AB			:= ab -c 100 -n 10000
TEST_URL	:= "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"

IMAGE_B64 						:= $(shell cat bjoern/tests/charlie.jpg | base64 | xargs urlencode)
IMAGE_B64_LEN 					:= $(shell cat bjoern/tests/charlie.jpg | base64 | xargs urlencode | wc -c)
flask_bench_36 					:= bjoern/bench/flask_py36.txt
flask_bench_pypy 				:= bjoern/bench/flask_pypy.txt
flask_gworker_bench_36 			:= bjoern/bench/flask_gworker_py36.txt
flask_gworker_bench_pypy 		:= bjoern/bench/flask_gworker_pypy.txt
flask_gunicorn_bench_36 		:= bjoern/bench/flask_gunicorn_py36.txt
flask_gworker_bench_thread_36 	:= bjoern/bench/flask_gworker_thread_py36.txt
flask_gworker_bench_multi_36 	:= bjoern/bench/flask_gworker_multi_py36.txt
bottle_bench_36 				:= bjoern/bench/bottle_py36.txt
bottle_bench_pypy 				:= bjoern/bench/bottle_pypy.txt
falcon_bench_36 				:= bjoern/bench/falcon_py36.txt
falcon_bench_pypy 				:= bjoern/bench/falcon_pypy.txt
flask_valgrind_36			 	:= bjoern/bench/flask_valgrind_py36.mem
flask_callgrind_36			 	:= bjoern/bench/flask_callgrind_py36.mem
flask_bench_37 					:= bjoern/bench/flask_py37.txt
bottle_bench_37 				:= bjoern/bench/bottle_py37.txt
falcon_bench_37 				:= bjoern/bench/falcon_py37.txt
flask_gunicorn_bench_37 		:= bjoern/bench/flask_gunicorn_py37.txt
flask_gworker_bench_37 			:= bjoern/bench/flask_gworker_py37.txt
flask_gworker_bench_thread_37 	:= bjoern/bench/flask_gworker_thread_py37.txt
flask_gworker_bench_multi_37 	:= bjoern/bench/flask_gworker_multi_py37.txt
flask_valgrind_37			 	:= bjoern/bench/flask_valgrind_py37.mem
flask_callgrind_37			 	:= bjoern/bench/flask_callgrind_py37.mem
ab_post 						:= /tmp/bjoern.post

# Benchmarks
$(ab_post):
	@echo 'asdfghjkl=asdfghjkl&qwerty=qwertyuiop&image=$(IMAGE_B64)' > "$@"
	@echo $(IMAGE_B64_LEN)

$(flask_bench_36):
	@$(PYTHON36) bjoern/bench/flask_bench.py --log-level inf & jobs -p >/var/run/flask_bjoern.bench.pid
	@sleep 2

flask-ab-36: $(flask_bench_36) $(ab_post)
	@echo -e "\n====== Flask(Python3.6) ======\n" | tee -a $(flask_bench_36)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_bench_36)
	@$(AB) $(TEST_URL) | tee -a $(flask_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_36)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_bench_36)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_bench_36)
	@killall -9 $(PYTHON36) && sleep 2

$(flask_bench_pypy):
	@$(PYPY36) bjoern/bench/flask_bench.py --log-level inf & jobs -p >/var/run/flask_bjoern.bench.pid
	@sleep 2

flask-ab-pypy: $(flask_bench_pypy) $(ab_post)
	@echo -e "\n====== Flask(PyPy3.6) ======\n" | tee -a $(flask_bench_pypy)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_bench_pypy)
	@$(AB) $(TEST_URL) # warmup
	@$(AB) $(TEST_URL) | tee -a $(flask_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_pypy)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_bench_pypy)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_pypy)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) # warmup
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_bench_pypy)
	@killall -9 $(PYPY36) && sleep 2

$(flask_gworker_bench_multi_36):
	@$(GUNICORN36) bjoern.bench.flask_bench:app --bind localhost:8080 --log-level info -w 4 --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker-multi-36: $(flask_gworker_bench_multi_36) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker-multiworkers (Python3.6) ======\n" | tee -a $(flask_gworker_bench_multi_36)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench_multi_36)
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench_multi_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_multi_36)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench_multi_36)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench_multi_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_multi_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench_multi_36)
	@killall -9 gunicorn && sleep 2

$(flask_gworker_bench_36):
	@$(GUNICORN36) bjoern.bench.flask_bench:app --bind localhost:8080 --log-level info --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker-36: $(flask_gworker_bench_36) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker(Python3.6) ======\n" | tee -a $(flask_gworker_bench_36)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench_36)
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_36)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench_36)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench_36)
	@killall -9 gunicorn && sleep 2

$(flask_gworker_bench_pypy):
	@$(GUNICORNPYPY) bjoern.bench.flask_bench:app --bind localhost:8080 --log-level info --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker-pypy: $(flask_gworker_bench_pypy) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker(Python3.6) ======\n" | tee -a $(flask_gworker_bench_pypy)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench_pypy)
	@$(AB) $(TEST_URL) # warmup
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_pypy)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench_pypy)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_pypy)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) # warmup
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench_pypy)
	@killall -9 gunicorn && sleep 2

$(flask_gunicorn_bench_pypy):
	@$(GUNICORN36) bjoern.bench.flask_bench:app --bind localhost:8080 --log-level info --backlog 2048 --timeout 1800 &
	@sleep 2

flask-ab-gunicorn-36: $(flask_gunicorn_bench_36) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn(Python3.6) ======\n" | tee -a $(flask_gunicorn_bench_36)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gunicorn_bench_36)
	@$(AB) $(TEST_URL) | tee -a $(flask_gunicorn_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gunicorn_bench_36)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gunicorn_bench_36)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gunicorn_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gunicorn_bench_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gunicorn_bench_36)
	@killall -9 gunicorn && sleep 2

$(bottle_bench_36):
	@$(PYTHON36) bjoern/bench/bottle_bench.py &
	@sleep 2

bottle-ab-36: $(bottle_bench_36) $(ab_post)
	@echo -e "\n====== Bottle(Python3.6) ======\n" | tee -a $(bottle_bench_36)
	@echo -e "\n====== GET ======\n" | tee -a $(bottle_bench_36)
	@$(AB) $(TEST_URL) | tee -a $(bottle_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_36)
	@$(AB) -k $(TEST_URL) | tee -a $(bottle_bench_36)
	@echo -e "\n====== POST ======\n" | tee -a $(bottle_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(bottle_bench_36)
	@killall -9 $(PYTHON36) && sleep 2

$(bottle_bench_pypy):
	@$(PYPY36) bjoern/bench/bottle_bench.py &
	@sleep 2

bottle-ab-pypy: $(bottle_bench_pypy) $(ab_post)
	@echo -e "\n====== Bottle(Python3.6) ======\n" | tee -a $(bottle_bench_pypy)
	@echo -e "\n====== GET ======\n" | tee -a $(bottle_bench_pypy)
	@$(AB) $(TEST_URL) # warmup
	@$(AB) $(TEST_URL) | tee -a $(bottle_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_pypy)
	@$(AB) -k $(TEST_URL) | tee -a $(bottle_bench_pypy)
	@echo -e "\n====== POST ======\n" | tee -a $(bottle_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_pypy)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) # warmup
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(bottle_bench_pypy)
	@killall -9 $(PYPY36) && sleep 2

$(falcon_bench_36):
	@$(PYTHON36) bjoern/bench/falcon_bench.py &
	@sleep 2

falcon-ab-36: $(falcon_bench_36) $(ab_post)
	@echo -e "\n====== Falcon(Python3.6) ======\n" | tee -a $(falcon_bench_36)
	@echo -e "\n====== GET ======\n" | tee -a $(falcon_bench_36)
	@$(AB) $(TEST_URL) | tee -a $(falcon_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_36)
	@$(AB) -k $(TEST_URL) | tee -a $(falcon_bench_36)
	@echo -e "\n====== POST ======\n" | tee -a $(falcon_bench_36)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_36)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(falcon_bench_36)
	@killall -9 $(PYTHON36) && sleep 2

$(falcon_bench_pypy):
	@$(PYPY36) bjoern/bench/falcon_bench.py &
	@sleep 2

falcon-ab-pypy: $(falcon_bench_pypy) $(ab_post)
	@echo -e "\n====== Falcon(Python3.6) ======\n" | tee -a $(falcon_bench_pypy)
	@echo -e "\n====== GET ======\n" | tee -a $(falcon_bench_pypy)
	@$(AB) $(TEST_URL) # warmup
	@$(AB) $(TEST_URL) | tee -a $(falcon_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_pypy)
	@$(AB) -k $(TEST_URL) | tee -a $(falcon_bench_pypy)
	@echo -e "\n====== POST ======\n" | tee -a $(falcon_bench_pypy)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_pypy)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) # warmup
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(falcon_bench_pypy)
	@killall -9 $(PYPY36) && sleep 2

_clean_bench_36:
	@rm -rf bjoern/bench/*36.txt

_clean_bench_pypy:
	@rm -rf bjoern/bench/*pypy.txt

bjoern-bench-36: _clean_bench_36 setup-36 install-36-bench flask-ab-36 bottle-ab-36 falcon-ab-36 flask-ab-gunicorn-36 flask-ab-gworker-36 flask-ab-gworker-multi-36
bjoern-bench-pypy: _clean_bench_pypy setup-pypy install-pypy-bench bottle-ab-pypy falcon-ab-pypy flask-ab-pypy flask-ab-gworker-pypy


$(flask_bench_37):
	@$(PYTHON37) bjoern/bench/flask_bench.py & jobs -p >/var/run/flask_bjoern.bench.pid
	@sleep 2

flask-ab-37: $(flask_bench_37) $(ab_post)
	@echo -e "\n====== Flask(Python3.7) ======\n" | tee -a $(flask_bench_37)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_bench_37)
	@$(AB) $(TEST_URL) | tee -a $(flask_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_37)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_bench_37)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_bench_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_bench_37)
	@killall -9 $(PYTHON37) && sleep 2

$(flask_gworker_bench_multi_37):
	@$(GUNICORN37) bjoern.bench.flask_bench:app --bind localhost:8080 --log-level info -w 4 --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker-multi-37: $(flask_gworker_bench_multi_37) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker-multiworkers (Python3.7) ======\n" | tee -a $(flask_gworker_bench_multi_37)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench_multi_37)
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench_multi_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_multi_37)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench_multi_37)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench_multi_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_multi_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench_multi_37)
	@killall -9 gunicorn && sleep 2

$(flask_gworker_bench_37):
	@$(GUNICORN37) bjoern.bench.flask_bench:app --backlog 2048 --timeout 1800 --worker-class bjoern.gworker.BjoernWorker &
	@sleep 2

flask-ab-gworker-37: $(flask_gworker_bench_37) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn-BjoernWorker(Python3.7) ======\n" | tee -a $(flask_gworker_bench_37)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gworker_bench_37)
	@$(AB) $(TEST_URL) | tee -a $(flask_gworker_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_37)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gworker_bench_37)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gworker_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gworker_bench_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gworker_bench_37)
	@killall -9 gunicorn && sleep 2

$(flask_gunicorn_bench_37):
	@$(GUNICORN37) bjoern.bench.flask_bench:app --backlog 2048 --timeout 1800 &
	@sleep 2

flask-ab-gunicorn-37: $(flask_gunicorn_bench_37) $(ab_post)
	@echo -e "\n====== Flask-Gunicorn(Python3.7) ======\n" | tee -a $(flask_gunicorn_bench_37)
	@echo -e "\n====== GET ======\n" | tee -a $(flask_gunicorn_bench_37)
	@$(AB) $(TEST_URL) | tee -a $(flask_gunicorn_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gunicorn_bench_37)
	@$(AB) -k $(TEST_URL) | tee -a $(flask_gunicorn_bench_37)
	@echo -e "\n====== POST ======\n" | tee -a $(flask_gunicorn_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(flask_gunicorn_bench_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(flask_gunicorn_bench_37)
	@killall -9 gunicorn && sleep 2

$(bottle_bench_37):
	@$(PYTHON37) bjoern/bench/bottle_bench.py & jobs -p >/var/run/bottle_bjoern.bench.pid
	@sleep 2

bottle-ab-37: $(bottle_bench_37) $(ab_post)
	@echo -e "\n====== Falcon(Python3.7) ======\n" | tee -a $(bottle_bench_37)
	@echo -e "\n====== GET ======\n" | tee -a $(bottle_bench_37)
	@$(AB) $(TEST_URL) | tee -a $(bottle_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_37)
	@$(AB) -k $(TEST_URL) | tee -a $(bottle_bench_37)
	@echo -e "\n====== POST ======\n" | tee -a $(bottle_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(bottle_bench_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(bottle_bench_37)
	@killall -9 $(PYTHON37) && sleep 2

$(falcon_bench_37):
	@$(PYTHON37) bjoern/bench/falcon_bench.py & jobs -p >/var/run/falcon_bjoern.bench.pid
	@sleep 2

falcon-ab-37: $(falcon_bench_37) $(ab_post)
	@echo -e "\n====== Falcon(Python3.7) ======\n" | tee -a $(falcon_bench_37)
	@echo -e "\n====== GET ======\n" | tee -a $(falcon_bench_37)
	@$(AB) $(TEST_URL) | tee -a $(falcon_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_37)
	@$(AB) -k $(TEST_URL) | tee -a $(falcon_bench_37)
	@echo -e "\n====== POST ======\n" | tee -a $(falcon_bench_37)
	@echo -e "\n~~~~~ Keep Alive ~~~~~\n" | tee -a $(falcon_bench_37)
	$(AB) -T 'application/x-www-form-urlencoded' -T 'Expect: 100-continue' -k -p $(ab_post) $(TEST_URL) | tee -a $(falcon_bench_37)
	@killall -9 $(PYTHON37) && sleep 2

_clean_bench_37:
	@rm -rf bjoern/bench/*37.txt

bjoern-bench-37: _clean_bench_37 setup-37 install-37-bench flask-ab-gunicorn-37 flask-ab-37 bottle-ab-37 falcon-ab-37 flask-ab-gworker-37 flask-ab-gworker-multi-37
bjoern-bench: bjoern-bench-37 bjoern-bench-36

# Memory checks
flask-valgrind-36: install-debug-36
	valgrind --leak-check=full --show-reachable=yes $(PYTHON36) bjoern/tests/test_flask.py > $(flask_valgrind_36) 2>&1

flask-callgrind-36: install-debug-36
	valgrind --tool=callgrind $(PYTHON36) bjoern/tests/test_flask.py > $(flask_callgrind_36) 2>&1

memwatch-36:
	watch -n 0.5 \
	  'cat /proc/$$(pgrep -n $(PYTHON36))/cmdline | tr "\0" " " | head -c -1; \
	   echo; echo; \
	   tail -n +25 /proc/$$(pgrep -n $(PYTHON36))smaps'

flask-valgrind-37: install-debug-37
	valgrind --leak-check=full --show-reachable=yes $(PYTHON37) bjoern/tests/test_flask.py > $(flask_valgrind_37) 2>&1

flask-callgrind-37: install-debug-37
	valgrind --tool=callgrind $(PYTHON37) bjoern/tests/test_flask.py  > $(flask_callgrind_37) 2>&1

memwatch-37:
	watch -n 0.5 \
	  'cat /proc/$$(pgrep -n $(PYTHON37))/cmdline | tr "\0" " " | head -c -1; \
	   echo; echo; \
	   tail -n +25 /proc/$$(pgrep -n $(PYTHON37))smaps'

valgrind: flask-valgrind-36 flask-callgrind-36 flask-valgrind-37 flask-callgrind-37

