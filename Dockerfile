FROM centos:7.9.2009 as compile

ARG COPY_SRC_DIR=.
ARG COPY_DST_DIR=/root
ARG TARGETARCH=amd64

COPY ${COPY_SRC_DIR} ${COPY_DST_DIR}

WORKDIR ${COPY_DST_DIR}

# install dependencies
RUN yum -y update \
    && yum -y install epel-release \
    && yum -y groupinstall "Development Tools" \
    && yum -y install ncurses-devel openssl11-devel libsodium-devel readline-devel zlib-devel wget

# link openssl

RUN ln -s /usr/lib64/libssl.so.1.1 /usr/lib64/libssl.so \
    && ln -s /usr/lib64/libcrypto.so.1.1 /usr/lib64/libcrypto.so \
    && ln -s /usr/include/openssl11/openssl /usr/include/openssl

# update cmake
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        export CMAKE_SCRIPT_URL="https://cmake.org/files/v3.20/cmake-3.20.2-linux-x86_64.sh"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        export CMAKE_SCRIPT_URL="https://cmake.org/files/v3.20/cmake-3.20.2-linux-aarch64.sh"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi; \
    wget "$CMAKE_SCRIPT_URL" \
    && CMAKE_TOOL="$(basename $CMAKE_SCRIPT_URL)" \
    && chmod +x $CMAKE_TOOL \
    && $CMAKE_TOOL --skip-license --prefix=/usr/local \
    && rm $CMAKE_TOOL

# build
RUN git submodule init \
    && git submodule update \
    && CMAKE_FLAGS="-DSE_PIDDIR=/vpnserver/pid -DSE_LOGDIR=/vpnserver/log -DSE_DBDIR=/vpnserver/db" ./configure \
    && make -C build \
    && make -C build install

FROM centos:7.9.2009

RUN mkdir /vpnserver /vpnserver/bin /vpnserver/log /vpnserver/pid /vpnserver/db

# install dependencies
RUN yum -y install openssl11-libs libsodium ncurses-libs zlib readline

# copy from compile stage
COPY --from=compile /usr/local/libexec/softether/vpnserver/* /vpnserver/bin/
COPY --from=compile /usr/local/libexec/softether/vpncmd/vpncmd /vpnserver/bin/
COPY --from=compile /usr/local/lib64/libcedar.so /usr/local/lib64/libmayaqua.so /lib64/

# copy entrypoint
COPY docker/entrypoint.sh /bin/entrypoint.sh

# chmod
RUN chmod +x /vpnserver/bin/* /bin/entrypoint.sh

EXPOSE 443/tcp 992/tcp 1194/tcp 1194/udp 5555/tcp 500/udp 4500/udp

ENTRYPOINT [ "/bin/entrypoint.sh" ]