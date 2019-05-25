SHELL=/bin/bash

.PHONY: default setup test all again clean
default: test

SOURCE_DIR	:= bjoern
BUILD_DIR	:= build
PYTHON36	:= /.py36-venv/bin/python
DEBUG := DEBUG=True

PYTHON36_INCLUDE	:= $(shell python3-config --includes | sed s/-I/-isystem\ /g)
PYTHON36_LDFLAGS	:= $(shell python3-config --ldflags)

HTTP_PARSER_DIR	:= http-parser
HTTP_PARSER_OBJ := $(HTTP_PARSER_DIR)/http_parser.o
HTTP_PARSER_SRC := $(HTTP_PARSER_DIR)/http_parser.c

HTTP_PARSER_URL_DIR	:= http-parser/contrib
HTTP_PARSER_URL_OBJ := $(HTTP_PARSER_URL_DIR)/url_parser

objects		:= 	$(HTTP_PARSER_OBJ) $(HTTP_PARSER_URL_OBJ) \
		  		$(patsubst $(SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, \
		             $(wildcard $(SOURCE_DIR)/*.c))
FEATURES :=
ifneq ($(WANT_SENDFILE), no)
FEATURES	+= -D WANT_SENDFILE
endif

ifneq ($(WANT_SIGINT_HANDLING), no)
FEATURES	+= -D WANT_SIGINT_HANDLING
endif

ifneq ($(WANT_SIGNAL_HANDLING), no)
FEATURES	+= -D WANT_SIGNAL_HANDLING
endif

ifndef SIGNAL_CHECK_INTERVAL
FEATURES	+= -D SIGNAL_CHECK_INTERVAL=0.1
endif
CC 			:= gcc
CPPFLAGS	+= $(PYTHON36_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CFLAGS		+= $(FEATURES) -std=c99 -fno-strict-aliasing -fcommon -fPIC -Wall
LDFLAGS		+= $(PYTHON36_LDFLAGS) -pthread -shared -fcommon

IMAGE_B64 	:= $(shell cat tests/charlie.jpg | base64)
AB			:= ab -c 100 -n 10000
TEST_URL	:= "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"

flask_bench := bench/flask.txt

# Targets
setup: clean prepare-build

all: setup $(objects) _bjoernmodule test

print-env:
	@echo CFLAGS=$(CFLAGS)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo args=$(HTTP_PARSER_SRC) $(wildcard $(SOURCE_DIR)/*.c)
	@echo FEATURES=$(FEATURES)

_bjoernmodule:
	@$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON36} -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

again: clean all

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c
	@echo ' -> ' $(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# foo.o: shortcut to $(BUILD_DIR)/foo.o
%.o: $(BUILD_DIR)/%.o

reqs-36: install-requirements
	@bash install-requirements $(PYTHON36)

fmt:
	@isort --settings-path=/.isort.cfg **/*.py
	@black .

prepare-build: fmt
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)/*
	@rm -f /tmp/*.tmp

# Test
test: reqs-36 fmt install_debug
	@pytest

# Benchmarks
$(flask_bench): bench/flask.txt
	@$(PYTHON36) bench/flask_bench.py & jobs -p >/var/run/flask_bench.pid
	@sleep 5

flask_ab:
	@cat $(ab1) | tee $(flask_bench)
	@cat /var/run/flask_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/flask_bench.pid > /dev/null 2>&1

_bottle_bench:
	@$(PYTHON36) bench/bottle_bench.py & jobs -p >/var/run/bottle_bench.pid
	@sleep 5

bottle_ab: _bottle_bench ab1 ab1k ab2 ab2k
	@cat /var/run/bottle_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/bottle_bench.pid > /dev/null 2>&1

_falcon_bench:
	@$(PYTHON36) bench/falcon_bench.py & jobs -p >/var/run/falcon_bench.pid
	@sleep 5

falcon_ab: _falcon_bench ab1 ab1k ab2 ab2k
	@cat /var/run/falcon_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/falcon_bench.pid > /dev/null 2>&1

bjoern_bench: clean fmt install

ab1 := /tmp/ab1$(shell date +%s).tmp
$(ab1): $(ab1)
	$(AB) $(TEST_URL) | tee $@

ab2:
	@echo 'asdfghjkl=asdfghjkl&qwerty:qwertyuiop&image=$(IMAGE_B64)' > /tmp/bjoern-post.tmp
	$(AB) -p /tmp/bjoern-post.tmp $(TEST_URL)

ab1k:
	$(AB) -k $(TEST_URL)
ab2k:
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop' > /tmp/bjoern-post.tmp
	$(AB) -k -p /tmp/bjoern-post.tmp $(TEST_URL)

ab1j:
	$(AB) -T application/json $(TEST_URL)
ab2j:
	@echo {asdfghjkl=asdfghjkl&qwerty:qwertyuiop}' > /tmp/bjoern-post.tmp
	$(AB) -p /tmp/bjoern-post.tmp $(TEST_URL)

ab1jk:
	$(AB) -T application/json -k $(TEST_URL)
ab2jk:
	@echo {asdfghjkl=asdfghjkl&qwerty:qwertyuiop}' > /tmp/bjoern-post.tmp
	$(AB) -T application/json -k -p /tmp/bjoern-post.tmp  $(TEST_URL)

# Memory checks
valgrind:
	valgrind --leak-check=full --show-reachable=yes ${PYTHON36} tests/empty.py

callgrind:
	valgrind --tool=callgrind ${PYTHON36} tests/wsgitest-round-robin.py

memwatch:
	watch -n 0.5 \
	  'cat /proc/$$(pgrep -n ${PYTHON36})/cmdline | tr "\0" " " | head -c -1; \
	   echo; echo; \
	   tail -n +25 /proc/$$(pgrep -n ${PYTHON36})/smaps'

# Pypi
uninstall-36: clean
	@pip3 uninstall -y bjoern || { echo "Not installed."; }

install-debug-36: uninstall-36
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON36} setup.py build_ext
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON36} setup.py install

install-36: uninstall-36
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON36} setup.py build_ext
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON36} setup.py install

upload-36:
	${PYTHON36} setup.py sdist upload

wheel-36:
	${PYTHON36} setup.py bdist_wheel

upload-wheel-36: wheel
	twine upload --skip-existing dist/*.whl

# Vendors
libev:
	# http-parser 2.9.2
	@git submodule update --init --recursive
	@cd $(HTTP_PARSER_DIR) && git checkout 5c17dad400e45c5a442a63f250fff2638d144682

$(HTTP_PARSER_OBJ): libev
	$(MAKE) -C $(HTTP_PARSER_DIR) http_parser.o url_parser CFLAGS_DEBUG_EXTRA=-fPIC CFLAGS_FAST_EXTRA="-pthread -fPIC -march='core-avx2' -mtune='core-avx2'"