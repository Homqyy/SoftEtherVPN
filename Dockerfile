ARG IMAGE_NAME=centos
ARG IMAGE_VERSION=7.9.2009

FROM ${IMAGE_NAME}:${IMAGE_VERSION} as compile

ARG TARGETARCH=amd64
ARG COPY_SRC_DIR=.
ARG COPY_DST_DIR=/root
ARG VPN_NAME=vpnserver
ARG VPN_BIN_DIR=/usr/local/libexec/softether/vpnserver

COPY ${COPY_SRC_DIR} ${COPY_DST_DIR}

WORKDIR ${COPY_DST_DIR}

# install dependencies
RUN yum -y update \
    && yum -y install epel-release && yum -y update \
    && yum -y groupinstall "Development Tools" \
    && yum -y install ncurses-devel openssl11-devel libsodium-devel readline-devel zlib-devel wget

# link openssl

RUN ln -s /usr/lib64/libssl.so.1.1 /usr/lib64/libssl.so \
    && ln -s /usr/lib64/libcrypto.so.1.1 /usr/lib64/libcrypto.so \
    && ln -s /usr/include/openssl11/openssl /usr/include/openssl

# install cmake
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        CMAKE_SCRIPT_URL="https://cmake.org/files/v3.20/cmake-3.20.2-linux-x86_64.sh"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        CMAKE_SCRIPT_URL="https://cmake.org/files/v3.20/cmake-3.20.2-linux-aarch64.sh"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi; \
    wget "$CMAKE_SCRIPT_URL" \
    && CMAKE_TOOL="$(basename $CMAKE_SCRIPT_URL)" \
    && chmod +x $CMAKE_TOOL \
    && ./$CMAKE_TOOL --skip-license --prefix=/usr/local \
    && rm $CMAKE_TOOL

# build
RUN CMAKE_FLAGS="-DSE_PIDDIR=/${VPN_NAME}/pid \
    -DSE_LOGDIR=/${VPN_NAME}/log \
    -DSE_DBDIR=/${VPN_NAME}/db" \
    ./configure \
    && make -C build \
    && make -C build install

FROM ${IMAGE_NAME}:${IMAGE_VERSION}
ARG VPN_NAME
ARG VPN_BIN_DIR

RUN mkdir /${VPN_NAME} /${VPN_NAME}/bin /${VPN_NAME}/log /${VPN_NAME}/pid /${VPN_NAME}/db

# install dependencies
RUN yum -y update \
    && yum -y install epel-release && yum -y update \
    && yum -y install openssl11-libs libsodium ncurses-libs zlib readline

# copy from compile stage
COPY --from=compile ${VPN_BIN_DIR}/* /${VPN_NAME}/bin/
COPY --from=compile /usr/local/libexec/softether/vpncmd/vpncmd /${VPN_NAME}/bin/
COPY --from=compile /usr/local/lib64/libcedar.so /usr/local/lib64/libmayaqua.so /lib64/

# copy entrypoint
COPY docker/entrypoint.sh /bin/entrypoint.sh

# chmod
RUN chmod +x /${VPN_NAME}/bin/* /bin/entrypoint.sh

EXPOSE 443/tcp 992/tcp 1194/tcp 1194/udp 5555/tcp 500/udp 4500/udp

ENTRYPOINT [ "/bin/entrypoint.sh" ]