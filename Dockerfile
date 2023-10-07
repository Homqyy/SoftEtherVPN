FROM homqyy/dev_env_cetos8 as compile

ARG COPY_SRC_DIR=..
ARG COPY_DST_DIR=/root
ARG BUILD_

COPY ${COPY_SRC_DIR} ${COPY_DST_DIR}

WORKDIR ${COPY_DST_DIR}

# install dependencies
RUN sudo yum -y install cmake ncurses-devel openssl-devel libsodium-devel readline-devel zlib-devel

# build
RUN git submodule init \
    && git submodule update \
    && CMAKE_FLAGS="-DSE_PIDDIR=/run/softether -DSE_LOGDIR=/var/log/softether -DSE_DBDIR=/var/lib/softether" ./configure \
    && make -C build \
    && make -C build install

# FROM centos:8

# copy from compile stage