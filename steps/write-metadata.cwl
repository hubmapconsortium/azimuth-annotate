#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
requirements:
  - class: DockerRequirement
    dockerPull: hubmap/azimuth-annotate:1.3
baseCommand: [python3, /write_metadata.py]

inputs:
  orig_secondary_analysis_matrix:
    type: File
    inputBinding:
      position: 0
  secondary_analysis_matrix:
    type: File
    inputBinding:
      position: 1
  version_metadata:
    type: File
    inputBinding:
      position: 2
  annotations_csv:
    type: File
    inputBinding:
      position: 3

outputs:
  annotated_matrix:
    type: File
    outputBinding:
      glob: "secondary_analysis*"
