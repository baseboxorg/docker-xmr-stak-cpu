###
# Build image
###
FROM ubuntu:18.04 AS build
#FROM alpine:edge

ENV XMR_STAK_VERSION 2.4.3

COPY app /app

WORKDIR /usr/local/src

RUN apt-get install -qq --no-install-recommends -y \
      build-essential \
      ca-certificates \
      libhwloc-dev \
      libmicrohttpd-dev \
      libssl-dev \
      cmake \
      git 
   
RUN git clone https://github.com/fireice-uk/xmr-stak.git \
    && cd /xmr-stak \
    && git checkout tags/${XMR_STAK_VERSION} -b build  \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' xmrstak/donate-level.hpp \
    \
    && cmake . -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF -DHWLOC_ENABLE=ON -DXMR-STAK_COMPILE=generic \
    && make -j$(nproc) \
    \
    && cp -t /app bin/xmr-stak \
    && chmod 777 -R /app
 
 RUN apt-get purge -y -qq \
      build-essential \
      cmake \
      libhwloc-dev \
      libmicrohttpd-dev \
      libssl-dev \
      git || echo "apt-get purge error ignored" \
    && apt-get clean -qq

###
# Deployed image
###
FROM ubuntu:18.04

WORKDIR /app

RUN apt-get install -qq --no-install-recommends -y \
      ca-certificates \
      libhwloc-dev \
      libmicrohttpd-dev \
      libssl-dev \
      python2 \
      py2-pip \
      libstdc++-6-dev \
    && pip install --upgrade pip \
    && pip install envtpl

COPY --from=build app .

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["xmr-stak-cpu"]
