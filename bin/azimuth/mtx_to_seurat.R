#!/usr/bin/env Rscript
library(Seurat)

args <- commandArgs(trailingOnly = TRUE)

mtx_file <- args[1]
features_file <- args[2]
barcodes_file <- args[3]

# Convert MTX to Seurat object
expression_matrix <- ReadMtx(
mtx = mtx_file, features = features_file, cells = barcodes_file,
cell.column = 1, feature.column = 1, mtx.transpose = TRUE, 
skip.cell = 1, skip.feature = 1 
)
seurat_object <- CreateSeuratObject(counts = expression_matrix)

SaveSeuratRds(
    object = seurat_object,
    file = "seurat_object.Rds"
)
