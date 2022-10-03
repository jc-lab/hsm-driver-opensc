FROM registry.access.redhat.com/ubi8/ubi-minimal as pkcs11-proxy-builder

RUN microdnf install -y \
   git wget \
   make \
   cmake \
   openssl-devel \
   gcc \
   libseccomp \
   libseccomp-devel

RUN mkdir -p /work /output
WORKDIR /work

ARG PKCS11_PROXY_VERSION=2032875c95563c15cf77395f924191fdd6a1b33f
RUN cd /work && \
   git clone https://github.com/SUNET/pkcs11-proxy && \
   cd pkcs11-proxy && \
   git checkout ${PKCS11_PROXY_VERSION} && \
   cmake . && \
   make && \
   make install && \
   make install DESTDIR=/output

FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    pcscd libpcsclite1 \
    opensc opensc-pkcs11

RUN mkdir -p /opt
COPY --from=pkcs11-proxy-builder /output /opt/pkcs11-proxy

RUN mkdir -p /opt/primekey/p11proxy-client && \
    cp -L /opt/pkcs11-proxy/usr/local/lib/libpkcs11-proxy.so /opt/primekey/p11proxy-client/p11proxy-client.so && \
    cp /opt/pkcs11-proxy/usr/local/bin/pkcs11-daemon /usr/bin/pkcs11-daemon

CMD ["pkcs11-daemon", "/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so"]

