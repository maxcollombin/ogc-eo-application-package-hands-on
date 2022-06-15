## EO Application Packages - hands-on

### About 

The [OGC Best Practice for Earth Observation Application Package](https://docs.ogc.org/bp/20-089r1.html) describes how to package EO computational workflows targeting their execution automation, scalability, reusability and portability while also being workflow-engine and vendor neutral.

This hands-on training targets EO application developers and provides an introduction to the Earth Observation Application Package concept and a set of real-life exercises running on an Integrated Development Environment running on Binder.

### What is an Application Package

An Earth Observation Application is set of command-line tools with numeric, textual and EO data parameters organized as a computational workflow

An Application Package is a text document that describes the input and output interface of the EO Application and the orchestration of its command-line tools

The Application Package guarantees the automation, scalability, reusability, portability of the Application while also being workflow-engine and vendor neutral.

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


