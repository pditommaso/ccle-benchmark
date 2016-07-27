FROM debian:jessie
MAINTAINER Paolo Di Tommaso <paolo.ditommaso@gmail.com>

RUN apt-get update --fix-missing \ 
	&& apt-get install -y --no-install-recommends \
		ed \
		less \
		locales \
		vim-tiny \
		wget \
		curl \
		zip \	
		unzip \	
		ca-certificates \
		parallel \
	&& rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
	
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8


RUN apt-get update --fix-missing && \
        apt-get install -y \
		build-essential \
		cmake \
		hdf5-tools \
		libhdf5-dev \
		hdf5-helpers \
		libhdf5-serial-dev \
		libcurl4-gnutls-dev \
		libxml2-dev \
		libssl-dev 
		
#
# Install Kallisto
# 
RUN wget -q https://github.com/pachterlab/kallisto/archive/v0.43.0.zip \
    && unzip v0.43.0.zip \
    && mkdir kallisto-0.43.0/build \
    && cd kallisto-*/build \
    && cmake .. \
	&& make \
	&& make install \
	&& rm -rf ../kallisto-0.43.0
	
#
# Trim Galore
#	
RUN wget -q http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/trim_galore_v0.4.1.zip \
  && unzip trim_galore_v0.4.1.zip \
  && mv trim_galore_zip/trim_galore /usr/local/bin/ \
  && rm -rf trim_galore_zip \
  && rm trim_galore_v0.4.1.zip 
    
#
# Sambamba
#
RUN wget -q https://github.com/lomereiter/sambamba/releases/download/v0.6.3/sambamba_v0.6.3_linux.tar.bz2 \
  && tar xf sambamba_v0.6.3_linux.tar.bz2 \ 
  && mv sambamba_v0.6.3 /usr/local/bin/sambamba \
  && rm sambamba_v0.6.3_linux.tar.bz2     
  
#
# Oracle java 
# 
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
  && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
  && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
  && apt-get update \
  && apt-get install -y oracle-java8-installer
  
#
# Picard 
#  
RUN wget -q https://github.com/broadinstitute/picard/releases/download/2.5.0/picard-tools-2.5.0.zip \
  && unzip picard-tools-2.5.0.zip \
  && rm picard-tools-2.5.0.zip

COPY scripts/picard /usr/local/bin/picard

#
# Python 
#
RUN apt-get update --fix-missing && apt-get install -y python libpython-all-dev \
  && wget -qO- https://pypi.python.org/packages/15/a6/a05e99472b517aafd48824016f66458a31303f05256e9438ce9aec6b6bab/cutadapt-1.10.tar.gz | tar xz \
  && cd cutadapt-* \
  && python setup.py install \
  && cd .. && rm -rf cutadapt-*