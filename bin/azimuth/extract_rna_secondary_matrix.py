#!/usr/bin/env python3

"""Util for copying package & reference metadata from JSON to anndata file in 'uns' slot.
This step could not be bundled with the upstream R script because of an issue with
reticulate. See: https://github.com/rstudio/reticulate/issues/209
"""

from argparse import ArgumentParser
from pathlib import Path
from os import fspath

import anndata
import muon as mu

def main(secondary_analysis_matrix: Path):
    adata = mu.read(f"{fspath(secondary_analysis_matrix)}/rna") if secondary_analysis_matrix.suffix == ".h5mu" else anndata.read_h5ad(secondary_analysis_matrix)
    adata.write('secondary_analysis.h5aq:qd')

if __name__ == "__main__":
    p = ArgumentParser()
    p.add_argument("secondary_analysis_matrix", type=Path)
    args = p.parse_args()

    main(args.secondary_analysis_matrix)
