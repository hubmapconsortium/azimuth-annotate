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


def main(secondary_analysis_h5ad: Path, version_metadata: Path):
    with open(version_metadata, "rb") as f:
        metadata = json.load(f)

    ad = anndata.read_h5ad(secondary_analysis_h5ad)
    ad.uns[
        "annotation_metadata"
    ] = metadata  # add metadata dict to "annotation_metadata" key in uns
    ad.write("secondary_analysis.h5ad")  # save final secondary analysis matrix


if __name__ == "__main__":
    p = ArgumentParser()
    p.add_argument("version_metadata", type=Path)
    p.add_argument("secondary_analysis_h5ad", type=Path)
    args = p.parse_args()

    main(args.version_metadata, args.secondary_analysis_h5ad)
