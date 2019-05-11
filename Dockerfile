FROM guysoft/pytorch-docker-armv7
ENV MAPZEN_API_KEY mapzen-XXXX
ENV MAPBOX_API_KEY mapbox-XXXX
ENV ALLOWED_HOSTS=*

RUN apt-get update && \
    apt-get install -y \
    libsm6 \
    libboost-all-dev \
    libglib2.0-0 \
    libxrender-dev \
    wget \
    curl \
    nginx 

RUN apt-get install -y bzip2 python3-pip


#RUN wget http://repo.continuum.io/miniconda/Miniconda4-latest-Linux-armv7l.sh
#RUN chmod 755 Miniconda4-latest-Linux-armv7l.sh
#RUN ./Miniconda3-latest-Linux-armv7l.sh -b -p /miniconda
# RUN apt-get install libopenblas-dev liblapack-dev
#RUN /miniconda/bin/conda install -y faiss-cpu
#RUN /miniconda/bin/conda install -y cython

#RUN pip3 install faiss
RUN pip3 install cython

# Build and install dlib
RUN apt-get update && \
    apt-get install -y cmake git build-essential && \
    git clone https://github.com/davisking/dlib.git /dlib && \
    mkdir /dlib/build && \
    cd /dlib/build && \
    cmake .. -DDLIB_USE_CUDA=0 -DUSE_AVX_INSTRUCTIONS=0 && \
    cmake --build . && \
    cd /dlib && \
    python3 setup.py install --no USE_AVX_INSTRUCTIONS --no DLIB_USE_CUDA 

#RUN /miniconda/bin/conda install -y pytorch=0.4.1 -c pytorch
# RUN /venv/bin/pip install http://download.pytorch.org/whl/cpu/torch-0.4.1-cp35-cp35m-linux_x86_64.whl && /venv/bin/pip install torchvision
RUN apt-get install -y libpq-dev pkg-config libfreetype6-dev libpng-dev libffi-dev python3-dev python3-setuptools gfortran libjpeg8-dev zlib1g-dev libtiff-dev libfreetype6 libfreetype6-dev libwebp-dev libopenjp2-7-dev libopenjp2-7-dev

RUN pip3 install pillow --global-option="build_ext" --global-option="--enable-zlib" --global-option="--enable-jpeg" --global-option="--enable-tiff" --global-option="--enable-freetype" --global-option="--enable-webp" --global-option="--enable-webpmux" --global-option="--enable-jpeg2000"

RUN pip3 install psycopg2
RUN pip3 install numpy

RUN mkdir /code
WORKDIR /code
COPY requirements.txt /code/
RUN pip3 install -r requirements.txt

RUN python3 -m spacy download en_core_web_sm

WORKDIR /code/api/places365
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/places365_model.tar.gz
RUN tar xf places365_model.tar.gz

WORKDIR /code/api/im2txt
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_model.tar.gz
RUN tar xf im2txt_model.tar.gz
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_data.tar.gz
RUN tar xf im2txt_data.tar.gz

RUN rm -rf /var/lib/apt/lists/*
RUN apt-get remove --purge -y cmake git && \
    rm -rf /var/lib/apt/lists/*

VOLUME /data

# Application admin creds
ENV ADMIN_EMAIL admin@dot.com
ENV ADMIN_USERNAME admin
ENV ADMIN_PASSWORD changeme

# Django key. CHANGEME
ENV SECRET_KEY supersecretkey
# Until we serve media files properly (django dev server doesn't serve media files with with debug=false)
ENV DEBUG true 

# Database connection info
ENV DB_BACKEND postgresql
ENV DB_NAME ownphotos
ENV DB_USER ownphotos
ENV DB_PASS ownphotos
ENV DB_HOST database
ENV DB_PORT 5432

ENV BACKEND_HOST localhost
ENV FRONTEND_HOST localhost

# REDIS location
ENV REDIS_HOST redis
ENV REDIS_PORT 11211

# Timezone
ENV TIME_ZONE UTC

EXPOSE 80
COPY . /code


RUN mv /code/config_docker.py /code/config.py

WORKDIR /code

ENTRYPOINT ./entrypoint.sh
