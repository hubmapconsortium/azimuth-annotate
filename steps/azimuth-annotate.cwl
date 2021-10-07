#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: azimuth:0.4.3
baseCommand: [Rscript, /azimuth_analysis.R]

inputs:
  reference:
    type: string
    inputBinding:
      position: 1
  matrix:
    type: File 
    inputBinding:
      position: 2
  secondary_analysis_matrix:
    type: File
    inputBinding:
      position: 3

outputs:
  annotated_matrix:
    type: File
    outputBinding:
      glob: "secondary_analysis.h5ad"
  version_metadata:
    type: File
    outputBinding:
      glob: "version_metadata.json"
