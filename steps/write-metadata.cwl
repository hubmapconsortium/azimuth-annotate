#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: hubmap/azimuth-annotate:1.0
baseCommand: [python3, /write_metadata.py]

inputs:
  secondary_analysis_matrix:
    type: File
    inputBinding:
      position: 1
  version_metadata:
    type: File
    inputBinding:
      position: 2

outputs:
  annotated_matrix:
    type: File
    outputBinding:
      glob: "secondary_analysis.h5ad"
