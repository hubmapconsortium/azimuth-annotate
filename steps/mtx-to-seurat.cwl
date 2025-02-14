cwlVersion: v1.0
class: CommandLineTool
label: converts mtx to seurat 

requirements:
  DockerRequirement:
    dockerPull: hubmap/rna-data-products-azimuth

inputs:
    matrix_files:
        type: File
        doc: count matrixes
        inputBinding:
            position: 0
    
    features_files:
        type: File
        doc: features tsvs
        inputBinding:
            position: 1
    
    barcodes_files:
        type: File
        doc: barcodes tsvs
        inputBinding:
            position: 2

outputs: 
    seurat_rds:
        type: File
        outputBinding:
            glob: "*.Rds"

baseCommand: [Rscript, /opt/mtx_to_seurat.R]