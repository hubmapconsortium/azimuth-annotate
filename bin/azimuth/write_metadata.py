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
import muon as mu
from os import fspath

def main(orig_secondary_analysis_matrix:Path, secondary_analysis_h5ad: Path, version_metadata: Path, annotations_csv: Path):
    with open(version_metadata, "rb") as f:
        metadata = json.load(f)
    ad = anndata.read_h5ad(secondary_analysis_h5ad)

    annotations_df = pd.read_csv(annotations_csv)
    if (metadata["is_annotated"]):  # annotation was performed
        annotations_df.index = ad.obs.index  # set index for proper concatentation
        organ = metadata["azimuth_reference"]["name"]
        if (organ in ["lung", "heart", "kidney"]):
            #ad.obs = pd.concat([ad.obs, annotations_df], axis=1)
            with open("/all_metadata.json", 'r') as j:
                all_data = json.loads(j.read())
            # for organ value in json file, pull out info 
            organ_metadata = all_data[organ]

            # get mapping annotation name
            azimuth_annotation_name = "predicted." + organ_metadata["versions"]["azimuth_reference"]["annotation_level"]
            azimuth_label = "azimuth_label"
            azimuth_id = "azimuth_id"
            cl_id = "predicted_CLID"
            standardized_label = "predicted_label"  
            match = "cl_match_type"
            score = "prediction_score"
            metadata["annotation_names"] = [azimuth_label, azimuth_id, cl_id, standardized_label, match, score]

            # make sure the azimuth reference version matches the azimuth reference version used in the mapping
            if metadata["azimuth_reference"]["version"] != organ_metadata["versions"]["azimuth_reference"]["version"]:
                warnings.warn(
                    f"The Azimuth reference version does not match the \
                    Azimuth reference version used to generate the mapping! \
                    {metadata['azimuth_reference']['version']} vs \
                    {organ_metadata['versions']['azimuth_reference']['version']}"
                )

            # get mapping data for organ
            mapping_df = pd.read_csv('/all_labels.csv')
            organ_annotation = organ + "_" + organ_metadata["versions"]["azimuth_reference"]["annotation_level"]
            mapping_df = mapping_df.loc[mapping_df['Organ_Level'] == organ_annotation]

            # make dictionary for mapping 
            keys = mapping_df['A_L'].tolist()
            a_id_map = mapping_df['A_ID'].tolist()
            cl_id_map = mapping_df['CL_ID'].tolist()
            standardized_label_map = mapping_df['Label'].tolist()
            match_map = mapping_df['CL_Match'].tolist()
            mapping_dict = dict(zip(keys, zip(a_id_map, cl_id_map, standardized_label_map, match_map)))

            ad.obs[azimuth_label] = annotations_df[azimuth_annotation_name]
            # if a key does not exist it will quietly map to other instead of hitting a KeyError
            ad.obs[[azimuth_id, cl_id, standardized_label, match]] = pd.DataFrame([mapping_dict.get(a.strip(), ["other"]*4) 
                                                                            for a in annotations_df[azimuth_annotation_name]], 
                                                                            index = ad.obs.index)
            ad.obs[score] = annotations_df[azimuth_annotation_name + ".score"]

            # add additional metadata to 'annotation_metadata' when running
            metadata["CLID"] = {"version": organ_metadata["versions"]["CL_version"]}
            metadata["azimuth_to_CLID_mapping"] = {"version": organ_metadata["versions"]["mapping_version"]}
            for (i, key) in enumerate(organ_metadata["reviewers"]):
                metadata["reviewer" + str(i + 1)] = key
            metadata["disclaimers"] = {"text": organ_metadata["disclaimer"]}

    ad.uns[
        "annotation_metadata"
    ] = metadata  # add metadata dict to "annotation_metadata" key in uns

    if orig_secondary_analysis_matrix.suffix == ".h5mu":
        mudata = mu.read(orig_secondary_analysis_matrix)
        mudata.write(orig_secondary_analysis_matrix.name)
        mu.write(f"{orig_secondary_analysis_matrix.name}/rna", ad)
    else:
        ad.write("secondary_analysis.h5ad")  # save final secondary analysis matrix


if __name__ == "__main__":
    p = ArgumentParser()
    p.add_argument("version_metadata", type=Path)
    p.add_argument("secondary_analysis_h5ad", type=Path)
    p.add_argument("annotations_csv", type=Path)
    p.add_argument("orig_secondary_analysis_matrix", type=Path)
    args = p.parse_args()

    main(args.version_metadata, args.secondary_analysis_h5ad, args.annotations_csv, args.orig_secondary_analysis_matrix)
