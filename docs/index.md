
The [OGC Best Practice for Earth Observation Application Package](https://docs.ogc.org/bp/20-089r1.html) describes how to package EO computational workflows targeting their execution automation, scalability, reusability and portability while also being workflow-engine and vendor neutral.

This hands-on training targets EO application developers and provides an introduction to the Earth Observation Application Package concept and a set of real-life exercises running on an Integrated Development Environment running on Binder.

### What is an Application Package

An Earth Observation Application is set of command-line tools with numeric, textual and EO data parameters organized as a computational workflow

An Application Package is a text document that describes the input and output interface of the EO Application and the orchestration of its command-line tools

The Application Package guarantees the automation, scalability, reusability, portability of the Application while also being workflow-engine and vendor neutral.

### Bring your own algorithm

The application (e.g. Python, shell script, C++) is containerized and registered in Container Registry 

The input and output interface of the application and the orchestration of its command-line tools are described with Common Workflow Language (CWL)

The Platform converts the OGC API Processes in a CWL execution request in the computing resources of the selected provider

The Application can be deployed in multiple Clouds without lock-in 

