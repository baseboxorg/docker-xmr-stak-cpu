###
# Build image
###
FROM alpine:edge AS build
#FROM alpine:edge

ENV XMR_STAK_VERSION 2.4.3

COPY app /app

WORKDIR /usr/local/src

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd-dev \
      openssl-dev \
#      hwloc-dev@testing \
      build-base \
      cmake \
      coreutils \
      git

RUN git clone https://github.com/fireice-uk/xmr-stak.git \
    && cd xmr-stak \
    && git checkout tags/${XMR_STAK_VERSION} -b build  \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' xmrstak/donate-level.hpp \
    \
    && cmake . -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF -DHWLOC_ENABLE=OFF -DXMR-STAK_COMPILE=generic \
    && make -j$(nproc) \
    \
    && cp -t /app bin/xmr-stak \
    && chmod 777 -R /app
RUN apk del --no-cache --purge \
      libmicrohttpd-dev \
      openssl-dev \
      hwloc-dev@testing \
      build-base \
      cmake \
      coreutils \
      git || echo "apk purge error ignored"

###
# Deployed image
###
FROM alpine:edge

WORKDIR /app

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> //etc/apk/repositories
RUN apk add --no-cache \
      libmicrohttpd \
      openssl \
#      hwloc@testing \
      python2 \
      py2-pip \
      libstdc++ \
    && pip install --upgrade pip \
    && pip install envtpl

COPY --from=build app .

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["xmr-stak-cpu"]

