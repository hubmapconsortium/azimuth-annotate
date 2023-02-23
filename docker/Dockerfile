FROM satijalab/seurat:4.0.3

WORKDIR /opt

RUN apt-get update
RUN apt-get install -y libv8-dev

RUN mkdir lzf
WORKDIR /lzf
RUN wget https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf_filter.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf_filter.h
RUN mkdir lzf
WORKDIR /lzf/lzf
RUN wget https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf_c.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf_d.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzfP.h https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf.h
WORKDIR /lzf
RUN gcc -O2 -fPIC -shared lzf/*.c lzf_filter.c -I /usr/include/hdf5/serial/ -lhdf5_serial -o liblzf_filter.so
WORKDIR /
ENV HDF5_PLUGIN_PATH=/lzf

RUN pip install anndata==0.7.8
RUN R --no-echo -e "BiocManager::install(c('glmGamPoi'))"
RUN R --no-echo -e "install.packages(c('anndata', 'DT', 'future', 'ggplot2',  'googlesheets4', 'hdf5r', 'htmltools', 'httr', 'patchwork', 'rlang', 'shiny', 'shinyBS', 'shinydashboard', 'shinyjs', 'stringr', 'withr'), repo='https://cloud.r-project.org')"
RUN R --no-echo -e "remotes::install_github('immunogenomics/presto', dependencies = FALSE)"
RUN R -e "remotes::install_github(c('satijalab/seurat-data', 'satijalab/azimuth', 'mojaveazure/seurat-disk'), dependencies = FALSE)"

ARG AZIMUTH_VER=unknown
RUN echo "$AZIMUTH_VER"

COPY bin/azimuth .
COPY data .

# human kidney reference
RUN mkdir /opt/human_kidney
RUN wget -q --no-check-certificate https://zenodo.org/record/5181818/files/idx.annoy -O /opt/human_kidney/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/5181818/files/ref.Rds -O /opt/human_kidney/ref.Rds

# human lung reference
RUN mkdir /opt/human_lung
RUN wget -q --no-check-certificate https://zenodo.org/record/6342228/files/idx.annoy -O /opt/human_lung/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/6342228/files/ref.Rds -O /opt/human_lung/ref.Rds

# human heart reference
RUN mkdir /opt/human_heart
RUN wget -q --no-check-certificate https://zenodo.org/record/7032964/files/idx.annoy -O /opt/human_heart/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/7032964/files/ref.Rds -O /opt/human_heart/ref.Rds

