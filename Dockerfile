FROM ubuntu:bionic

ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/lib:/usr/lib:/usr/local/lib"

RUN \
  apt-get -qq update && \
  apt-get -qq install --no-install-recommends \
	build-essential \
	git \
	vim \
	wget \
	make \
 	python3-dev \
	python3-venv \
	python3-pip \
	python3-setuptools \
	python3-wheel \
	libev-dev && \
  rm -rf /var/lib/apt/lists/*

RUN ldconfig -p

CMD ["python3", "--version"] 
