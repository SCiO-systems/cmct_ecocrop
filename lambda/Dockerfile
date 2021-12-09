FROM public.ecr.aws/lambda/provided

ENV R_VERSION=3.6.3
ENV PROJ_VERSION=6.1.1
ENV GEOS_VERSION=3.6.0
ENV GDAL_VERSION=3.0.4
ENV PATH="${PATH}:/opt/R/${R_VERSION}/bin/"

# install R and base image OS needed dependencies
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
    openssl-devel \
    libxml2-devel \
    unzip \
    wget \
    tar \
    bzip2 \
    yum-utils \
    gcc-c++.x86_64 \
    cpp.x86_64 \
    sqlite-devel.x86_64 \
    libtiff.x86_64 \
    cmake3.x86_64 \
    && yum clean all \
    && rm -rf /var/cache/yum/*

# PROJ Installation
RUN cd /tmp
RUN wget https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
RUN tar -xvf proj-${PROJ_VERSION}.tar.gz
RUN cd proj-${PROJ_VERSION} \
    && ./configure \
    && make -j4 \
    && make install

# GEOS Installation
RUN cd /tmp
RUN wget http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2
RUN bunzip2 geos-${GEOS_VERSION}.tar.bz2 && tar -xvf geos-${GEOS_VERSION}.tar
RUN cd geos-${GEOS_VERSION} \
    && ./configure \
    && make -j4 \
    && make install

# GDAL Installation
RUN cd /tmp
RUN wget https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
RUN tar -xvf gdal-${GDAL_VERSION}.tar.gz
RUN cd gdal-${GDAL_VERSION} \
    && ./configure \
    && make -j4 \
    && make install

# install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -f awscliv2.zip

# install R packages
RUN Rscript -e "install.packages(c('httr', 'logger', 'glue', 'terra', 'Recocrop', 'aws.s3', 'rjson', 'jsonlite', 'stringi'), repos = 'https://cloud.r-project.org/')"

RUN aws configure set aws_access_key_id <<aws_access_key_id>>
RUN aws configure set aws_secret_access_key <<aws_secret_access_key>>

# Copy R runtime and inference code
COPY runtime.R ecocrop.R ${LAMBDA_TASK_ROOT}/
RUN chmod 755 -R ${LAMBDA_TASK_ROOT}/

COPY bootstrap ${LAMBDA_RUNTIME_DIR}/
RUN chmod 755 ${LAMBDA_RUNTIME_DIR}/bootstrap
RUN rm -rf /tmp/*

CMD [ "ecocrop.handler" ]