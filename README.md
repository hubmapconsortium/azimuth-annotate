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
cwltool pipeline.cwl --matrix EXPR_H5AD --reference REFERENCE --secondary-analysis-matrix SECONDARY_ANALYSIS_H5AD --assay ASSAY
```
The supported values for ``--reference`` are ``RK``, ``LK``, ``RL``, ``LL``, ``HT``. These two character codes indicate the side the organ was derived from (if applicable) and the organ type (kidney, lung, or heart). If the value for ``--reference`` doesn't match one of the five options, the workflow will run without performing annotation. 
The supported values for ``--assay`` are included [here](https://github.com/hubmapconsortium/expr-h5ad-adjust/blob/main/bin/expr_h5ad_adjust.py).

Azimuth to Cell Ontology Mapping
-------------------------

The mapping from Azimuth cell types to Cell Ontology IDs is described in csv format in the ``data`` directory. Each Azimuth label for each organ maps to a corresponding Azimuth ID, CL ID, and standardized label. There is also associated metadata for each organ in ``all_metadata.json`` in the ``data`` directory. The JSON contains a key per organ. Within each organ's metadata there are the same three keys: ``versions``,  ``reviewers``,  and ``disclaimer``. ``versions`` contains the three keys described below:

Key | Description
--- | ---
azimuth_reference | ``version`` of Azimuth. ``organ`` used. ``annotation_level`` indicates which Azimuth annotations were used for the mapping since there are usually multiple per reference. ``doi`` of the Azimuth reference. 
CL_version | The version of Cell Ontology used in mapping.
mapping_version | The version of table itself, as it could hypothetically change independent of Azimuth and ASCTB versions.


Mapping tables are pulled into this workflow's Docker image, so for updates to be propogated the new Docker image will need to be pushed to Docker Hub.
