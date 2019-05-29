FROM ubuntu:bionic

MAINTAINER <danius danigosa@gmail.com>

ENV LC_ALL=C.UTF-8
ENV LC_CTYPE=C.UTF-8

ENV PYPY_VERSION="7.1.1-beta"

# base packages
RUN \
  apt-get -qq update && \
  apt-get -qq install --no-install-recommends \
	build-essential \
	gnupg2 \
	git \
	vim \
	wget \
	curl \
	httpie \
	make \
	gdb \
	psmisc \
	valgrind \
	apache2-utils \
	gridsite-clients \
	libev-dev && \
  wget -O /tmp/checkmake.deb \
    --content-disposition https://packagecloud.io/mrtazz/checkmake/packages/ubuntu/trusty/checkmake_0.1.0-1_amd64.deb/download.deb && \
  dpkg -i /tmp/checkmake.deb && rm -f /tmp/checkmake.deb && \
  rm -rf /var/lib/apt/lists/*

# Python3.6
RUN \
  apt-get -qq update && \
  apt-get -qq install --no-install-recommends \
 	python3-dev \
 	python3-dev \
 	python3-dbg \
	python3-venv \
	python3-pip \
	python3-setuptools \
	python3-wheel && \
  rm -rf /var/lib/apt/lists/*

RUN pip3 install \
    black==19.3b0 \
    isort[requirements]==4.3.20

RUN python3 -m venv --system-site-packages /.py36-venv && \
    /.py36-venv/bin/python -m pip install --upgrade \
        pip==19.1.1 \
        setuptools==41.0.1\
        wheel==0.33.4 \
        Cython==0.29.7

# Python3.7
RUN \
  apt-get -qq update && \
  apt-get -qq install --no-install-recommends \
    python3.7-dev \
    python3.7-dev \
    python3.7-dbg \
    python3.7-venv && \
  rm -rf /var/lib/apt/lists/*

RUN python3.7 -m venv --system-site-packages /.py37-venv && \
    /.py37-venv/bin/python -m pip install --upgrade \
        pip==19.1.1 \
        setuptools==41.0.1\
        wheel==0.33.4 \
        Cython==0.29.7

RUN ldconfig

# Install Pypy environment
RUN \
  apt-get -qy update && \
  apt-get -qy install --no-install-recommends curl ca-certificates && update-ca-certificates && \
  curl -Lo /opt/pypy.tar.bz2 https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.6-$PYPY_VERSION-linux_x86_64-portable.tar.bz2 && \
  tar -C /opt -xjf /opt/pypy.tar.bz2 && \
  ln -sf /opt/pypy3.6-$PYPY_VERSION-linux_x86_64-portable/bin/pypy3 /usr/bin/pypy3 && \
  ln -sf /opt/pypy3.6-$PYPY_VERSION-linux_x86_64-portable/bin/pypy3 /usr/bin/pypy && \
  pypy3 -m ensurepip && \
  pypy3 -m pip install --upgrade virtualenv==16.5.0 && \
  rm -f /opt/pypy.tar.bz2 && \
  apt-get -qy purge curl curl ca-certificates && \
  rm -rf /var/lib/apt/lists/*
RUN pypy3 -m virtualenv -p /usr/bin/pypy3 --system-site-packages /.pypy36-venv && \
        /.pypy36-venv/bin/pypy -m pip install --upgrade \
            pip==19.1.1 \
            setuptools==41.0.1\
            wheel==0.33.4 \
            Cython==0.29.7