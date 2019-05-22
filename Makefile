SOURCE_DIR	= bjoern
BUILD_DIR	= build
PYTHON	= python3
PY36	= py36
DEBUG = DEBUG=True

PYTHON_INCLUDE	= $(shell ${PYTHON}-config --includes | sed s/-I/-isystem\ /g)
PYTHON_LDFLAGS	= $(shell ${PYTHON}-config --ldflags)

HTTP_PARSER_DIR	= http-parser
HTTP_PARSER_OBJ = $(HTTP_PARSER_DIR)/http_parser.o
HTTP_PARSER_SRC = $(HTTP_PARSER_DIR)/http_parser.c

HTTP_PARSER_URL_DIR	= http-parser/contrib
HTTP_PARSER_URL_OBJ = $(HTTP_PARSER_URL_DIR)/url_parser

objects		= 	$(HTTP_PARSER_OBJ) $(HTTP_PARSER_URL_OBJ) \
		  		$(patsubst $(SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, \
		             $(wildcard $(SOURCE_DIR)/*.c))
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
CC 			= gcc
CPPFLAGS	+= $(PYTHON_INCLUDE) -I . -I $(SOURCE_DIR) -I $(HTTP_PARSER_DIR)
CFLAGS		+= $(FEATURES) -std=c99 -fno-strict-aliasing -fcommon -fPIC -Wall -g
LDFLAGS		+= $(PYTHON_LDFLAGS) -pthread -shared -fcommon


all: prepare-build $(objects) _bjoernmodule

print-env:
	@echo CFLAGS=$(CFLAGS)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo args=$(HTTP_PARSER_SRC) $(wildcard $(SOURCE_DIR)/*.c)
	@echo FEATURES=$(FEATURES)

opt: clean
	CFLAGS='-O3' make

small: clean
	CFLAGS='-Os -s' make

fast: clean
	CFLAGS='-Os -s -O3 -march=core-avx2 -mtune=core-avx2' make

_bjoernmodule:
	@$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(objects) -o $(BUILD_DIR)/_bjoern.so -lev
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON} -c 'import bjoern;print(f"Bjoern version: {bjoern.__version__}");'

again: clean all

debug:
	CFLAGS='-D DEBUG -g' make again

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c
	@echo ' -> ' $(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# foo.o: shortcut to $(BUILD_DIR)/foo.o
%.o: $(BUILD_DIR)/%.o

reqs: requirements.txt
	pip3 install -r requirements.txt --quiet

fmt:
	@isort --settings-path=/.isort.cfg **/*.py
	@black -t $(PY36) .

prepare-build: reqs fmt
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)/*

AB		= ab -c 100 -n 10000
TEST_URL	= "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"

flask_bench:
	@$(PYTHON) flask_bench.py &
	@export LAST_BENCH="$!"
	@sleep 5

flask_ab: fast flask_bench ab1
	@kill ${LAST_BENCH}

ab1:
	$(AB) $(TEST_URL)
ab2:
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop' > /tmp/bjoern-post.tmp
	$(AB) -p /tmp/bjoern-post.tmp $(TEST_URL)
ab3:
	$(AB) -k $(TEST_URL)
ab4:
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop' > /tmp/bjoern-post.tmp
	$(AB) -k -p /tmp/bjoern-post.tmp $(TEST_URL)

wget:
	wget -O - -q -S $(TEST_URL)

valgrind:
	valgrind --leak-check=full --show-reachable=yes ${PYTHON} tests/empty.py

callgrind:
	valgrind --tool=callgrind ${PYTHON} tests/wsgitest-round-robin.py

memwatch:
	watch -n 0.5 \
	  'cat /proc/$$(pgrep -n ${PYTHON})/cmdline | tr "\0" " " | head -c -1; \
	   echo; echo; \
	   tail -n +25 /proc/$$(pgrep -n ${PYTHON})/smaps'

uninstall:
	@pip3 uninstall -y bjoern || { echo "Not installed."; }

install: uninstall
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(DEBUG) ${PYTHON} setup.py build_ext
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) $(DEBUG) ${PYTHON} setup.py install

install_real: uninstall
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON} setup.py build_ext
	@PYTHONPATH=$$PYTHONPATH:$(BUILD_DIR) ${PYTHON} setup.py install

test: reqs fmt install_real
	pytest

upload:
	${PYTHON} setup.py sdist upload

wheel:
	${PYTHON} setup.py bdist_wheel

upload-wheel: wheel
	twine upload

libev:
	# http-parser 2.9.2
	@git submodule update --init --recursive
	@cd $(HTTP_PARSER_DIR) && git checkout 5c17dad400e45c5a442a63f250fff2638d144682

$(HTTP_PARSER_OBJ): libev
	$(MAKE) -C $(HTTP_PARSER_DIR) http_parser.o url_parser CFLAGS_DEBUG_EXTRA=-fPIC CFLAGS_FAST_EXTRA="-pthread -fPIC -march='core-avx2' -mtune='core-avx2'"