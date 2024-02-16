from qgis.core import QgsProject, QgsRasterLayer, QgsCoordinateReferenceSystem
from scipy.ndimage import generic_filter
from osgeo import gdal, osr, ogr
import os
import numpy
import numpy as np

def set_geospatial_metadata(dataset, output_dataset, origin_x, origin_y, pixel_size):
    output_dataset.SetGeoTransform((origin_x, pixel_size, 0, origin_y, 0, -pixel_size))
    srs = osr.SpatialReference()
    srs.ImportFromEPSG(4326)
    output_dataset.SetProjection(srs.ExportToWkt())

def fill_nodata(values):
    nodata = values[values != band.GetNoDataValue()]
    if nodata.size == 0:
        return band.GetNoDataValue()
    else:
        return nodata.mean()

dataset_path = 'G:/Scenery/ws3.0/Alabama/data/NLCD_2021_Alabama_Combined-Clean_4326.tiff'
output_path_no_water = 'G:/Scenery/ws3.0/Alabama/data/NLCD_2021_prep-no-water.tiff'
output_path_grow = 'G:/Scenery/ws3.0/Alabama/data/NLCD_2021_prep-grow.tiff'
output_path_add_water = 'G:/Scenery/ws3.0/Alabama/data/NLCD_2021_prep-add-water.tiff'
coastline_vector_path = 'G:/Scenery/ws3.0/Alabama/data/NHD_H_Alabama_State_GPKG.gpkg'
output_path_grow_coast = 'G:/Scenery/ws3.0/Alabama/data/NLCD_2021_clipped-grown-coast.tiff'

################################################################# Process for removing water #################################################################
if not os.path.isfile(dataset_path):
    print(f"<input_raster> ({output_path_no_water}) does not exist")
else:
    dataset = gdal.Open(dataset_path)

band = dataset.GetRasterBand(1)
clipped_data = band.ReadAsArray()
temp = numpy.equal(clipped_data, 41)
numpy.putmask(clipped_data, temp, 0)

band.SetNoDataValue(0)
dataset = None

output_dataset_no_water = gdal.GetDriverByName('GTiff').Create(
    output_path_no_water, band.XSize, band.YSize, 1, gdal.GDT_Byte)
output_band_no_water = output_dataset_no_water.GetRasterBand(1)
output_band_no_water.SetNoDataValue(0)
output_band_no_water.WriteArray(clipped_data)

# Set the CRS and geospatial metadata for the output dataset
set_geospatial_metadata(band, output_dataset_no_water, -89.7686456863925457, 35.5418068143822197, 0.0002861339774627594886)

output_dataset_no_water = None

output_layer_no_water = QgsRasterLayer(output_path_no_water, 'NLCD_2021_prep-no-water')
output_layer_no_water.setCrs(QgsCoordinateReferenceSystem('EPSG:4326'))
QgsProject.instance().addMapLayer(output_layer_no_water)

clipped_data = None
band = None

########################################################################## Process for growing landclass ##########################################################
if not os.path.isfile(output_path_no_water):
    print(f"<input_raster> ({output_path_no_water}) does not exist")
else:
    dataset = gdal.Open(output_path_no_water)

band = dataset.GetRasterBand(1)
modified_array = band.ReadAsArray()

# Identify nodata values
nodata_mask = (modified_array == band.GetNoDataValue())

# Apply custom fill function using scipy.ndimage.generic_filter
modified_array = generic_filter(modified_array, fill_nodata, size=3, mode='constant', cval=0)

output_dataset_grow = gdal.GetDriverByName('GTiff').Create(
    output_path_grow, band.XSize, band.YSize, 1, gdal.GDT_Byte)
output_band_grow = output_dataset_grow.GetRasterBand(1)
output_band_grow.SetNoDataValue(0)
output_band_grow.WriteArray(modified_array)

set_geospatial_metadata(band, output_dataset_grow, -89.7686456863925457, 35.5418068143822197, 0.0002861339774627594886)

output_dataset_grow = None

output_layer_grow = QgsRasterLayer(output_path_grow, 'NLCD_2021_prep-grow')
output_layer_grow.setCrs(QgsCoordinateReferenceSystem('EPSG:4326'))
QgsProject.instance().addMapLayer(output_layer_grow)

band = None

########################################################################## Process for adding water ################################################################
dataset = gdal.Open(output_path_grow_coast)
if not os.path.isfile(output_path_grow_coast):
    print(f"<input_raster> ({ooutput_path_grow_coast}) does not exist")

band = dataset.GetRasterBand(1)
clipped_data = band.ReadAsArray()
temp = numpy.equal(clipped_data, 0)
numpy.putmask(clipped_data, temp, 41)

band.SetNoDataValue(0)
dataset = None

output_dataset_add_water = gdal.GetDriverByName('GTiff').Create(
    output_path_add_water, band.XSize, band.YSize, 1, gdal.GDT_Byte)
output_band_add_water = output_dataset_add_water.GetRasterBand(1)
output_band_add_water.SetNoDataValue(0)
output_band_add_water.WriteArray(clipped_data)

# Set the CRS and geospatial metadata for the output dataset
set_geospatial_metadata(band, output_dataset_add_water, -89.7686456863925457, 35.5418068143822197, 0.0002861339774627594886)

output_dataset_add_water = None

output_layer_add_water = QgsRasterLayer(output_path_add_water, 'NLCD_2021_prep-add-water')
output_layer_add_water.setCrs(QgsCoordinateReferenceSystem('EPSG:4326'))
QgsProject.instance().addMapLayer(output_layer_add_water)

clipped_data = None
band = None