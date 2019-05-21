FROM ubuntu:bionic

RUN \
  apt-get -qy update && \
  apt-get -qy install --no-install-recommends \
	build-essential \
	git \
	vim \
	wget \
	curl \
	make \
	gdb \
	valgrind \
	apache2-utils \
 	python3-dev \
 	python3-dbg \
	python3-venv \
	python3-pip \
	python3-setuptools \
	python3-wheel \
	libev-dev && \
  rm -rf /var/lib/apt/lists/*

RUN ldconfig

RUN pip3 install isort black twine flask

CMD ["python3", "--version"] 
