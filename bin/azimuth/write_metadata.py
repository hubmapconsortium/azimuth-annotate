#!/usr/bin/env python3

"""Util for copying package & reference metadata from JSON to anndata file in 'uns' slot.
This step could not be bundled with the upstream R script because of an issue with
reticulate. See: https://github.com/rstudio/reticulate/issues/209
"""

from argparse import ArgumentParser
import json
import sys
from pathlib import Path
import warnings

import anndata
import pandas as pd

def main(secondary_analysis_h5ad: Path, version_metadata: Path, annotations_csv: Path):
    with open(version_metadata, "rb") as f:
        metadata = json.load(f)
    ad = anndata.read_h5ad(secondary_analysis_h5ad)

    annotations_df = pd.read_csv(annotations_csv)
    if (metadata["is_annotated"]):  # annotation was performed
        annotations_df.index = ad.obs.index  # set index for proper concatentation

        if (metadata["azimuth_reference"]["name"] == "lung"):
            ad.obs = pd.concat([ad.obs, annotations_df], axis=1)
        elif (metadata["azimuth_reference"]["name"] == "kidney"): # map kidney ASCT+B annotations
            with open("/kidney.json") as f:
                mapping = json.load(f)

            # get mapping annotation name
            azimuth_annotation_name = "predicted." + mapping["versions"]["azimuth_reference"]["annotation_level"]
            asct_annotations_name = "predicted.ASCT.celltype"
            metadata["annotation_names"] = [asct_annotations_name, asct_annotations_name + ".score"]
            # make sure the azimuth reference version matches the azimuth reference version used in the mapping
            if metadata["azimuth_reference"]["version"] != mapping["versions"]["azimuth_reference"]["version"]:
                warnings.warn(
                    f"The Azimuth reference version does not match the \
                    Azimuth reference version used to generate the mapping! \
                    {metadata['azimuth_reference']['version']} vs \
                    {mapping['versions']['azimuth_reference']['version']}"
                )

            # if a key does not exist it will quietly map to other instead of hitting a KeyError
            asct_annotations = [mapping["mapping"].get(a.strip(), "other") for a in annotations_df[azimuth_annotation_name]]
            ad.obs[asct_annotations_name] = asct_annotations
            ad.obs[asct_annotations_name + ".score"] = annotations_df[azimuth_annotation_name + ".score"]

            # add additional metadata to 'annotation_metadata' when running
            metadata["ASCTB"] = {"version": mapping["versions"]["ASCTB"]}
            metadata["azimuth_to_ASCTB_mapping"] = {"version": mapping["versions"]["mapping_version"]}

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
