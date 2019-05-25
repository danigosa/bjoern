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

AB			:= ab -c 100 -n 10000
TEST_URL	:= "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"

IMAGE_B64 := $(shell cat tests/charlie.jpg | base64 | xargs urlencode)
IMAGE_B64_LEN := $(shell cat tests/charlie.jpg | base64 | xargs urlencode | wc -c)
flask_bench_36 := bench/flask_py36.txt
bottle_bench_36 := bench/bottle_py36.txt
falcon_bench_36 := bench/falcon_py36.txt
ab1 := /tmp/ab1.tmp
ab2 := /tmp/ab2.tmp

# Targets
setup-36: clean prepare-build reqs-36

all-36: setup-36 $(objects) _bjoernmodule test

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
test-36: fmt reqs-36 install-debug-36
	@$(PYTHON36) -m pytest

# Benchmarks
$(flask_bench_36):
	@$(PYTHON36) bench/flask_bench.py & jobs -p >/var/run/flask_bench.pid
	@sleep 5

flask-ab-36: $(flask_bench_36) $(ab1) $(ab2)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_bench_36) > /dev/null
	@cat $(ab1) | tee $(flask_bench_36) > /dev/null
	@echo -e "\n====== POST ======\n" | tee -a $(flask_bench_36) > /dev/null
	@cat $(ab2) | tee -a $(flask_bench_36) > /dev/null
	@cat /var/run/flask_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/flask_bench.pid > /dev/null 2>&1

$(bottle_bench_36):
	@$(PYTHON36) bench/bottle_bench.py & jobs -p >/var/run/bottle_bench.pid
	@sleep 5

bottle-ab-36: $(bottle_bench_36) $(ab1) $(ab2)
	@echo -e "\n====== GET ======\n" | tee -a $(bottle_bench_36) > /dev/null
	@cat $(ab1) | tee $(bottle_bench_36) > /dev/null
	@echo -e "\n====== POST ======\n" | tee -a $(bottle_bench_36) > /dev/null
	@cat $(ab2) | tee -a $(bottle_bench_36) > /dev/null
	@cat /var/run/bottle_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/bottle_bench.pid > /dev/null 2>&1

$(falcon_bench_36):
	@$(PYTHON36) bench/falcon_bench.py & jobs -p >/var/run/falcon_bench.pid
	@sleep 5

falcon-ab-36: $(falcon_bench_36) $(ab1) $(ab2)
	@echo -e "\n====== GET ======\n" | tee -a $(falcon_bench_36) > /dev/null
	@cat $(ab1) | tee $(falcon_bench_36) > /dev/null
	@echo -e "\n====== POST ======\n" | tee -a $(falcon_bench_36) > /dev/null
	@cat $(ab2) | tee -a $(falcon_bench_36) > /dev/null
	@cat /var/run/falcon_bench.pid | xargs -n1 kill -9 > /dev/null 2>&1
	@rm -f /var/run/falcon_bench.pid > /dev/null 2>&1

_clean_bench:
	@rm -rf bench/*.txt
	@rm -rf tmp/*.tmp

bjoern-bench-36: clean _clean_bench setup-36 install-36 flask-ab-36 bottle-ab-36 falcon-ab-36

$(ab1): /tmp/ab1.tmp
	@$(AB) $(TEST_URL) | tee "$@"
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a "$@"
	@$(AB) -k $(TEST_URL) | tee -a "$@"

$(ab2): /tmp/ab2.tmp
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop&image=$(IMAGE_B64)' > /tmp/bjoern-post.tmp
	@echo $(IMAGE_B64_LEN)
	$(AB) -T 'application/x-www-form-urlencoded' -p /tmp/bjoern-post.tmp $(TEST_URL) | tee "$@"
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a "$@"
	$(AB) -T 'application/x-www-form-urlencoded' -k -p /tmp/bjoern-post.tmp $(TEST_URL) | tee -a "$@"

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
uninstall-36:
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