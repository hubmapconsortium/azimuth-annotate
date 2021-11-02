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
