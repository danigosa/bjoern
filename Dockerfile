FROM ubuntu:bionic

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

CMD ["python3", "--version"] 
