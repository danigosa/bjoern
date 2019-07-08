SHELL=/bin/bash

.PHONY: default setup test all again clean
default: test

SOURCE_DIR	:= src
BUILD_DIR	:= build
GUNICORN	:= /.py37-venv/bin/gunicorn
PYTHON		:= /.py37-venv/bin/python3
PIP			:= /.py37-venv/bin/pip3
DEBUG 		:= DEBUG=True

PYTHON_INCLUDE	:= $(shell python3.7-config --includes | sed s/-I/-isystem\ /g)
PYTHON_LDFLAGS	:= $(shell python3.7-config --ldflags)


HTTP_PARSER_DIR	:= vendors/http-parser
HTTP_PARSER_OBJ := $(HTTP_PARSER_DIR)/http_parser.o
HTTP_PARSER_SRC := $(HTTP_PARSER_DIR)/http_parser.c

HTTP_PARSER_URL_DIR	:= vendors/http-parser
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

CC 				:= gcc
CPPFLAGS		+= $(PYTHON_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CFLAGS			+= $(FEATURES) -std=c17 -fno-strict-aliasing -fcommon -fPIC -Wall -D DEBUG
LDFLAGS			+= $(PYTHON_LDFLAGS) -shared -fcommon

AB								:= ab -c 100 -n 10000
TEST_URL						:= "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
IMAGE_B64 						:= $(shell cat bjoern/tests/charlie.jpg | base64 | xargs urlencode)
IMAGE_B64_LEN 					:= $(shell cat bjoern/tests/charlie.jpg | base64 | xargs urlencode | wc -c)
flask_bench 					:= bjoern/bench/flask_py37.txt
bottle_bench 					:= bjoern/bench/bottle_py37.txt
falcon_bench 					:= bjoern/bench/falcon_py37.txt
flask_gworker_bench 			:= bjoern/bench/flask_gworker_py37.txt
flask_valgrind			 		:= bjoern/bench/flask_valgrind_py37.mem
flask_callgrind			 		:= bjoern/bench/flask_callgrind_py37.mem
ab_post 						:= /tmp/bjoern.post

# Targets
setup: clean prepare-build reqs

all: setup $(objects) _bjoernmodule test

print-env:
	@echo CFLAGS=$(CFLAGS)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo args=$(HTTP_PARSER_SRC) $(wildcard $(SOURCE_DIR)/*.c)
	@echo FEATURES=$(FEATURES)

_bjoernmodule:
	@$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

again: print-env all

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c
	@echo ' -> ' $(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# foo.o: shortcut to $(BUILD_DIR)/foo.o
%.o: $(BUILD_DIR)/%.o


reqs:
	@bash install-requirements $(PIP)

fmt:
	@$(PYTHON) -m isort --settings-path=/.isort.cfg **/*.py
	@$(PYTHON) -m black .

prepare-build:
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)/*
	@rm -rf _bjoern.*.so
	@rm -rf *.egg-info
	@rm -rf dist/*
	@rm -f /tmp/*.tmp

# Test
test: clean reqs install-debug
	@$(PYTHON) -m pytest

# Pypi
extension:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) setup.py build_ext

install-debug:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip install --editable .

uninstall: clean
	@DEBUG=False PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip uninstall -y bjoern

install:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip install --editable .

upload:
	$(PYTHON) setup.py sdist
	$(PYTHON) -m twine upload --repository=robbie-pypi dist/*.tar.gz

wheel:
	$(PYTHON) setup.py bdist_wheel

install-debug:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip install --editable .

uninstall: clean
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip uninstall -y bjoern

install:
	@DEBUG=False @PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) -m pip install --editable .

install-bench: uninstall extension
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON) setup.py install

upload:
	$(PYTHON) setup.py sdist
	$(PYTHON) -m twine upload --repository=robbie-pypi dist/*.tar.gz

wheel:
	$(PYTHON) setup.py bdist_wheel

upload-wheel: wheel
	@$(PYTHON) -m twine upload --skip-existing dist/*.whl

# Vendors
http-parser:
	# http-parser 2.9.2
	@cd $(HTTP_PARSER_DIR) && git checkout 5c17dad400e45c5a442a63f250fff2638d144682

$(HTTP_PARSER_OBJ): http-parser
	$(MAKE) -C $(HTTP_PARSER_DIR) http_parser.o url_parser CFLAGS_DEBUG_EXTRA=-fPIC CFLAGS_FAST_EXTRA="-pthread -fPIC -march='core-avx2' -mtune='core-avx2'"

# Benchmarks
$(ab_post):
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop&image=$(IMAGE_B64)' > "$@"
	@echo $(IMAGE_B64_LEN)

$(flask_bench):
	@$(PYTHON) bjoern/bench/flask_bench.py & jobs -p >/var/run/flask_bjoern.bench.pid
	@sleep 2

flask-ab: $(flask_bench) $(ab_post)
	@echo -e "\n====== Flask(Python3.7) ======\n" | tee -a $(flask_bench)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_bench)
	@$(AB) $(TEST_URL) | tee -a $(flask_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_bench)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_bench)
	@killall -9 $(PYTHON) && sleep 2

$(flask_gworker_bench):
	@$(GUNICORN) bjoern.bench.flask_bench:app --bind localhost:8080 --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker: $(flask_gworker_bench) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker(Python3.7) ======\n" | tee -a $(flask_gworker_bench)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench)
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench)
	@killall -9 gunicorn && sleep 2

$(bottle_bench):
	@$(PYTHON) bjoern/bench/bottle_bench.py & jobs -p >/var/run/bottle_bjoern.bench.pid
	@sleep 2

bottle-ab: $(bottle_bench) $(ab_post)
	@echo -e "\n====== Bottle(Python3.7) ======\n" | tee -a $(bottle_bench)
	@echo -e "\n====== GET ======\n" | tee -a $(bottle_bench)
	@$(AB) $(TEST_URL) | tee -a $(bottle_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench)
	@$(AB) -k $(TEST_URL) | tee -a $(bottle_bench)
	@echo -e "\n====== POST ======\n" | tee -a $(bottle_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(bottle_bench)
	@killall -9 $(PYTHON) && sleep 2

$(falcon_bench):
	@$(PYTHON) bjoern/bench/falcon_bench.py & jobs -p >/var/run/falcon_bjoern.bench.pid
	@sleep 2

falcon-ab: $(falcon_bench) $(ab_post)
	@echo -e "\n====== Falcon(Python3.7) ======\n" | tee -a $(falcon_bench)
	@echo -e "\n====== GET ======\n" | tee -a $(falcon_bench)
	@$(AB) $(TEST_URL) | tee -a $(falcon_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench)
	@$(AB) -k $(TEST_URL) | tee -a $(falcon_bench)
	@echo -e "\n====== POST ======\n" | tee -a $(falcon_bench)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(falcon_bench)
	@killall -9 $(PYTHON) && sleep 2

_clean_bench:
	@rm -rf bjoern/bench/*37.txt

bjoern-bench: _clean_bench setup install-bench flask-ab bottle-ab falcon-ab flask-ab-gworker

flask-valgrind: install-debug
	valgrind --leak-check=full --show-reachable=yes $(PYTHON) bjoern/tests/test_flask.py > $(flask_valgrind) 2>&1

flask-callgrind: install-debug
	valgrind --tool=callgrind $(PYTHON) bjoern/tests/test_flask.py  > $(flask_callgrind) 2>&1

memwatch:
	watch -n 0.5 \
	  'cat /proc/$$(pgrep -n $(PYTHON))/cmdline | tr "\0" " " | head -c -1; \
	   echo; echo; \
	   tail -n +25 /proc/$$(pgrep -n $(PYTHON))smaps'