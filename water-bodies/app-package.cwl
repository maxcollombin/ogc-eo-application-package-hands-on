cwlVersion: v1.0

$graph:
- class: Workflow
 
  id: water_bodies
  label: Water bodies detection based on NDWI and otsu threshold
  doc: Water bodies detection based on NDWI and otsu threshold

  requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  
  inputs:
    aoi: 
      doc: area of interest as a bounding box
      type: string

    epsg:
      doc: EPSG code 
      type: string
      default: "EPSG:4326"

    stac_items:
      doc: list of STAC items
      type: string[]

  outputs:
  - id: detected_water_bodies
    outputSource:
    - node_water_bodies/detected_water_body
    type: Directory[]

  steps:

    node_water_bodies:

      run: "#detect_water_body"

      in:
        item: stac_items
        aoi: aoi
        epsg: epsg

      out:
      - detected_water_body
        
      scatter: item
      scatterMethod: dotproduct

- class: Workflow
 
  id: detect_water_body
  label: Water body detection based on NDWI and otsu threshold
  doc: Water body detection based on NDWI and otsu threshold

  requirements:
  - class: ScatterFeatureRequirement
  
  inputs:
    aoi: 
      doc: area of interest as a bounding box
      type: string

    epsg:
      doc: EPSG code 
      type: string
      default: "EPSG:4326"

    bands: 
      doc: bands used for the NDWI
      type: string[]
      default: ["green", "nir"]

    item:
      doc: STAC item
      type: string

  outputs:
    - id: detected_water_body
      outputSource: 
      - node_otsu/binary_mask_item
      type: Directory

  steps:

    node_crop:

      run: "#crop"

      in:
        item: item
        aoi: aoi
        epsg: epsg
        band: 
          default: ["green", "nir"]

      out:
        - cropped

      scatter: band
      scatterMethod: dotproduct

    node_normalized_difference:

      run: "#norm_diff"

      in: 
        tifs: 
          source: node_crop/cropped
        
      out:
      - ndwi

    node_otsu:

      run: "#otsu"

      in:
        raster:
          source: node_normalized_difference/ndwi
      out:
        - binary_mask_item

- class: CommandLineTool
  id: crop

  requirements:
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef: 
        PATH: /opt/conda/envs/env_app/bin
        PYTHONPATH: /workspaces/vscode-binder/command-line-tools/crop/crop
        PROJ_LIB: /opt/conda/envs/env_app/share/proj/

  baseCommand: ["python", "-m", "app"]
  arguments: []
  inputs:
    item:
      type: string
      inputBinding:
        prefix: --input-item
    aoi:
      type: string
      inputBinding:
        prefix: --aoi
    epsg:
      type: string  
      inputBinding:
        prefix: --epsg
    band:
      type: string  
      inputBinding:
        prefix: --band
  outputs: 
    cropped:
      outputBinding:
        glob: '*.tif'
      type: File

- class: CommandLineTool
  id: norm_diff

  requirements:
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef: 
        PATH: /opt/conda/envs/env_app/bin
        PYTHONPATH: /workspaces/vscode-binder/command-line-tools/norm_diff
        PROJ_LIB: /opt/conda/envs/env_app/share/proj/
  baseCommand: ["python", "-m", "app"]
  arguments: []
  inputs:
    tifs:
      type: File[]
  outputs: 
    ndwi:
      outputBinding:
        glob: '*.tif'
      type: File

- class: CommandLineTool
  id: otsu

  requirements:
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef: 
        PATH: /opt/conda/envs/env_app/bin
        PYTHONPATH: /workspaces/vscode-binder/command-line-tools/otsu
        PROJ_LIB: /opt/conda/envs/env_app/share/proj/
  baseCommand: ["python", "-m", "app"]
  arguments: []
  inputs:
    raster:
      type: File
  outputs: 
    binary_mask_item:
      outputBinding:
        glob: .
      type: Directory