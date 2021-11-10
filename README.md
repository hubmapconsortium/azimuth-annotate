# azimuth-annotation

Celltype annotation workflow

Overview
--------

The annotation workflow utilizes [Azimuth](https://github.com/satijalab/azimuth) to transfer celltype labels from an annotated reference to a query dataset. This CWL workflow wraps Azimuth and runs within a docker container containing all dependencies.

Requirements
------------

Running the pipeline requires a CWL workflow execution engine and container
runtime; we recommend Docker and the ``cwltool`` reference implementation.
``cwltool`` is written in Python and can be installed into a sufficiently
recent Python environment with ``pip install cwltool``. Afterward, clone this
repository, check out a tag, and invoke the pipeline as::
```
cwltool pipeline.cwl --matrix EXPR_H5AD --reference REFERENCE --secondary-analysis-matrix SECONDARY_ANALYSIS_H5AD
```
The supported values for ``--reference`` are ``RK``, ``LK``, ``RL``, or ``LL``. These two character codes indicate the side the organ was derived from (right or left) and the organ type (kidney or lung). If the value for ``--reference`` doesn't match one of the four options, the workflow will run without performing annotation.

Azimuth to ASCT+B Cell Type Mapping
-------------------------

The mapping from Azimuth cell types to ASCT+B cell types is described in JSON format in the ``data`` directory. There will be one mapping for each supported organ type and each mapping will follow the same format. The JSON contains two keys - ``versions`` and ``mapping``. ``mapping`` contains keys representing Azimuth cell types with values corresponding to ASCT+B cell types. ``versions`` contains three keys described below:

Key | Description
--- | ---
azimuth_reference | ``version`` of Azimuth. ``organ`` used. ``annotation_level`` indicates which Azimuth annotations were used for the mapping since there are usually multiple per reference.
ASCTB | The version of ASCTB annotation used in mapping.
mapping_version | The version of table itself, as it could hypothetically change independent of Azimuth and ASCTB versions.

Mapping tables are pulled into this workflow's Docker image, so for updates to be propogated the new Docker image will need to be pushed to Docker Hub.
