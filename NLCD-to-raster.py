# Import necessary QGIS modules
from qgis.core import QgsProject, QgsRasterLayer, QgsCoordinateReferenceSystem, QgsProcessingException
from qgis.analysis import QgsRasterCalculator, QgsRasterCalculatorEntry
from osgeo import gdal
import processing
import subprocess
import numpy

# Define input layer names
state = 'Iowa';
tree_canopy_layer_name = 'NLCD_2021_Tree_Canopy_' + state
land_cover_layer_name = 'NLCD_2021_Land_Cover_' + state

if state == "Iowa":
    extent = '-97.250013669,-89.355428176,39.713667567,44.419802923 [EPSG:4326]',
elif state == "Missouri":
    extent = '-95.076043547,-88.501387866,32.747173200,37.289917060 [EPSG:4326]',
else:
    extent = None

# Step 1: Reclass tree canopy to one landcover type 41, 42, or 43

# Define input and output paths
output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Trees-Combined.tiff'

# Retrieve input layers from the project using iface for land cover layer
layer1 = QgsProject.instance().mapLayersByName(tree_canopy_layer_name)[0]

# Check if the layer is valid
if layer1:
    # Set the layers as the active layer
    iface.setActiveLayer(layer1)
    # Retrieve input layers from the project using iface
    input_layer_tree_canopy = iface.activeLayer()  

    #scaling_factor = 2
    expression = (
        '(A > 0) * 41 + '
        '(A <= 0) * A'
    )
    #expression_scale = f'A * {scaling_factor} * ({expression})'
    command = [
        'gdal_calc.py',
        '-A', input_layer_tree_canopy.source(),
        '--outfile', output_path,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)
    result_tree_canopy_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + '_Trees-Combined')
    QgsProject.instance().addMapLayer(result_tree_canopy_layer)
    
    print("Step 1: Calculate result_tree_canopy completed.")

# Step 2: Warp tree canopy to 4326

output_path_warp_trees = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Tree_Canopy_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Trees-Combined')[0]

if layer1:
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
            'OUTPUT':output_path_warp_trees
        }
    )

    result_tree_canopy_warped_layer = QgsRasterLayer(output_path_warp_trees, 'NLCD_2021_' + state + '_Tree_Canopy_4326')
    QgsProject.instance().addMapLayer(result_tree_canopy_warped_layer)

    print("Step 2: Warp tree_canopy completed.")

# Step 3: Warp land cover 4326

output_path_warp_land = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Land_Cover_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName(land_cover_layer_name)[0]

if layer1:
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
            'OUTPUT':output_path_warp_land
        }
    )
    
    result_land_cover_warped_layer = QgsRasterLayer(output_path_warp_land, 'NLCD_2021_' + state + '_Land_Cover_4326')
    QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

    print("Step 3: Warp land_cover completed.")

# Step 4: Combine land cover 4326 and tree canopy 4326

output_path_combined = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Combined_4326.tiff'
    
warped_tree_canopy_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Tree_Canopy_4326')[0]
warped_land_cover_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Land_Cover_4326')[0]

if warped_tree_canopy_layer and warped_land_cover_layer:
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
        '--outfile', output_path_combined,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)
    
    result_tree_canopy_layer = QgsRasterLayer(output_path_combined, 'NLCD_2021_' + state + '_Combined_4326')
    QgsProject.instance().addMapLayer(result_tree_canopy_layer)

    print("Step 4: Combine tree canopy and land cover completed.")

# Step 5: Replace urban and clutter with grass

output_path_grass_only = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Grass-Only_4326.tiff'

combined_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Combined_4326')[0]

# Check if the layers are valid
if combined_layer:
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
        '--outfile', output_path_grass_only,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)
    
    result_grass_only_layer = QgsRasterLayer(output_path_grass_only, 'NLCD_2021_' + state + '_Grass-Only_4326')
    QgsProject.instance().addMapLayer(result_grass_only_layer)
    
    print("Step 5: Calculate result_grass_only completed.")

# Step 6: Reclass urban 21, 22, 23 or 24

output_path_urban = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Urban_4326.tiff'

combined_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Combined_4326')[0]

if combined_layer:
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
        '--outfile', output_path_urban,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)
    
    result_urban_layer = QgsRasterLayer(output_path_urban, 'NLCD_2021_' + state + '_Urban_4326')
    QgsProject.instance().addMapLayer(result_urban_layer)
    
    print("Step 6: Calculate result_urban completed.")
    
# Step 7: Remove clutter and roads from urban

output_path_smooth_land = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Urban-Only_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Urban_4326')[0]

if layer1:
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
            'output':output_path_smooth_land,
            'GRASS_REGION_PARAMETER':None,
            'GRASS_REGION_CELLSIZE_PARAMETER':0,
            'GRASS_RASTER_FORMAT_OPT':'',
            'GRASS_RASTER_FORMAT_META':''
        }
    )

    result_land_cover_warped_layer = QgsRasterLayer(output_path_smooth_land, 'NLCD_2021_' + state + '_Urban-Only_4326')
    QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

    print("Step 7: Remove clutter and roads from urban.")

# Step 8: Combine grass only and clean urban

output_path_urban_grass_combined = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Combined-Clean_4326.tiff'

grass_only_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Grass-Only_4326')[0]
urban_only_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Urban-Only_4326')[0]

if grass_only_layer and urban_only_layer:
    iface.setActiveLayer(urban_only_layer)
    input_urban_only = iface.activeLayer()
    iface.setActiveLayer(grass_only_layer)
    input_grass_only = iface.activeLayer()

    expression = (
        '((A > 0) & (B > 0)) * A + '
        '((A <= 0) | (B <= 0)) * B'
    )
    command = [
        'gdal_calc.py',
        '-A', input_urban_only.source(),
        '-B', input_grass_only.source(),
        '--type=Byte',
        '--outfile', output_path_urban_grass_combined,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)

    urban_grass_combined = QgsRasterLayer(output_path_urban_grass_combined, 'NLCD_2021_' + state + '_Combined-Clean_4326')
    QgsProject.instance().addMapLayer(urban_grass_combined)
    
    print("Step 8: Combined and clean completed.")

# Step 9: Reclass water to sand and nodata to 44 ocean

output_path = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Complete-No-Water_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Combined-Clean_4326')[0]

if layer1:
    iface.setActiveLayer(layer1)
    input_layer_smoothed_hd = iface.activeLayer()  

    expression = (
        '((A > 0) & (A != 41))* A + '
        '(A <= 0)*44 + '
        '(A == 41)*26'
    )
    command = [
        'gdal_calc.py',
        '-A', input_layer_smoothed_hd.source(),
        '--outfile', output_path,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)
    result_nlcd_complete_layer = QgsRasterLayer(output_path, 'NLCD_2021_' + state + '_Complete-No-Water_4326')
    QgsProject.instance().addMapLayer(result_nlcd_complete_layer)
    
    print("Step 9: Reclass water to sand and nodata to 44 ocean.")

# Step 10: Upsample combined and clean

output_path_hd = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_HD-No-Water_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Complete-No-Water_4326')[0]

if layer1:
    iface.setActiveLayer(layer1)
    input_layer_land_cover = iface.activeLayer()

    options = gdal.WarpOptions(
        format="GTiff",
        dstSRS="EPSG:4326",
        xRes=0.0000415456,
        yRes=0.0000415456,
        resampleAlg=gdal.GRA_NearestNeighbour,
        outputType=gdal.GDT_Byte
    )
    gdal.Warp(
        output_path_hd,
        input_layer_land_cover.source(),
        options=options
    )

    result_land_cover_hd = QgsRasterLayer(output_path_hd, 'NLCD_2021_' + state + '_HD-No-Water_4326')
    QgsProject.instance().addMapLayer(result_land_cover_hd)

    print("Step 10: Upsample combined and clean completed.")

# Step 11: Smooth all hi res features 

output_path_smooth_features = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Smoothed-HD-No-Water_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_HD-No-Water_4326')[0]

if layer1:
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
            'output':output_path_smooth_features,
            'GRASS_REGION_PARAMETER':None,
            'GRASS_REGION_CELLSIZE_PARAMETER':0,
            'GRASS_RASTER_FORMAT_OPT':'',
            'GRASS_RASTER_FORMAT_META':''
        }
    )
    
    result_land_cover_warped_layer = QgsRasterLayer(output_path_smooth_features, 'NLCD_2021_' + state + '_Smoothed-HD-No-Water_4326')
    QgsProject.instance().addMapLayer(result_land_cover_warped_layer)

    print("Step 11: Smooth all hi res features completed.")
    
# Step 12: Vector to raster hi res water

output_path_hi_res_water = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_HD-Water_4269.tiff'

layer1 = QgsProject.instance().mapLayersByName(state +'-water')[0]

if layer1:
    iface.setActiveLayer(layer1)
    input_layer_hd_water = iface.activeLayer()

    processing.run(
        "gdal:rasterize",
        {
            'INPUT':input_layer_hd_water.source(),
            'FIELD':'',
            'BURN':41,
            'USE_Z':False,
            'UNITS':1,
            'WIDTH': 0.0000415456,
            'HEIGHT': 0.0000415456,
            'TARGET_EXTENT':extent,
            'NODATA':-9999,
            'OPTIONS':'',
            'DATA_TYPE':0,
            'INIT':None,
            'INVERT':False,
            'EXTRA':'',
            'OUTPUT':output_path_hi_res_water
        }
    )

    hd_water_complete = QgsRasterLayer(output_path_hi_res_water, 'NLCD_2021_' + state + '_HD-Water_4269')
    QgsProject.instance().addMapLayer(hd_water_complete)
    
    print("Step 12: Vector to raster hi res water completed.")

# Step 13: Combine hires water and hires nowater

output_path_hd_water_combined = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_NLCD-Complete_4269.tiff'

hd_water_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_HD-Water_4269')[0]
hd_nowater_layer = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_Smoothed-HD-No-Water_4326')[0]

if hd_water_layer and hd_nowater_layer:
    iface.setActiveLayer(hd_nowater_layer)
    input_hd_nowater_layer = iface.activeLayer()
    iface.setActiveLayer(hd_water_layer)
    input_hd_water_layer = iface.activeLayer()

    expression = (
        '((A > 0) & (B > 0)) * A + '
        '((A <= 0) | (B <= 0)) * B'
    )
    command = [
        'gdal_calc.py',
        '-A', input_hd_water_layer.source(),
        '-B', input_hd_nowater_layer.source(),
        '--type=Byte',
        '--outfile', output_path_hd_water_combined,
        '--calc', expression
    ]
    subprocess.run(command, shell=True)

    hd_water_combined = QgsRasterLayer(output_path_hd_water_combined, 'NLCD_2021_' + state + '_NLCD-Complete_4269')
    QgsProject.instance().addMapLayer(hd_water_combined)
    
    print("Step 13: Combine hires water and hires nowater completed.")
    
# Step 14: Warp Hi Res NLCD-Complete_4269 to 4326

output_path_warp_complete = 'G:/Scenery/ws3.0/' + state + '/data/NLCD_2021_' + state + '_Hi-Res_Complete_4326.tiff'

layer1 = QgsProject.instance().mapLayersByName('NLCD_2021_' + state + '_NLCD-Complete_4269')[0]

if layer1:
    iface.setActiveLayer(layer1)
    input_layer_land_cover = iface.activeLayer()

    processing.run(
        "gdal:warpreproject",
        {
            'INPUT':input_layer_land_cover.source(),
            'SOURCE_CRS':None,
            'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:4326'),
            'RESAMPLING':0,
            'NODATA':0,
            'TARGET_RESOLUTION':0.0000415456,
            'OPTIONS':'',
            'DATA_TYPE':1,
            'TARGET_EXTENT':extent,
            'TARGET_EXTENT_CRS':None,
            'MULTITHREADING':False,
            'EXTRA':'',
            'OUTPUT':output_path_warp_complete
        }
    )

    result_hires_complete = QgsRasterLayer(output_path_warp_complete, 'NLCD_2021_' + state + '_Hi-Res_Complete_4326')
    QgsProject.instance().addMapLayer(result_hires_complete)

    print("Step 14: Warp hires NLCD-Complete_4269 to to 4326.")

    
