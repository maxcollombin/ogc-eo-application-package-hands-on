### Water bodies detection Application Package scripted execution

**Bob scripts the execution of the Application package**

Alice included in the water bodies detection Application Package software repository a Continuous Integration configuration relying on Github Actions to:

* build the containers
* push the built containers to Github container registry
* update the Application Package with these new container references
* push the updated Application Package to Github's artifact registry

Bob scripts the Application Execution. His environment has a container engine (e.g. docker) and the `cwltool` CWL runner.

To do so, Bob:
- downloads the latest Water bodies detection Application Package from https://github.com/Terradue/ogc-eo-application-package-hands-on/releases
- creates the `params.yml` file (or uses Alice's)
- invokes:

```
cwltool --no-container <app-water-bodies-m.n.x.cwl#water_bodies params.yml
```

Where `m.n.x` is the version of the Application Package