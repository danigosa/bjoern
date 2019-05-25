FROM ubuntu:bionic

MAINTAINER <danigosa danigosa@gmail.com>

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

RUN pip3 install virtualenv==16.6.0 && \
    pip3 install --upgrade pip==19.1.1 setuptools==41.0.1 wheel==0.33.4 Cython==0.29.7 && \
    python3 -m virtualenv -p /usr/bin/python3 --system-site-packages /bjoern/.py36-venv

# Python3.7
RUN \
  apt-get -qq update && \
  apt-get -qq install --no-install-recommends \
    python3.7-dev \
    python3.7-dev \
    python3.7-dbg \
    python3.7-venv && \
  rm -rf /var/lib/apt/lists/*

RUN python3.7 -m pip install virtualenv==16.6.0 && \
    python3.7 -m pip install --upgrade pip==19.1.1 setuptools==41.0.1 wheel==0.33.4 Cython==0.29.7 && \
    python3.7 -m virtualenv -p /usr/bin/python3.7 --system-site-packages /bjoern/.py37-venv


RUN ldconfig

CMD ["python3", "--version"] 
