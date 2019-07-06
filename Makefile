SHELL=/bin/bash

.PHONY: default setup test all again clean
default: test

SOURCE_DIR	:= src
BUILD_DIR	:= build
PYTHON35	:= /.py35-venv/bin/python3
PIP35		:= /.py35-venv/bin/pip3
PYTHON36	:= /.py36-venv/bin/python3
PIP36		:= /.py36-venv/bin/pip3
GUNICORN36	:= /.py36-venv/bin/gunicorn
GUNICORNPYPY:= /.pypy36-venv/bin/gunicorn
GUNICORN37	:= /.py37-venv/bin/gunicorn
PYTHON37	:= /.py37-venv/bin/python3
PIP37		:= /.py37-venv/bin/pip3
PYPY36		:= /.pypy36-venv/bin/pypy3
PIPY36		:= /.pypy36-venv/bin/pip3
DEBUG 		:= DEBUG=True

PYTHON35_INCLUDE	:= $(shell python3-config --includes | sed s/-I/-isystem\ /g)
PYTHON35_LDFLAGS	:= $(shell python3-config --ldflags)
PYTHON36_INCLUDE	:= $(shell python3-config --includes | sed s/-I/-isystem\ /g)
PYTHON36_LDFLAGS	:= $(shell python3-config --ldflags)
PYTHON37_INCLUDE	:= $(shell python3.7-config --includes | sed s/-I/-isystem\ /g)
PYTHON37_LDFLAGS	:= $(shell python3.7-config --ldflags)


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

PYPY36_INSTALL  := /opt/pypy3.6-7.1.1-beta-linux_x86_64-portable
CC 				:= gcc
CPPFLAGS_35		+= $(PYTHON35_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CPPFLAGS_36		+= $(PYTHON36_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CPPFLAGS_37		+= $(PYTHON37_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CPPFLAGS_PYPY	+= -isystem $(PYPY36_INSTALL)/include -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CFLAGS			+= $(FEATURES) -std=c11 -fno-strict-aliasing -fcommon -fPIC -Wall -D DEBUG
LDFLAGS_36		+= $(PYTHON36_LDFLAGS) -shared -fcommon
LDFLAGS_37		+= $(PYTHON37_LDFLAGS) -shared -fcommon
LDFLAGS_PYPY	+= -L$(PYPY36_INSTALL)/lib -L/usr/lib -L$(PYPY36_INSTALL)/lib_pypy -lpython3.6m -lpthread -ldl -lutil -lm  -Xlinker -export-dynamic -Wl,-O1 -Wl,-Bsymbolic-functions -shared -fcommon

# Targets
setup-35: clean prepare-build reqs-35
setup-36: clean prepare-build reqs-36
setup-37: clean prepare-build reqs-37
setup-pypy: clean prepare-build reqs-pypy

all-35: print-env setup-35 $(objects) _bjoernmodule_35 test-35
all-36: setup-36 $(objects) _bjoernmodule_36 test-36
all-37: setup-36 $(objects) _bjoernmodule_37 test-37
all-pypy: setup-pypy $(objects) _bjoernmodule_pypy test-pypy

print-env:
	@echo CFLAGS=$(CFLAGS)
	@echo CPPFLAGS_36=$(CPPFLAGS_36)
	@echo LDFLAGS_36=$(LDFLAGS_36)
	@echo CPPFLAGS_37=$(CPPFLAGS_37)
	@echo LDFLAGS_37=$(LDFLAGS_37)
	@echo CPPFLAGS_PYPY=$(CPPFLAGS_PYPY)
	@echo LDFLAGS_PYPY=$(LDFLAGS_PYPY)
	@echo args=$(HTTP_PARSER_SRC) $(wildcard $(SOURCE_DIR)/*.c)
	@echo FEATURES=$(FEATURES)

_bjoernmodule_35:
	@$(CC) $(CPPFLAGS_35) $(CFLAGS) $(LDFLAGS_35) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON35) -c 'import bjoern;print("Bjoern version: {}".format(bjoern.__version__));'

_bjoernmodule_36:
	@$(CC) $(CPPFLAGS_36) $(CFLAGS) $(LDFLAGS_36) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

_bjoernmodule_37:
	@$(CC) $(CPPFLAGS_37) $(CFLAGS) $(LDFLAGS_37) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

_bjoernmodule_pypy:
	$(CC) $(CPPFLAGS_PYPY) $(CFLAGS) $(LDFLAGS_PYPY) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYPY36) -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

again-36: print-env all-36
again-37: print-env all-37
again-pypy: print-env all-pypy

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c
	@echo ' -> ' $(CC) $(CPPFLAGS_36) $(CFLAGS) -c $< -o $@
	@$(CC) $(CPPFLAGS_36) $(CFLAGS) -c $< -o $@

# foo.o: shortcut to $(BUILD_DIR)/foo.o
%.o: $(BUILD_DIR)/%.o

reqs-35:
	@bash install-requirements $(PIP35)

reqs-36:
	@bash install-requirements $(PIP36)

reqs-37:
	@bash install-requirements $(PIP37)

reqs-pypy:
	@bash install-requirements $(PIPY36)

fmt:
	@$(PYTHON36) -m isort --settings-path=/.isort.cfg **/*.py
	@$(PYTHON36) -m black .

prepare-build:
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)/*
	@rm -rf _bjoern.*.so
	@rm -rf *.egg-info
	@rm -rf dist/*
	@rm -f /tmp/*.tmp

# Test
test-35: clean reqs-35 install-debug-35
	@$(PYTHON35) -m pytest

# Test
test-36: clean reqs-36 install-debug-36
	@$(PYTHON36) -m pytest

test-37: clean reqs-37 install-debug-37
	@$(PYTHON37) -m pytest

test-pypy: fmt clean reqs-pypy install-debug-pypy
	@$(PYPY36) -m pytest

test: test-37 test-36

# Pypi
extension-36:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) setup.py build_ext

extension-pypy:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYPY36) setup.py build_ext

extension-37:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) setup.py build_ext

install-debug-35:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON35) -m pip install --editable .

install-debug-36:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) -m pip install --editable .

install-debug-pypy:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYPY36) -m pip install --editable .

uninstall-36: clean
	@DEBUG=False PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) -m pip uninstall -y bjoern

uninstall-pypy: clean
	@DEBUG=False PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYPY36) -m pip uninstall -y bjoern

install-36:
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) -m pip install --editable .

install-36-bench: uninstall-36 extension-36
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON36) setup.py install

install-pypy-bench: uninstall-pypy extension-pypy
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYPY36) setup.py install

install-legacy-bench-36: uninstall-36
	@$(PIP36) install --upgrade --index-url=https://pypi.org/simple bjoern

install-legacy-bench-37: uninstall-37
	@$(PIP37) install --upgrade --index-url=https://pypi.org/simple bjoern

upload-36:
	$(PYTHON36) setup.py sdist
	$(PYTHON36) -m twine upload --repository=robbie-pypi dist/*.tar.gz

wheel-36:
	$(PYTHON36) setup.py bdist_wheel

install-debug-37:
	@DEBUG=True PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) -m pip install --editable .

uninstall-37: clean
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) -m pip uninstall -y bjoern

install-37:
	@DEBUG=False @PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) -m pip install --editable .

install-37-bench: uninstall-37 extension-37
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(PYTHON37) setup.py install

upload-37:
	$(PYTHON36) setup.py sdist
	$(PYTHON36) -m twine upload --repository=robbie-pypi dist/*.tar.gz

wheel-37:
	$(PYTHON37) setup.py bdist_wheel

upload-wheel-36: wheel-36
	@$(PYTHON36) -m twine upload --skip-existing dist/*.whl

upload-wheel-37: wheel-37
	@$(PYHHON37) -m twine upload --skip-existing dist/*.whl

# Vendors
http-parser:
	# http-parser 2.9.2
	@cd $(HTTP_PARSER_DIR) && git checkout 5c17dad400e45c5a442a63f250fff2638d144682

$(HTTP_PARSER_OBJ): http-parser
	$(MAKE) -C $(HTTP_PARSER_DIR) http_parser.o url_parser CFLAGS_DEBUG_EXTRA=-fPIC CFLAGS_FAST_EXTRA="-pthread -fPIC -march='core-avx2' -mtune='core-avx2'"

# Benchmarks
include benchmarks.mk
