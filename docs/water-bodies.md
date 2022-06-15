### Water bodies detection Application Package

This Application Package takes as input Copernicus Sentinel-2 data and detects water bodies by applying the Otsu thresholding technique on the Normalized Difference Water Index:

``` mermaid
graph TB
  A[STAC Items] --> B
  A[STAC Items] --> C
subgraph Process STAC item
  B["crop(green)"] --> D[Normalized difference];
  C["crop(nir)"] --> D[Normalized difference];
  D --> E[Otsu threshold]
end
  E --> F[Create STAC]
```

1. Open the [Code server IDE interface](../../vscode/?folder=/home/jovyan/water-bodies) 
2. Go to `Terminal` to open a new terminal
3. Run the water bodies detection Application Package typing 

```
cwltool --no-container app-package.cwl#water_bodies params.yml > out.json
```

**Note** The flag `--no-container` is used to instruct the CWL runner to use the local command-line tools instead of using the containers as Binder cannot launch containers.


Once completed, there's a folder with the results generated.

Inspect the Python command-line tools used by each step of the computational workflow.

Once completed, visualize the results with the `visualization.ipynb` notebook on [JupyterLab](../../lab) by running all cells. 

The notebook parses the results produced looking for the STAC Catalog file `catalog.json` and add the STAC items' `data` asset on the map.



