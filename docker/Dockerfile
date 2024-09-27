FROM satijalab/azimuth:0.5.0

RUN pip install anndata==0.9.2 muon==0.1.5
RUN R --no-echo -e "options(repos = list(CRAN = 'http://cran.rstudio.com')); remotes::install_version('Matrix', version = '1.6.1.1')"
RUN R --no-echo -e "BiocManager::install(c('glmGamPoi'))"
RUN R --no-echo -e "install.packages(c('anndata', 'DT', 'future', 'ggplot2',  'googlesheets4', 'hdf5r', 'htmltools', 'httr', 'patchwork', 'rlang', 'shiny', 'shinyBS', 'shinydashboard', 'shinyjs', 'stringr', 'withr'), repo='https://cloud.r-project.org')"
RUN R --no-echo -e "remotes::install_github('immunogenomics/presto', dependencies = FALSE)"


COPY bin/azimuth .
COPY data .

# human kidney reference
RUN mkdir /opt/human_kidney
RUN wget -q --no-check-certificate https://zenodo.org/records/10694842/files/idx.annoy -O /opt/human_kidney/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/records/10694842/files/ref.Rds -O /opt/human_kidney/ref.Rds

# human lung reference
RUN mkdir /opt/human_lung
RUN wget -q --no-check-certificate https://zenodo.org/record/6342228/files/idx.annoy -O /opt/human_lung/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/6342228/files/ref.Rds -O /opt/human_lung/ref.Rds

# human heart reference
RUN mkdir /opt/human_heart
RUN wget -q --no-check-certificate https://zenodo.org/record/7032964/files/idx.annoy -O /opt/human_heart/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/7032964/files/ref.Rds -O /opt/human_heart/ref.Rds

# added pancreas reference 
RUN mkdir /opt/human_pancreas
RUN wget -q --no-check-certificate https://zenodo.org/record/4546926/files/idx.annoy -O /opt/human_pancreas/idx.annoy
RUN wget -q --no-check-certificate https://zenodo.org/record/4546926/files/ref.Rds -O /opt/human_pancreas/ref.Rds
