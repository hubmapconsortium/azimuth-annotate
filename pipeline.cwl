#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0

inputs:
  assay:
    label: "single-cell/nucleus assay"
    type: string
  reference:
    label: "Reference type to map data to"
    type: string
  matrix:
    label: "h5 matrix containing raw counts"
    type: File 
  secondary-analysis-matrix:
    label: "h5 matrix to save annotations to"
    type: File

outputs:
  azimuth_annotated_h5ad:
    outputSource: write_metadata/annotated_matrix
    type: File
    label: "final secondary analysis matrix with all labels and metadata"

steps:
  expr_h5ad_adjust:
    run: steps/expr-h5ad-adjust.cwl
    in:
      assay:
        source: assay
      matrix:
        source: matrix
    out:
      - matrix_adj
  azimuth:
    run: steps/azimuth-annotate.cwl
    in:
      reference:
        source: reference
      matrix:
        source: expr_h5ad_adjust/matrix_adj
      secondary_analysis_matrix:
        source: secondary-analysis-matrix
    out:
      - annotated_matrix
      - version_metadata
      - annotations_csv
  write_metadata:
    run: steps/write-metadata.cwl
    in:
      secondary_analysis_matrix:
        source: azimuth/annotated_matrix
      annotations_csv:
        source: azimuth/annotations_csv
      version_metadata:
        source: azimuth/version_metadata
    out:
      - annotated_matrix
