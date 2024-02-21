from qgis.core import QgsProject, QgsRasterLayer, QgsCoordinateReferenceSystem, QgsProcessingException
from qgis.analysis import QgsRasterCalculator, QgsRasterCalculatorEntry
from osgeo import gdal, osr
import os
import numpy
import numpy as np
import processing
import subprocess

# Define input layer names
state = 'Missouri';
part = '';

tree_canopy_layer_name = 'NLCD_2021_Tree_Canopy_' + state + part
land_cover_layer_name = 'NLCD_2021_Land_Cover_' + state + part

if state == "Iowa":
	extent = '-97.250013669,-89.355428176,39.713667567,44.419802923 [EPSG:4326]'
elif state == "Missouri":
	extent = '-96.355195279,-88.469631424,35.729314262,41.248773156 [EPSG:4326]'
elif state == "Arkansas":
	extent = '-95.076043547,-88.501387866,32.747173200,37.289917060 [EPSG:4326]'
elif state == "Alabama":
	extent = '-89.768645686,-82.954078879,28.866873388,35.541806814 [EPSG:4326]'
else:
    extent = None

################################################## Step 1: Reclass tree canopy to one landcover type 41, 42, or 43 #########################################

# Define input and output paths
output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Trees-Combined.tiff'
    
# Retrieve input layers from the project using iface for land cover layer
layer1 = QgsProject.instance().mapLayersByName(tree_canopy_layer_name)[0]
# Set the layers as the active layer
iface.setActiveLayer(layer1)
# Retrieve input layers from the project using iface
input_layer_tree_canopy = iface.activeLayer()  

expression = (
    '(A > 0) * 41 + '
    '(A <= 0) * A'
)
command = [
    'gdal_calc.py',
    '-A', input_layer_tree_canopy.source(),
    '--outfile', output_path,
    '--calc', expression
]
subprocess.run(command, shell=True)
result_tree_canopy_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Trees-Combined')
QgsProject.instance().addMapLayer(result_tree_canopy_layer)

print("Step 1: Calculate result_tree_canopy completed. (NLCD_2021_" + state + part + "_Trees-Combined)")

############################################################# Step 2: Warp tree canopy to 4326 #############################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Tree_Canopy_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Trees-Combined')[0]
iface.setActiveLayer(layer1)
input_layer_tree_canopy = iface.activeLayer()

processing.run(
    "gdal:warpreproject",
    {
        'INPUT':input_layer_tree_canopy.source(),
        'SOURCE_CRS':None,
        'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),
        'RESAMPLING':0,
        'NODATA':None,
        'TARGET_RESOLUTION':None,
        'OPTIONS':'',
        'DATA_TYPE':1,
        'TARGET_EXTENT':extent,
        'TARGET_EXTENT_CRS':None,
        'MULTITHREADING':False,
        'EXTRA':'',
        'OUTPUT':output_path
    }
)

result_tree_canopy_warped_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Tree_Canopy_4326')
QgsProject.instance().addMapLayer(result_tree_canopy_warped_layer)

print("Step 2: Warp tree_canopy completed. (NLCD_2021_" + state + part + "_Tree_Canopy_4326)")

################################################################### Step 3: Warp land cover 4326 ############################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Land_Cover_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName(land_cover_layer_name)[0]
iface.setActiveLayer(layer1)
input_layer_land_cover = iface.activeLayer()

processing.run(
    "gdal:warpreproject",
    {
        'INPUT':input_layer_land_cover.source(),
        'SOURCE_CRS':None,
        'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),
        'RESAMPLING':0,
        'NODATA':None,
        'TARGET_RESOLUTION':None,
        'OPTIONS':'',
        'DATA_TYPE':1,
        'TARGET_EXTENT':extent,
        'TARGET_EXTENT_CRS':None,
        'MULTITHREADING':False,
        'EXTRA':'',
        'OUTPUT':output_path
    }
)

result_land_cover_warped_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Land_Cover_4326')
QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

print("Step 3: Warp land_cover completed. (NLCD_2021_" + state + part + "_Land_Cover_4326)")

################################################################ Step 4: Combine land cover 4326 and tree canopy 4326######################################
  
output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Combined_4326.tiff'

warped_tree_canopy_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Tree_Canopy_4326')[0]
warped_land_cover_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Land_Cover_4326')[0]
iface.setActiveLayer(warped_tree_canopy_layer)
input_layer_tree_canopy = iface.activeLayer()
iface.setActiveLayer(warped_land_cover_layer)
input_layer_land_cover = iface.activeLayer()

expression = (
    '((B > 0) & (B != 41) & (B != 42) & (B != 43) & (A > 0)) * A + '
    '((B == 41) | (B == 42) | (B == 43) | (A <= 0)) * B'
   )
command = [
    'gdal_calc.py',
    '-A', input_layer_tree_canopy.source(),
    '-B', input_layer_land_cover.source(),
    '--outfile', output_path,
    '--calc', expression
]
subprocess.run(command, shell=True)

result_tree_canopy_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Combined_4326')
QgsProject.instance().addMapLayer(result_tree_canopy_layer)

print("Step 4: Combine tree canopy and land cover completed. (NLCD_2021_" + state + part + "_Combined_4326)")

############################################################## Step 5: Replace urban and clutter with grass ###################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Grass-Only_4326.tiff'

combined_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Combined_4326')[0]
iface.setActiveLayer(combined_layer)
input_combined_layer = iface.activeLayer()

expression = (
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
    '-A', input_combined_layer.source(),
    '--outfile', output_path,
    '--calc', expression
]
subprocess.run(command, shell=True)

result_grass_only_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Grass-Only_4326')
QgsProject.instance().addMapLayer(result_grass_only_layer)

print("Step 5: Calculate result_grass_only completed. (NLCD_2021_" + state + part + "_Grass-Only_4326)")

################################################################## Step 6: Reclass urban 21, 22, 23 or 24 ###########################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Urban_4326.tiff'

combined_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Combined_4326')[0]
iface.setActiveLayer(combined_layer)
input_combined_layer = iface.activeLayer()

expression = (
    '(A == 21)*10 + '
    '(A == 22)*1 + '
    '(A == 23)*1 + '
    '(A == 24)*2'
)
command = [
    'gdal_calc.py',
    '-A', input_combined_layer.source(),
    '--outfile', output_path,
    '--calc', expression
]
subprocess.run(command, shell=True)

result_urban_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Urban_4326')
QgsProject.instance().addMapLayer(result_urban_layer)

print("Step 6: Calculate result_urban completed.")
    
################################################################ Step 7: Remove clutter and roads from urban ###########################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Urban-Only_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Urban_4326')[0]
iface.setActiveLayer(layer1)
input_layer_land_cover = iface.activeLayer()

processing.run(
    "grass7:r.neighbors",
    {
        'input':input_layer_land_cover.source(),
        'selection':None,
        'method':1,
        'size':7,
        'gauss':None,
        'quantile':'',
        '-c':False,
        '-a':False,
        'weight':'',
        'output':output_path,
        'GRASS_REGION_PARAMETER':extent,
        'GRASS_REGION_CELLSIZE_PARAMETER':0,
        'GRASS_RASTER_FORMAT_OPT':'',
        'GRASS_RASTER_FORMAT_META':''
    }
)

result_land_cover_warped_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + part + '_Urban-Only_4326')
QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

print("Step 7: Remove clutter and roads from urban. (NLCD_2021_" + state + part + "_Urban-Only_4326)")

############################################################## Step 8: Combine grass only and clean urban #########################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_Combined-Clean_4326.tiff'

grass_only_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Grass-Only_4326')[0]
urban_only_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Urban-Only_4326')[0]
iface.setActiveLayer(urban_only_layer)
input_urban_only = iface.activeLayer()
iface.setActiveLayer(grass_only_layer)
input_grass_only = iface.activeLayer()

expression = (
    '((A > 0) & (B > 0)) * A + '
    '((A <= 0) | (B <= 0)) * B + (B == 0) * 44'
)
command = [
    'gdal_calc.py',
    '-A', input_urban_only.source(),
    '-B', input_grass_only.source(),
    '--type=Byte',
    '--outfile', output_path,
    '--calc', expression
]
subprocess.run(command, shell=True)

# Resample the combined raster to a different resolution
output_path_resampled = output_path.replace("_4326.tiff", "_HD_4326.tiff")
gdal.Warp(
    output_path_resampled,
    output_path,
    xRes=0.00005539416,
    yRes=0.00005539416
)

urban_grass_combined = QgsRasterLayer(output_path_resampled, 'NLCD_2021_' + state + part + '_Combined-Clean_HD_4326')
QgsProject.instance().addMapLayer(urban_grass_combined)

print("Step 8: Combined and clean completed. (NLCD_2021_" + state + part + "_Combined-Clean_HD_4326)")
    
################################################################## Step 9: Smooth all hi res features #################################################################

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + part + '_HD_4326.tiff'
    
layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + part + '_Combined-Clean_HD_4326')[0]
iface.setActiveLayer(layer1)
input_layer_land_cover = iface.activeLayer()

processing.run(
    "grass7:r.neighbors",
    {
        'input':input_layer_land_cover.source(),
        'selection':None,
        'method':1,
        'size':7,
        'gauss':None,
        'quantile':'',
        '-c':False,
        '-a':False,
        'weight':'',
        'output':output_path,
        'GRASS_REGION_PARAMETER':extent,
        'GRASS_REGION_CELLSIZE_PARAMETER':0,
        'GRASS_RASTER_FORMAT_OPT':'',
        'GRASS_RASTER_FORMAT_META':''
    }
)  

# Convert output to Byte using gdal_translate
converted_output_path = output_path.replace("_HD_4326.tiff", "_Final-HD_4326.tiff")
command = [
    'gdal_translate',
    '-ot', 'Byte',  # Set output data type to Byte
    output_path,
    converted_output_path
]
subprocess.run(command, shell=True)

result_land_cover_warped_layer = QgsRasterLayer(converted_output_path, 'NLCD_2021_' + state + part + '_Final-HD_4326')
QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

print("Step 11: Smooth all hi res features completed. (NLCD_2021_" + state + part + "_Final-HD_4326)")
