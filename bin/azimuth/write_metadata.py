#!/usr/bin/env python3

"""Util for copying package & reference metadata from JSON to anndata file in 'uns' slot.
This step could not be bundled with the upstream R script because of an issue with
reticulate. See: https://github.com/rstudio/reticulate/issues/209
"""

from argparse import ArgumentParser
import json
import sys
from pathlib import Path

import anndata
import pandas as pd

def main(secondary_analysis_h5ad: Path, version_metadata: Path, annotations_csv: Path):
    with open(version_metadata, "rb") as f:
        metadata = json.load(f)

    ad = anndata.read_h5ad(secondary_analysis_h5ad)

    annotations_df = pd.read_csv(annotations_csv)
    if (metadata["is_annotated"]):  # annotation was performed
        annotations_df.index = ad.obs.index  # set index for proper concatentation
        ad.obs = pd.concat([ad.obs, annotations_df], axis=1)  # add new columns to obs

    # map kidney ASCT+B annotations
    if (metadata["is_annotated"] and metadata["reference"]["name"] in {"RK", "LK"}):
        with open("/opt/kidney.json") as f:
            mapping = json.load(f)
        
        asct_annotations_name = "predicted.ASCT.celltype"
        asct_annotations = [mapping.get(a.strip(), "other") for a in annotations_df["predicted.annotation.l3"]]
        ad.obs[asct_annotations_name] = asct_annotations
        ad.obs[asct_annotations_name + ".score"] = annotations_df["predicted.annotation.l3.score"]

    ad.uns[
        "annotation_metadata"
    ] = metadata  # add metadata dict to "annotation_metadata" key in uns
    ad.write("secondary_analysis.h5ad")  # save final secondary analysis matrix


if __name__ == "__main__":
    p = ArgumentParser()
    p.add_argument("version_metadata", type=Path)
    p.add_argument("secondary_analysis_h5ad", type=Path)
    p.add_argument("annotations_csv", type=Path)
    args = p.parse_args()

    main(args.version_metadata, args.secondary_analysis_h5ad, args.annotations_csv)
