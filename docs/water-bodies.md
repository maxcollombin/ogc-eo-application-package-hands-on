### Water bodies detection Application Package

This Application Package takes as input Copernicus Sentinel-2 data and detects water bodies by applying the Otsu thresholding technique on the Normalized Difference Water Index.

Run the water bodies detection Application Package using [Code server IDE interface](../../vscode/?folder=/home/jovyan/water-bodies)

Open a Terminal and type:

```
cwltool --no-container app-package.cwl#water_bodies params.yml > out.json
```

**Note** The flag `--no-container` is used to instruct the CWL runner to use the local command-line tools instead of using the containers as Binder cannot launch containers.

Inspect the Python command-line tools used by each step of the computational workflow.

Once completed, visualize the results with a visualization notebook on [JupyterLab](../../lab) 


