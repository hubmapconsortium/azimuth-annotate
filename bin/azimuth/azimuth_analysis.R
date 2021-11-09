#!/usr/bin/env Rscript

library(Seurat)
library(Azimuth)
library(anndata)
library(rjson)

args <- commandArgs(trailingOnly=TRUE)
reference.name <- args[1]  # currently, 'kidney' and 'lung' are the two supported references
query.h5.path <- args[2]  # path to raw counts matrix 
save.h5.path <- args[3] 

secondary.analysis.path <- "secondary_analysis.h5ad"
version.metadata.path <- "version_metadata.json"
annotations.csv.path <- "annotations.csv"

if (!file.exists(query.h5.path)) {
  stop("Path to raw counts matrix doesn't exist ", query.h5.path, call. = FALSE)
} else if (!file.exists(save.h5.path)) {
  stop("Path to secondary_analysis.h5ad ", save.h5.path, call. = FALSE)
}

if (reference.name %in% c("RK", "LK", "RL", "LL")) {
  # reference.path points to path within docker image
  if (reference.name %in% c("RK", "LK")) {
    reference.path = "/opt/human_kidney"
  } else if (reference.name %in% c("RL", "LL")) {
    reference.path = "/opt/human_lung"
  }
  if (!dir.exists(reference.path)) {
    stop("Reference path does not exist ", reference.path, call. = FALSE)
  }

  # Load reference and gather version information
  reference <- LoadReference(path = reference.path)
  reference.version <- ReferenceVersion(reference$map)
  azimuth.version <- as.character(packageVersion(pkg = "Azimuth"))
  seurat.version <- as.character(packageVersion(pkg = "Seurat"))
  max.dims <- as.double(length(slot(reference$map, "reductions")$refDR))
  meta.data <- names(slot(reference$map, "meta.data"))
  annotation.columns <- c()

  # cortex references use hierarchical annotations and all other reference annotations names match *.l[1-3]
  if (reference.name %in% c("human-cortex", "mouse-cortex")) {  # not yet supported
    annotation.columns <- c("class", "subclass", "cluster", "cross_species_cluster")
  } else {
    for (i in grep("[.]l[1-3]", meta.data)) {
      annotation.columns <- c(annotation.columns, meta.data[i])
    }
  }

  # Load the query object for mapping
  # Change the file path based on where the query file is located on your system.
  query <- LoadFileInput(path = query.h5.path)
  query <- ConvertGeneNames(
    object = query,
    reference.names = rownames(x = reference$map),
    homolog.table = 'https://seurat.nygenome.org/azimuth/references/homologs.rds'
  )

  # Calculate nCount_RNA and nFeature_RNA if the query does not
  # contain them already
  if (!all(c("nCount_RNA", "nFeature_RNA") %in% c(colnames(x = query[[]])))) {
      calcn <- as.data.frame(x = Seurat:::CalcN(object = query))
      colnames(x = calcn) <- paste(
        colnames(x = calcn),
        "RNA",
        sep = '_'
      )
      query <- AddMetaData(
        object = query,
        metadata = calcn
      )
      rm(calcn)
  }

  # Calculate percent mitochondrial genes if the query contains genes
  # matching the regular expression "^MT-"
  if (any(grepl(pattern = '^MT-', x = rownames(x = query)))) {
    query <- PercentageFeatureSet(
      object = query,
      pattern = '^MT-',
      col.name = 'percent.mt',
      assay = "RNA"
    )
  }

  # Preprocess with SCTransform
  query <- SCTransform(
    object = query,
    assay = "RNA",
    new.assay.name = "refAssay",
    residual.features = rownames(x = reference$map),
    reference.SCT.model = reference$map[["refAssay"]]@SCTModel.list$refmodel,
    method = 'glmGamPoi',
    ncells = 2000,
    n_genes = 2000,
    do.correct.umi = FALSE,
    do.scale = FALSE,
    do.center = TRUE
  )

  # Find anchors between query and reference
  anchors <- FindTransferAnchors(
    reference = reference$map,
    query = query,
    k.filter = NA,
    reference.neighbors = "refdr.annoy.neighbors",
    reference.assay = "refAssay",
    query.assay = "refAssay",
    reference.reduction = "refDR",
    normalization.method = "SCT",
    features = intersect(rownames(x = reference$map), VariableFeatures(object = query)),
    dims = 1:max.dims,
    n.trees = 20,
    mapping.score.k = 100
  )

  # Transfer cell type labels and impute protein expression
  #
  # Transferred labels are in metadata columns named "predicted.*"
  # The maximum prediction score is in a metadata column named "predicted.*.score"
  # The prediction scores for each class are in an assay named "prediction.score.*"
  # The imputed assay is named "impADT" if computed

  refdata <- lapply(X = annotation.columns, function(x) {
    reference$map[[x, drop = TRUE]]
  })
  names(x = refdata) <- annotation.columns

  query <- TransferData(
    reference = reference$map,
    query = query,
    dims = 1:max.dims,
    anchorset = anchors,
    refdata = refdata,
    n.trees = 20,
    store.weights = TRUE
  )

  # Calculate the embeddings of the query data on the reference SPCA
  query <- IntegrateEmbeddings(
    anchorset = anchors,
    reference = reference$map,
    query = query,
    reductions = "pcaproject",
    reuse.weights.matrix = TRUE
  )

  # Calculate the query neighbors in the reference
  # with respect to the integrated embeddings
  query[["query_ref.nn"]] <- FindNeighbors(
    object = Embeddings(reference$map[["refDR"]]),
    query = Embeddings(query[["integrated_dr"]]),
    return.neighbor = TRUE,
    l2.norm = TRUE
  )

  # The reference used in the app is downsampled compared to the reference on which
  # the UMAP model was computed. This step, using the helper function NNTransform,
  # corrects the Neighbors to account for the downsampling.
  query <- Azimuth:::NNTransform(
    object = query,
    meta.data = reference$map[[]]
  )

  # Project the query to the reference UMAP.
  query[["proj.umap"]] <- RunUMAP(
    object = query[["query_ref.nn"]],
    reduction.model = reference$map[["refUMAP"]],
    reduction.key = 'UMAP_'
  )

  # Calculate mapping score and add to metadata
  query <- AddMetaData(
    object = query,
    metadata = MappingScore(anchors = anchors, ndim = max.dims),
    col.name = "mapping.score"
  )

  # build and save df containing annotations and scores
  # need to gather column names to save based on the names of things which are in the reference
  # we know which columns exist based on which reference is used, thus include the columns and
  # annotation levels as metadata
  predicted.cols <- c()
  for (col in annotation.columns) {
    predicted.cols <- c(predicted.cols, paste0("predicted.", col), paste0("predicted.", col, ".score"))
  }

  # build list of matrices to append to anndata object
  ls <- list()
  for (col in predicted.cols) {
    ls <-  c(ls, list(matrix(query[[col]][[1]])))
  }
  names(ls) <- predicted.cols
  ls <- c(ls, list("mapping.score" = matrix(query$mapping.score)))

  # build and save data as a CSV
  df <- data.frame(ls)
  df <- cbind(cells = rownames(df), df)
  df["barcodes"] <- names(query$orig.ident)
  df["V1"] <- matrix(query[["proj.umap"]]@cell.embeddings, ncol=2)[,1]
  df["V2"] <- matrix(query[["proj.umap"]]@cell.embeddings, ncol=2)[,2]

  # load secondary analysis matrix as anndata object
  secondary.analysis <- read_h5ad(filename = save.h5.path)

  # expr.h5ad may contain barcodes which were filtered from secondary analysis.
  drop.bcs <- setdiff(colnames(query), rownames(secondary.analysis))
  df <- df[!df$barcodes %in% drop.bcs, ]

  # remove cells and barcodes cols and umap projection cols post-filtering
  umap.new <- matrix(c(df$V1, df$V2), ncol=2)
  df <- df[ , !(names(df) %in% c("cells", "barcodes", "V1", "V2"))]

  # add reference-guided UMAP to anndata object
  secondary.analysis$obsm$X_umap_proj <- umap.new

  # save modified secondary_analysis.h5ad matrix to a new annotated equivalent
  write_h5ad(secondary.analysis, secondary.analysis.path) 

  write.csv(df, file=annotations.csv.path, row.names=FALSE)

  version.metadata <- list(
    "is_annotated" = TRUE,
    "seurat" = list("version" = seurat.version),
    "azimuth" = list("version" = azimuth.version),
    "reference" = list("version" = reference.version, "name" = reference.name)
  )
  version.metadata.json = toJSON(version.metadata)
  f <- file("version_metadata.json")
  write(version.metadata.json, f)
  close(f)

} else {
  # no-op, but still return the unmodified secondary_analysis.h5ad and metadata indicating no annotation occurred
  write.csv(data.frame(), file=annotations.csv.path, row.names=FALSE)
  ad <- read_h5ad(save.h5.path)
  write_h5ad(ad, secondary.analysis.path)
  version.metadata <- list("is_annotated" = FALSE)
  version.metadata.json = toJSON(version.metadata)
  f <- file(version.metadata.path)
  write(version.metadata.json, f)
  close(f)
  # Create dummy annotations file if no annotation performed. Will handle this case in write_metadata.py
}
