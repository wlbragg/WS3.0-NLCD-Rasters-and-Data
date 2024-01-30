#!/usr/bin/python3

import numpy
import os
import shlex
import subprocess
import sys
from osgeo import gdal
from osgeo import ogr
from osgeo import osr
from osgeo import gdal_array
from osgeo import gdalconst

gdal.UseExceptions()    # Enable exceptions

# Set to True to generate intermediat .tif files.  Useful to see what may have gone wrong
DEBUG = False

PROGNAME = os.path.basename(sys.argv[0])
DEFAULT_HGT_DIR = os.path.join("/home", "flightgear", "data")
DEFAULT_OUTPUT_DIR = os.path.join("/home", "flightgear", "output", "vpb")

def usage(msg, *, exit_status=1, **kwargs):
    help_text = f"""\
ERROR: {msg}

Generate a set of VPB tiles from a landclass raster and HGT elevation data, optionally reclassifying the raster data and applying coastline polygon data as a mask

Usage: {PROGNAME} <min-lon> <min-lat> <max-lon> <max-lat> <input-raster> [--reclass <reclass>] [--coastline <coastline>] [--hgt-dir <hgt-dir>] [--output-dir <output-dir>]

  <min-lon> <min-lat> <max-lon> <max-lat> - bounding box of scenery to generated
  <input-raster>  - Input landclass raster
  [coastline]     - Optional coastline polygon data (.osm) to clip against.  E.g. from https://osmdata.openstreetmap.de/data/land-polygons.html
  [reclass]       - Optional file containing a set of rules for reclassifying the raster similar to r.reclass. See fgmeta/ws30/mappings/
  [hgt-dir]       - Optional directory containing unzipped NASADEM HGT files. Defaults to '{DEFAULT_HGT_DIR}'.
  [output-dir]    - Optional directory for output scenery. Defaults to '{DEFAULT_OUTPUT_DIR}'"""
    print(help_text, **kwargs)
    sys.exit(exit_status)


if len(sys.argv) < 7:
    usage("")

lon0, lat0, lon1, lat1 = map(int, sys.argv[1:5])
input_raster = sys.argv[5]
hgtdir = DEFAULT_HGT_DIR
output_dir = DEFAULT_OUTPUT_DIR
coastline = None
reclass = None

# Parse optional command line arguments.
i = 6
while i < len(sys.argv):
    arg = sys.argv[i]

    if arg == '--coastline':
        i = i + 1
        coastline = str(sys.argv[i])

    elif arg == '--hgt-dir':
        i = i + 1
        hgtdir = str(sys.argv[i])

    elif arg == '--output-dir':
        i = i + 1
        output_dir = str(sys.argv[i])

    elif arg == '--reclass':
        i = i + 1
        reclass = str(sys.argv[i])

    else:
        usage("Invalid argument: {}".format(arg))

    i = i + 1


# Basic argument validation
if lon0 >= lon1:
    usage("<min-lon> must be smaller than <max-lon>")
if lat0 >= lat1:
    usage("<min-lat> must be smaller than <max-lat>")
if not os.path.isfile(input_raster):
    usage("<input_raster> (" + input_raster + ") does not exist")
if coastline and not os.path.isfile(coastline):
    usage("<coastline> (" + coastline + ") does not exist")
if reclass and not os.path.isfile(reclass):
    usage("<reclass> (" + reclass + ") does not exist")
if not os.path.isdir(hgtdir):
    usage("<hgt-dir> (" + hgtdir + ") does not exist")
if not os.path.isdir(output_dir):
    usage("<output_dir> (" + output_dir + ") does not exist")


def getTileBaseName(lon: int, lat: int) -> str:
    # Determine a name for the 1x1 degree tile, to match the standard for WS3.0 for simplicity
    ns = "n" if lat >= 0 else "s"
    ew = "e" if lon >= 0 else "w"
    return "ws_{ew}{lon:03d}{ns}{lat:02d}".format(ew=ew, ns=ns, lon=abs(lon), lat=abs(lat))

def writeGeoTIFF(filename : str, data_source : gdal.Dataset) -> str:
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, filename + ".tif")
    if DEBUG : print("Writing " + output_path)

    driver = gdal.GetDriverByName("GTiff")
    outdata = driver.Create(output_path, data_source.RasterXSize, data_source.RasterYSize, 1, gdal.GDT_Byte)
    outdata.SetProjection(data_source.GetProjection())
    outdata.SetGeoTransform(data_source.GetGeoTransform())
    band = data_source.GetRasterBand(1)
    arr = band.ReadAsArray()
    outband = outdata.GetRasterBand(1)
    outband.WriteArray(arr)
    if (band.GetNoDataValue() == None) :
        outband.SetNoDataValue(0)
    else :
        outband.SetNoDataValue(band.GetNoDataValue())
    outdata.FlushCache()
    outdata = None
    band = None

    return output_path

# Clip a given raster to the require 1x1 lon/lat tile, check for projection
def clipTileToLonLat(lon: int, lat: int, dataset : gdal.Dataset) -> gdal.Dataset :

    # Check and correct the projection
    projection = dataset.GetProjection()
    if not projection.startswith("GEOGCS[\"WGS 84\"") :
        # Correct to WGS84.  We are intentionally changing the base dataset here so we only
        # have to do this once.
        dataset = gdal.Warp('', dataset, format = 'MEM', dstSRS = 'EPSG:4326')

    # Reduce to a single 1x1 degree block.  Note unusual ordering of extents.
    return gdal.Translate('', dataset, format = 'MEM', projWin = [lon, lat+1, lon+1, lat])

# Reclassify a raster based on a set of rules
def reclassifyRaster(rules: str, dataset : gdal.Dataset) -> gdal.Dataset :

    file1 = open(rules, 'r')
    Lines = file1.readlines()
    
    count = 0
    reclass = []
    lookup = numpy.arange(256)

    for line in Lines:
        count += 1
        line = line.strip()
        print("Line {}: {}".format(count, line))
        # Ignore any lines starting with # for comments
        if len(line) == 0 or line[0] == '#' : 
            continue

        # Ignore everything that might be after a #, as inline comments
        q = line.split('#')

        # We've now removed any comments so what we should have is something of the form
        #
        # 1 2 3 = 23
        # * = 44
        #
        # This is to assign values 1, 2 or 3 to the value 23 and anything else to 44
        
        # Split on the equals sign.  s[0] will be a set of values to map from, while s[1] is the value to map to.
        s = q[0].split('=')

        if len(s) == 0 : continue
        if (len(s) != 2) or (len(s[0].strip()) == 0) or (len(s[1].strip()) == 0) : 
            print("Each line must contain exactly one mapping assignment for reclassification in {} line {} : {}".format(rules, count, q[0]))
            continue

        try :
            rh = int(s[1].strip())
        except ValueError :
            print("Invalid RH assigment for reclassification in {} line {} : {}".format(rules, count, s[1]))
            continue

        # Split on whitespace to get the list of values to map from
        l = s[0].split()

        for i in l:
            if i.strip() == '*' :
                # We're setting a wildcard value, so re-initialize the LUT to the wildcard value
                lookup = numpy.full(256, rh)
            else :
                try :
                    lh = int(i.strip())
                except ValueError:
                    print("Invalid LH assignment for reclassification in {} line {} : {}".format(rules, count, i))
                    continue
                reclass.append((lh, rh))

    # Now fill in the LUT
    for (lh, rh) in reclass:
        lookup[lh] = rh

    # Now use numpy to map the values
    for iBand in range(1, dataset.RasterCount + 1):
        band = dataset.GetRasterBand(iBand)

        for iY in range(dataset.RasterYSize):
            src_data = band.ReadAsArray(0, iY, dataset.RasterXSize, 1)
            dst_data = numpy.take(lookup, src_data)
            band.WriteArray(dst_data, 0, iY)        

    return dataset

# Clip a given data set to a coastline from OSM.  
#
# To handle cases where the OSM coastline is further out to sea than the raster coastline, we
# first "grow" the land, as if the sea level dropped.  Then we flood it again :)
# We also extrude it by 1 px so that there is a suitable landclass underneath the detailed coastline
# raster.
def clipTileToCoastline(lon: int, lat: int, dataset : gdal.Dataset, coastline : str) -> gdal.Dataset :
    # Remove any sea.  This is value 44
    band = dataset.GetRasterBand(1)
    clipped_data = band.ReadAsArray()
    temp = numpy.equal(clipped_data, 44)
    numpy.putmask(clipped_data, temp, 0)
    band.WriteArray(clipped_data)
    clipped_data = None # Flush to the dataset
    band = None # Flush to the dataset
    if DEBUG : writeGeoTIFF(getTileBaseName(lon, lat) + "_noSea", dataset)

    # Grow the landclass so we can clip against some vector data.  We do this one pixel at a time
    # as otherwise we get many more interpolation artefacts
    band = dataset.GetRasterBand(1)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    if (result) : 
        usage("Failed to fill No Data")
    band = None  # Flush to the dataset
    if DEBUG : writeGeoTIFF(getTileBaseName(lon, lat) + "_grow", dataset)

    # Clip against the vector data 
    clippedCoast = gdal.Warp('', dataset, format = 'MEM', cutlineDSName = coastline)
    if DEBUG : writeGeoTIFF(getTileBaseName(lon, lat) + "_clipped", clippedCoast)

    # Extrude slighly so there there is land underneath the detailed coastline raster that is generated
    # at runtime.
    band = clippedCoast.GetRasterBand(1)
    result = gdal.FillNodata(targetBand = band, maskBand = None, maxSearchDist=1, smoothingIterations=0)
    if (result) :
        usage("Failed to fill No Data")
    band = None  # Flush to the dataset

    # Set the NoDataValue to 44 which is the Sea
    band = clippedCoast.GetRasterBand(1)    
    clipped_data = band.ReadAsArray()
    temp = numpy.equal(clipped_data, 0)
    numpy.putmask(clipped_data, temp, 44)
    band.WriteArray(clipped_data)
    band = None  # Flush to the dataset
    return clippedCoast

def checkHGT(lon: int, lat: int) -> bool :
    ns = "n" if lat >= 0 else "s"
    ew = "e" if lon >= 0 else "w"
    hgt_filename = "{ns}{lat:02d}{ew}{lon:03d}.hgt".format(
        ew=ew, ns=ns, lat=abs(lat), lon=abs(lon))
    hgtname = os.path.join(hgtdir, hgt_filename)

    if not os.path.isfile(hgtname):
        print(f"Skipping tile {lon}, {lat} as HGT file {hgtname} does not exist")
        return False
    return True

# Build a 1x1 VPB tile for a given lon/lon and geotiff
def buildTile(lon: int, lat: int, geotiff: str) -> None:
    ns = "n" if lat >= 0 else "s"
    ew = "e" if lon >= 0 else "w"

    lat10 = 10 * (lat // 10)
    lon10 = 10 * (lon // 10)

    d1 = "{ew}{lon10:03d}{ns}{lat10:02d}".format(
        ew=ew, ns=ns, lon10=abs(lon10), lat10=abs(lat10))
    d2 = "{ew}{lon:03}{ns}{lat:02}".format(
        ew=ew, ns=ns, lon=abs(lon), lat=abs(lat))
    dirname = os.path.join(d1, d2)
    os.makedirs(os.path.join(output_dir, dirname), exist_ok=True)

    tilename = "ws_{ew}{lon:03d}{ns}{lat:02d}.osgb".format(
        ew=ew, ns=ns, lat=abs(lat), lon=abs(lon))
    if DEBUG : print("Generating " + os.path.join(output_dir, dirname, tilename))

    hgt_filename = "{ns}{lat:02d}{ew}{lon:03d}.hgt".format(
        ew=ew, ns=ns, lat=abs(lat), lon=abs(lon))
    hgtname = os.path.join(hgtdir, hgt_filename)

    if not os.path.isfile(hgtname):
        print(f"Skipping tile {lon}, {lat} as HGT file {hgtname} does not exist")
        return

    args = [
        "osgdem",
        "--TERRAIN",
        "--image-ext", "png",
        "--no-interpolate-imagery",
        "--disable-error-diffusion",
        "--geocentric",
        "--no-mip-mapping",
        "-t", geotiff,
        "-d", hgtname,
        "-b", str(lon), str(lat), str(lon + 1), str(lat + 1),
        "--PagedLOD",
        "-l", "7",
        "--radius-to-max-visible-distance-ratio", "3",
        "-o", os.path.join(output_dir, dirname, tilename),
    ]

    log_file = os.path.join(output_dir, "commands.log")
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(' '.join(map(shlex.quote, args)) + "\n")

    cp = subprocess.run(args, capture_output=True, check=True, text=True)

    if DEBUG : print("stdout: '{}'".format(cp.stdout))
    if DEBUG : print("stderr: '{}'".format(cp.stderr))

def main():

    dataset = gdal.Open(input_raster)

    for lon in range(lon0, lon1):
        for lat in range(lat0, lat1):            
            if (checkHGT(lon, lat) == False) :
                continue

            print("Processing " + str(lon) + ", " + str(lat))

            # Create a 1x1 tile in WGS84
            tile = clipTileToLonLat(lon, lat, dataset)

            # Reclassify if required
            if reclass : tile = reclassifyRaster(reclass, tile)

            # Apply coastline if available
            if coastline : tile = clipTileToCoastline(lon, lat, tile, coastline)

            # Write out the final geotiff
            geotiff = writeGeoTIFF(getTileBaseName(lon, lat), tile)

            # Build the VPB tile.
            buildTile(lon, lat, geotiff)

            # Remove the geotiff
            if not DEBUG : os.unlink(geotiff)

if __name__ == "__main__": main()
