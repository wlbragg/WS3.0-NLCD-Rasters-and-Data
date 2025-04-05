from qgis.core import QgsApplication, QgsCoordinateTransform, QgsProject, QgsRasterLayer, QgsCoordinateReferenceSystem, QgsProcessingException, QgsRasterBlock, QgsRectangle
from qgis.analysis import QgsRasterCalculator, QgsRasterCalculatorEntry
from qgis import processing
from processing.core.Processing import Processing
from osgeo import gdal, osr, ogr
import os
import numpy
import numpy as np
import subprocess

# Define input layer names, change according to your file names
path = '/media/wayne/TOSHIBA-EXT/Scenery/ws3.0/';
year = '2016';
state = 'Alaska';
part = '_SaintPaul-Island';

################################## IMPORTANT ###############################
# Beginning filename of the NLCD from the source needs to be
# NLCD_' + year +  '_Tree_Canopy_' + state + part + '.tiff'
# Also note that "/data/" is hardcoded into the path as well
# I needed the existing path structure to process it by state.
# For Alaska I used one lat and a few lon sections per chunck built.
# I will likly do the entire NLCD coverage area the same in future runs.
# Example beginning NLCD source:
# NLCD_2016_Tree_Canopy_Alaska141-140_60.tiff
# Full path and filename to source example is:
# G:/Scenery/ws3.0/Alaska/data/NLCD_2016_Tree_Canopy_Alaska141-140_60.tiff
# Final output path to last processed file is:
# G:/Scenery/ws3.0/Alaska/data/NLCD_2016_Alaska141-140_60_Smoothed-HD-Compressed_4326

#IMPORTANT NOTE:
# On any subprocess.run(command, shell=True) process, when using the script in Linux
# you need to change to subprocess.run(command). Remove the shell=True.

#You can try using the following syntax for both Windows and Linux
#subprocess.run([
#    'gdal_calc.py',
#    '-A', input_path,
#    '--outfile', output_path,
#    '--calc', expression,
#    '--type', 'Byte'
#], check=True)
############################################################################

################################################################### Step 1: Warp land cover 4326 ############################################################

input_path = path + state + '/data/NLCD_' + year +  '_Land_Cover_' + state + part + '.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Land_Cover_4326.tiff'

processing.run(
    "gdal:warpreproject",
    {
        'INPUT':input_path,
        'SOURCE_CRS':None,
        'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),
        'RESAMPLING':0,
        'NODATA':None,
        'TARGET_RESOLUTION':None,
        'OPTIONS':'',
        'DATA_TYPE':1,  # GDAL GDT_Byte
        'TARGET_EXTENT':None,
        'TARGET_EXTENT_CRS':None,
        'MULTITHREADING':False,
        'EXTRA':'',
        'OUTPUT':output_path
    }
)

print("Step 1: Warp land_cover completed. (NLCD_" + year +  "_" + state + part + "_Land_Cover_4326)")

############################################################## Step 2: Replace urban and clutter with grass ###################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Land_Cover_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Grass-Only_4326.tiff'

expression = (
    '(A == 0) * 44 + '
    '(A == 11) * 41 + '
    '(A == 12) * 34 + '
    '(A == 21) * 26 + '
    '(A == 22) * 26 + '
    '(A == 23) * 26 + '
    '(A == 24) * 26 + '
    '(A == 31) * 27 + '
    '(A == 41) * 23 + '
    '(A == 42) * 24 + '
    '(A == 43) * 25 + '
    '(A == 51) * 30 + '
    '(A == 52) * 29 + '
    '(A == 71) * 26 + '
    '(A == 72) * 32 + '
    '(A == 73) * 31 + '
    '(A == 74) * 31 + '
    '(A == 75) * 32 + '
    '(A == 81) * 18 + '
    '(A == 82) * 19 + '
    '(A == 90) * 25 + '
    '(A == 95) * 35'
)
command = [
    'gdal_calc.py',
    '-A', input_path,
    '--outfile', output_path,
    '--calc', expression,
    '--type', 'Byte'
]
subprocess.run(command)

print("Step 2: Replace urban and clutter with grass completed. (NLCD_" + year +  "_" + state + part + "_Grass-Only_4326)")

################################################################## Step 3: Reclass urban 21, 22, 23 or 24 ###########################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Land_Cover_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Reclassed-Urban_4326.tiff'

expression = (
    '(A == 21)*10 + '
    '(A == 22)*1 + '
    '(A == 23)*1 + '
    '(A == 24)*2'
)
command = [
    'gdal_calc.py',
    '-A', input_path,
    '--outfile', output_path,
    '--calc', expression,
    '--type', 'Byte'
]
subprocess.run(command)

print("Step 3:  Reclass urban completed. (NLCD_" + year +  "_" + state + part + "_Reclassed-Urban_4326)")

################################################################ Step 4: Remove clutter and roads from urban ###########################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Reclassed-Urban_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Urban-Only_4326.tiff'

processing.run(
    "grass7:r.neighbors",
    {
        'input':input_path,
        'selection':None,
        'method':1, #1=median, 2=mode
        'size':7,
        'gauss':None,
        'quantile':'',
        '-c':False,
        '-a':False,
        'weight':'',
        'output':output_path,
        'GRASS_REGION_PARAMETER':None,
        'GRASS_REGION_CELLSIZE_PARAMETER':0,
        'GRASS_RASTER_FORMAT_OPT':'',
        'GRASS_RASTER_FORMAT_META':''
    }
)

print("Step 4: Remove clutter and roads from urban. (NLCD_" + year +  "_" + state + part + "_Urban-Only_4326)")

############################################################## Step 5: Combine grass only and clean urban #########################################################

input_path_a = path + state + '/data/NLCD_' + year + '_' + state + part + '_Urban-Only_4326.tiff'
input_path_b = path + state + '/data/NLCD_' + year + '_' + state + part + '_Grass-Only_4326.tiff'
output_path = path + state + '/data/NLCD_' + year + '_' + state + part + '_Combined-Clean_4326.tiff'

expression = (
   '((A > 0) & (B > 0)) * A + '
   '((A <= 0) | (B <= 0)) * B'
)
command = [
    'gdal_calc.py',
    '-A', input_path_a,
    '-B', input_path_b,
    '--outfile', output_path,
    '--calc', expression,
    '--NoDataValue', '0'
]
subprocess.run(command)

print("Step 5: Combined and clean completed. (NLCD_" + year +  "_" + state + part + "_Combined-Clean_4326)")

################################################################## Step 6: Upsample to HD #################################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Combined-Clean_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Combined-Clean-HD_4326.tiff'

# Open the original raster
ds = gdal.Open(input_path)
gt = ds.GetGeoTransform()

# Extract the original resolution
original_xRes = gt[1]
original_yRes = abs(gt[5])

# Define the percentage to resize by (e.g., 0.50 for 50%, 2.0 for 200%)
percentage = 8.0  # Adjust this as needed

# Calculate the new resolution
new_xRes = original_xRes / percentage
new_yRes = original_yRes / percentage

# Perform the warp (resampling)
gdal.Warp(
    output_path,
    input_path,
    xRes=new_xRes,
    yRes=new_yRes,
    outputType=gdal.GDT_Byte  # Set the output type to uint8
)

print("Step 6: Upsample to. (NLCD_" + year +  "_" + state + part + "_Combined-Clean-HD_4326)")

################################################################## Step 7: Smooth all features in original dataset #################################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Combined-Clean-HD_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Smoothed-HD_4326.tiff'

processing.run(
    "grass7:r.neighbors",
    {
        'input':input_path,
        'selection':None,
        'method':1, #1=median, 3=mode
        'size':11,
        'gauss':None,
        'quantile':'',
        '-c':False,
        '-a':False,
		'weight':'',
        'output':output_path,
        'GRASS_REGION_CELLSIZE_PARAMETER':0,
        'GRASS_RASTER_FORMAT_OPT':'',
        'GRASS_RASTER_FORMAT_META':''
    }
) 

print("Step 7: Smooth all features in original dataset completed. (NLCD_" + year +  "_" + state + part + "_Smoothed-HD_4326)")

################################################################## Step 8: Convert to 8Bit #################################################################

input_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Smoothed-HD_4326.tiff'
output_path = path + state + '/data/NLCD_' + year +  '_' + state + part + '_Smoothed-HD-Compressed_4326.tiff'

processing.run(
	"gdal:translate",
	{
		'INPUT':input_path,
		'TARGET_CRS':None,
		'NODATA':0,
		'COPY_SUBDATASETS':False,
		'OPTIONS':'',
		'EXTRA':'',
		'DATA_TYPE':1,
		'OUTPUT':output_path,
		'OPTIONS': 'COMPRESS=LZW'
	}
)

result_bit_conversion_layer = QgsRasterLayer(output_path, 'NLCD_' + year +  '_' + state + part + '_Smoothed-HD-Compressed_4326')
QgsProject.instance().addMapLayer(result_bit_conversion_layer)

print("Step 8: Convert to Compressed. (NLCD_" + year +  "_" + state + part + "_Smoothed-HD-Compressed_4326)")

