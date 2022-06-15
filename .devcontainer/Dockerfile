FROM mambaorg/micromamba

USER root

ENV USERNAME=mambauser 

ENV PATH=/opt/conda/envs/env_eo_snuggs/bin:$PATH

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl sudo git gcc build-essential tree nodejs

RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chown -R mambauser:1000 /opt/conda/

USER mambauser

#ADD .devcontainer/environment.yml /tmp/environment.yml

RUN micromamba create -n env_crop -c conda-forge gdal click pystac  
RUN micromamba create -n env_norm_diff -c conda-forge click gdal  
RUN micromamba create -n env_otsu gdal -c conda-forge scikit-image click gdal 
RUN micromamba create -n env_stac -c conda-forge click pystac python=3.9 pip && \
    /opt/conda/envs/env_stac/bin/pip install rio_stac


RUN micromamba create -n env_base -c conda-forge -c terradue Stars black awscli cwltool

WORKDIR /home/mambauser
