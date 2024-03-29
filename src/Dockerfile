ARG CENTOS_VERSION

FROM quay.io/centos/centos:stream${CENTOS_VERSION} as base_image
RUN dnf -y update && dnf -y upgrade

FROM base_image as building_image
RUN dnf groupinstall -y "Development Tools"
RUN dnf install -y \
  bzip2-devel \
  libffi-devel \
  ncurses-devel \
  nss-devel \
  perl \
  sqlite-devel \
  wget \
  zlib-devel

ARG OPENSSL_VERSION="3.2.1"
ARG QUICK_BUILD="false"
ARG PY_VERSION

RUN echo "Downloading sources"

# BASE_PYTHON_VERSION: we strip the alpha, beta, rc, etc. For instance 3.11.0a3 -> 3.11.0 
RUN export BASE_PYTHON_VERSION=`echo ${PY_VERSION} | sed -r "s/([0-9]+\.[0-9]+\.[0-9]+)([a-zA-Z]+[0-9]+)?/\1/"` && \
  wget -cq https://www.python.org/ftp/python/${BASE_PYTHON_VERSION}/Python-${PY_VERSION}.tgz -O - | tar -xz && \
  wget -cq https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O - | tar -xz

RUN echo "Building OpenSSL ${OPENSSL_VERSION}"
WORKDIR /openssl-${OPENSSL_VERSION}
# Make sure to use RPATH as specified at
# https://wiki.openssl.org/index.php/Compilation_and_Installation#Using_RPATHs
RUN ./config -Wl,-rpath=/usr/local/ssl/lib64:/usr/local/lib -Wl,--enable-new-dtags --prefix=/usr/local/ssl --openssldir=/usr/local/ssl
RUN make --quiet
RUN if [ ! "${QUICK_BUILD}" = true ] ; then make test; fi
RUN make --quiet install

RUN echo "Building Python ${PY_VERSION}"
WORKDIR /Python-${PY_VERSION}
# Make sure the env variable are correctly set for Python to be able
# to link and compile against openSSL.
ENV LDFLAGS "-L/usr/local/ssl/lib64/ -Wl,-rpath=/usr/local/ssl/lib64:/usr/local/lib"
ENV LD_LIBRARY_PATH "/usr/local/ssl/lib/:/usr/local/ssl/lib64/"
ENV CPPFLAGS "-I/usr/local/ssl/include -I/usr/local/ssl/include/openssl"

RUN if [ "${QUICK_BUILD}" = true ] ; then OPTIMIZATION="" ; else OPTIMIZATION="--enable-optimizations --with-lto"; fi && \
  ./configure \
  --with-openssl=/usr/local/ssl \
  --enable-loadable-sqlite-extensions \
  --enable-shared \
  --with-system-ffi \
  --with-openssl-rpath=auto \
  --disable-test-modules \
  ${OPTIMIZATION}
RUN make --quiet
RUN make --quiet altinstall
# We make sure to remove all the fluff
# recipe taken from the official image https://github.com/docker-library/python/
RUN find /usr/local -depth \
  \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
  -o \
  \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
  \) -exec rm -rf '{}' +;
# We also remove the headers and doc for openSSL as they are no longer needed.
RUN rm -rf /usr/local/ssl/share /usr/local/ssl/include

FROM base_image
RUN dnf install -y --setopt=install_weak_deps=False \
  bzip2 \
  ca-certificates \
  libffi \
  ncurses \
  nss \
  sqlite \
  wget \
  zlib && \
  dnf clean dbcache && \
  dnf clean all && \
  dnf autoremove -y && \
  rm -rf /var/cache/dnf
COPY --from=building_image /usr/local/ /usr/local/
ARG PY_VERSION
ARG CREATION_COMMIT_SHA
ENV LD_LIBRARY_PATH "/usr/local/ssl/lib/:/usr/local/ssl/lib64/"
ENV CREATION_COMMIT_SHA ${CREATION_COMMIT_SHA}
RUN echo "Python ${PY_VERSION} has been successfully installed and is accessible at /usr/local/bin/python3."
# OpenSSL looks into ${OPENSSLDIR}/certs as CA trust store. By default this is
# empty, and installing ca-certificates with apt-get populates it in the system
# openssl at /usr/lib/ssl/certs/. Our compiled openssl looks into
# /usr/local/ssl/certs, we create a symlink between the two to let Python access
# the OS trust store.
RUN rm -rf /usr/local/ssl/certs && ln -s /usr/lib/ssl/certs/ /usr/local/ssl/certs

WORKDIR /usr/local/bin/
RUN ln -s python${PY_VERSION%.*} python \
  && ln -s python${PY_VERSION%.*} python3
CMD ["/usr/local/bin/python3"]
