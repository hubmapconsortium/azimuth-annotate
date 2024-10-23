#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: hubmap/azimuth-annotate:1.8
baseCommand: [python3, /extract_rna_secondary_matrix.py]

inputs:
  secondary_analysis_matrix:
    type: File
    inputBinding:
      position: 1

outputs:
  rna_secondary_analysis_matrix:
    type: File
    outputBinding:
      glob: "secondary_analysis.h5ad"
