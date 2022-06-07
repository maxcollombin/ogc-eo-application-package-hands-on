$graph:
- class: Workflow
  label: This application generates Sentinel-2 RGB composites
  doc: This application generates a Sentinel-2 RGB composite over an area of interest with selected bands

  id: s2-composites

  requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement

  inputs: 

    products: 
      type: string[]
      label: Sentinel-2 input references
      doc: Sentinel-2 Level-2A STAC Items
    red:
      type: string
      label: Sentinel-2 band for red channel
      doc: Sentinel-2 band for red channel
    green:
      type: string
      label: Sentinel-2 band for green channel
      doc: Sentinel-2 band for green channel
    blue:
      type: string
      label: Sentinel-2 band for blue channel
      doc: Sentinel-2 band for blue channel
    bbox:
      type: string
      label: Area of interest expressed as a bounding bbox
      doc: Area of interest expressed as a bounding bbox
    proj:
      type: string
      label: EPSG code 
      doc: Projection EPSG code for the bounding box coordinates
      default: "EPSG:4326"

  outputs:
    wf_results:
      outputSource:
      - node_rgb/results
      type: Directory[]

  steps:
    
    node_rgb:

      run: "#s2-compositer"

      in: 
        product: products
        red: red
        green: green
        blue: blue
        bbox: bbox
        proj: proj

      out:
      - results

      scatter: product
      scatterMethod: dotproduct 

- class: Workflow
  label: This sub-workflow generates a Sentinel-2 RGB composite 
  doc: This sub-workflow generates a Sentinel-2 RGB composite over an area of interest 
  id: s2-compositer

  requirements:
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement

  inputs:
    product:
      type: string
      label: Sentinel-2 input reference 
      doc: Sentinel-2 STAC Item
    red:
      type: string
      label: Sentinel-2 band for red channel
      doc: Sentinel-2 band for red channel
    green:
      type: string
      label: Sentinel-2 band for green channel
      doc: Sentinel-2 band for green channel
    blue:
      type: string
      label: Sentinel-2 band for blue channel
      doc: Sentinel-2 band for blue channel
    bbox:
      type: string
      label: Area of interest expressed as a bounding bbox
      doc: Area of interest expressed as a bounding bbox
    proj:
      type: string
      label: EPSG code 
      doc: Projection EPSG code for the bounding box coordinates
      default: "EPSG:4326"
    

  outputs:
    results:
      outputSource:
      - node_stac/stac
      type: Directory
      
  steps:

    node_stage_in:

      run: "#stage-in"

      in: 
        input: product
        
      out: 
        - staged 

    node_crop:

      run: "#crop-cl"

      in:
        product: 
          source: node_stage_in/staged 
        band: [ red, green, blue ]
        bbox: bbox
        epsg: proj

      out:
        - cropped_tif

      scatter: band
      scatterMethod: dotproduct 

    node_composite:

      run: "#composite-cl"

      in:
        cropped_tifs:
          source:  node_crop/cropped_tif

      out:
        - rgb_composite

    node_stac:
      
      run: "#stac-cl"

      in: 
        composite: 
          source: node_composite/rgb_composite
        product: 
          source: node_stage_in/staged 
      
      out: 
        - stac

- class: CommandLineTool

  baseCommand: Stars
  doc: "Run Stars for staging input data"
  
  id: stage-in
  arguments:
    - copy
    - -v
    - -rel
    - -r
    - '4'
    - --harvest
    - valueFrom: ${ if (inputs.input.split("#").length == 2) 
                    {
                    var args=[];
                    var assets=inputs.input.split("#")[1].split(',');
                    for (var i = 0; i < assets.length; i++)
                    {
                        args.push("-af " + assets[i]);
                    }
                    return args;
                    }
                    else {return '--empty'}
            }
    - -o 
    - ./
    - valueFrom: ${ return inputs.input.split("#")[0]; }
  inputs:
    input:
      type: string 
  outputs:
    staged:
      outputBinding:
        glob: .
      type: Directory
  
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: /srv/conda/envs/notebook/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}


- class: CommandLineTool

  id: crop-cl

  requirements:
    InitialWorkDirRequirement:
      listing:
        - entryname: environment.yaml
          entry: |- 
            name: env_crop
            channels:
              - conda-forge
            dependencies:
              - python=3.8
              - pystac
              - numpy
              - gdal=3.4
        - entryname: run.sh 
          entry: |- 
            #!/bin/sh
            /srv/conda/condabin/mamba env create -q -f environment.yaml 
            export GDAL_DATA=/srv/conda/envs/env_crop/share/gdal
            export PROJ_LIB=/srv/conda/envs/env_crop/share/proj
            /srv/conda/envs/env_crop/bin/python crop.py "$(inputs.product.dirname)/$(inputs.product.basename)" "$(inputs.band)" "$(inputs.epsg)" "$(inputs.bbox)"
            rm -fr run.sh environment.yaml crop.py .cache
        - entryname: crop.py
          entry: |-
            import pystac
            import os
            from osgeo import gdal 
            gdal.UseExceptions() 
            import sys 
            from urllib.parse import urlparse

            catalog_url = os.path.join(sys.argv[1], "catalog.json")
            common_name = sys.argv[2]
            epsg = sys.argv[3]
            bbox = [float(c) for c in sys.argv[4].split(",")]

            def get_item(catalog):
              cat = pystac.Catalog.from_file(catalog)
              try:

                  collection = next(cat.get_children())
                  item = next(collection.get_items()) 
              except StopIteration:
                  item = next(cat.get_items())
              assert item

              return item

            item = get_item(catalog_url)

            def get_asset(item, common_name):

                for _, asset in item.get_assets().items():
                    
                    if not "data" in asset.to_dict()['roles']:
                        continue

                    eo_asset = pystac.extensions.eo.AssetEOExtension(asset)
                    if not eo_asset.bands:
                        continue
                    for b in eo_asset.bands:
                        if b.properties["common_name"] == common_name:
                            return asset

            asset = get_asset(item, common_name)
            print(asset.href)


            def fix_asset_href(uri):

                parsed = urlparse(uri)
                if parsed.scheme.startswith("http"):
                    return "/vsicurl/{}".format(uri)
                elif parsed.scheme.startswith("file"):
                    return uri.replace("file://", "")
                elif parsed.scheme.startswith("s3"):
                    for var in ["AWS_REGION", "AWS_SECRET_ACCESS_KEY", "AWS_ACCESS_KEY_ID", "AWS_S3_ENDPOINT"]:
                        gdal.SetConfigOption(var, os.getenv(var))
                    return "/vsis3/{}".format(uri.replace("s3://", ""))
                else:
                    return uri

            href=fix_asset_href(asset.href)
            ds = gdal.Open(href)

            gdal.Translate(f"crop_{common_name}.tif", ds, projWin=[bbox[0], bbox[3], bbox[2], bbox[1]], projWinSRS=epsg) 
            
  baseCommand: ["/bin/sh", "run.sh"]
  arguments: []

  inputs: 
    product: 
      type: Directory
      inputBinding:
        position: 1
    band: 
      type: string
      inputBinding:
        position: 2
    bbox: 
      type: string
      inputBinding:
        position: 3
    epsg:
      type: string
      inputBinding:
        position: 4
  
  outputs:
    cropped_tif:
      outputBinding:
        glob: '*.tif'
      type: File

- class: CommandLineTool

  id: composite-cl

  requirements:
    DockerRequirement: 
      dockerPull: docker.io/mambaorg/micromamba
    InlineJavascriptRequirement: {}
    InitialWorkDirRequirement:
      listing:
        - entryname: environment.yaml
          entry: |- 
            name: env_composite
            channels:
              - conda-forge
            dependencies:
              - python=3.8
              - numpy
              - gdal=3.1.4
              - pip
              - pip:
                - rio_color
                - snuggs
        - entryname: run.sh 
          entry: |- 
            #!/bin/sh
            micromamba create -q -f environment.yaml 
            /opt/conda/envs/env_composite/bin/python composite.py
            rm -fr run.sh environment.yaml composite.py .cache
        - entryname: composite.py
          entry: |-
            import gdal 
            import snuggs
            import numpy as np
            from rio_color.operations import parse_operations

            red_tif = "$( inputs.cropped_tifs[0].path )"
            green_tif = "$( inputs.cropped_tifs[1].path )"
            blue_tif = "$( inputs.cropped_tifs[2].path )"

            in_arr = []

            for index, tiff in enumerate([red_tif, green_tif, blue_tif]):

              ds = gdal.Open(tiff)
              if index==0: 
                driver = gdal.GetDriverByName("GTiff")

                dst_ds = driver.Create(
                    "composite.tif",
                    ds.RasterXSize,
                    ds.RasterYSize,
                    3,
                    gdal.GDT_Byte,
                    options=["TILED=YES", "COMPRESS=DEFLATE", "INTERLEAVE=BAND"],
                )

                dst_ds.SetGeoTransform(ds.GetGeoTransform())
                dst_ds.SetProjection(ds.GetProjectionRef())

              data = ds.ReadAsArray().astype(float)
              in_arr.append(snuggs.eval("(interp band (asarray 0 10000) (asarray 0 1))", band=data))
              ds = None

            arr = np.stack(in_arr)

            ops = "Gamma RGB 3.5 Saturation 1.3 Sigmoidal RGB 6 0.45"

            assert arr.shape[0] == 3
            assert arr.min() >= 0
            assert arr.max() <= 1

            for func in parse_operations(ops):
                arr = func(arr)

            for index in range(1, arr.shape[0]):
               
                dst_ds.GetRasterBand(index).WriteArray(
                    (arr[index-1] * 255.0).astype(np.int)
                )

            dst_ds.FlushCache()


  baseCommand: ["/bin/sh", "run.sh"]
  arguments: []

  inputs: 
    cropped_tifs: 
      type: File[]
        
  outputs:
    rgb_composite:
      outputBinding:
        glob: composite.tif
      type: File

- class: CommandLineTool

  id: stac-cl

  requirements:
    DockerRequirement: 
      dockerPull: docker.io/mambaorg/micromamba
    InlineJavascriptRequirement: {}
    InitialWorkDirRequirement:
      listing:
        - entryname: environment.yaml
          entry: |- 
            name: env_rio_stac
            channels:
              - conda-forge
            dependencies:
              - python=3.8
              - pip
              - pip:
                - rio_stac
        - entryname: run.sh 
          entry: |- 
            #!/bin/sh
            micromamba create -q -f environment.yaml 
            /opt/conda/envs/env_rio_stac/bin/python stac.py "$(inputs.product.dirname)/$(inputs.product.basename)"
            rm -fr run.sh environment.yaml stac.py .cache
        - entryname: stac.py
          entry: |-
            import rio_stac
            import pystac 
            import shutil 
            import os
            import sys

            catalog_url = os.path.join(sys.argv[1], "catalog.json")

            def get_item(catalog):
                cat = pystac.Catalog.from_file(catalog)
                try:

                    collection = next(cat.get_children())
                    item = next(collection.get_items()) 
                except StopIteration:
                    item = next(cat.get_items())
                assert item

                return item

            item = get_item(catalog_url)

            composite_tif = "$( inputs.composite.path )"

            out_item = rio_stac.stac.create_stac_item(source=composite_tif, input_datetime=item.datetime, id="composite", asset_roles=["visual"], asset_href="composite.tif", with_proj=True, with_raster=True)

            cat = pystac.Catalog(id="catalog", description="composite")

            cat.add_items([out_item])

            cat.normalize_and_save(
                root_href="./", catalog_type=pystac.CatalogType.SELF_CONTAINED
            )
            
            shutil.copy(composite_tif, "composite")

  baseCommand: ["/bin/sh", "run.sh"]
  arguments: []

  inputs: 
    product:
      type: Directory
    composite: 
      type: File
        
  outputs:
    stac:
      outputBinding:
        glob: .
      type: Directory

$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.9
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

cwlVersion: v1.0