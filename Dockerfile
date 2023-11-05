ARG IMAGE_NAME=centos
ARG IMAGE_VERSION=7.9.2009

FROM $IMAGE_NAME:$IMAGE_VERSION as compile

ARG TARGETARCH
ARG COPY_SRC_DIR=.
ARG COPY_DST_DIR=/root
ARG VPN_BIN_DIR=/usr/local/libexec/softether/vpnserver
ARG VPN_CMD=vpncmd
ARG VPN_CONFIG_OPTIONS

COPY ${COPY_SRC_DIR} ${COPY_DST_DIR}

WORKDIR ${COPY_DST_DIR}

# install dependencies
RUN yum -y update \
    && yum -y install epel-release && yum -y update \
    && yum -y groupinstall "Development Tools" \
    && yum -y install ncurses-devel libsodium-devel readline-devel zlib-devel wget

# install openssl-1.1.1
RUN wget https://ftp.openssl.org/source/old/1.1.1/openssl-1.1.1.tar.gz \
        && tar -xvf openssl-1.1.1.tar.gz \
        && cd openssl-1.1.1 \
        && ./config --prefix=/usr && make && make install \
        && rm -rf openssl-1.1.1.tar.gz openssl-1.1.1

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

# prepare for arm64
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        # link openssl
        ln -s /usr/lib/libssl.so /usr/lib64/libssl.so; \
        ln -s /usr/lib/libcrypto.so /usr/lib64/libcrypto.so; \
        # no SSE2
        sed -i 's/cmake_host_system_information(RESULT HAS_SSE2 QUERY HAS_SSE2)/#cmake_host_system_information(RESULT HAS_SSE2 QUERY HAS_SSE2)/' src/Cedar/CMakeLists.txt
    fi;


# build
RUN CMAKE_FLAGS="-DSE_PIDDIR=/vpn/pid \
    -DSE_LOGDIR=/vpn/log \
    -DSE_DBDIR=/vpn/db \
    ${VPN_CONFIG_OPTIONS}" \
    ./configure \
    && make -C build \
    && make -C build install

FROM $IMAGE_NAME:$IMAGE_VERSION
ARG VPN_BIN_DIR
ARG VPN_CMD

RUN mkdir /vpn /vpn/bin /vpn/log /vpn/pid /vpn/db

# install dependencies
RUN yum -y update \
    && yum -y install epel-release && yum -y update \
    && yum -y install libsodium ncurses-libs zlib readline

# copy from compile stage
COPY --from=compile ${VPN_BIN_DIR}/* /vpn/bin/
COPY --from=compile /usr/local/libexec/softether/vpncmd/vpncmd /vpn/bin/
COPY --from=compile /usr/local/lib64/libcedar.so /usr/local/lib64/libmayaqua.so /lib64/
COPY --from=compile /usr/lib64/libssl.so /usr/lib64/libcrypto.so /lib64
COPY --from=compile /usr/include/openssl /usr/include/

# copy entrypoint
COPY docker/entrypoint.sh /bin/entrypoint.sh

# chmod
RUN chmod +x /vpn/bin/* /bin/entrypoint.sh

EXPOSE 443/tcp 992/tcp 1194/tcp 1194/udp 5555/tcp 500/udp 4500/udp

ENV VPN_CMD=${VPN_CMD}

ENTRYPOINT ["/bin/entrypoint.sh"]
