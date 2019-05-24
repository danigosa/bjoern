# May 23 2019 (bjoern4.0.0a1)

## Bottle (0.12.16)
```
ab -c 100 -n 10000 "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        22 bytes

Concurrency Level:      100
Time taken for tests:   1.456 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1120000 bytes
HTML transferred:       220000 bytes
Requests per second:    6869.04 [#/sec] (mean)
Time per request:       14.558 [ms] (mean)
Time per request:       0.146 [ms] (mean, across all concurrent requests)
Transfer rate:          751.30 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       6
Processing:     4   14   1.1     14      16
Waiting:        4   14   1.2     14      16
Total:          5   14   0.9     14      16

Percentage of the requests served within a certain time (ms)
  50%     14
  66%     15
  75%     15
  80%     15
  90%     15
  95%     15
  98%     16
  99%     16
 100%     16 (longest request)
ab -c 100 -n 10000 -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        48 bytes

Concurrency Level:      100
Time taken for tests:   1.607 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1380000 bytes
Total body sent:        1820000
HTML transferred:       480000 bytes
Requests per second:    6224.05 [#/sec] (mean)
Time per request:       16.067 [ms] (mean)
Time per request:       0.161 [ms] (mean, across all concurrent requests)
Transfer rate:          838.79 [Kbytes/sec] received
                        1106.23 kb/s sent
                        1945.02 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       5
Processing:     0   16   2.1     16      20
Waiting:        0   16   2.1     16      20
Total:          0   16   2.0     16      20

Percentage of the requests served within a certain time (ms)
  50%     16
  66%     16
  75%     17
  80%     17
  90%     17
  95%     17
  98%     18
  99%     19
 100%     20 (longest request)
ab -c 100 -n 10000 -k "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        22 bytes

Concurrency Level:      100
Time taken for tests:   0.831 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      1170000 bytes
HTML transferred:       220000 bytes
Requests per second:    12039.34 [#/sec] (mean)
Time per request:       8.306 [ms] (mean)
Time per request:       0.083 [ms] (mean, across all concurrent requests)
Transfer rate:          1375.59 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       5
Processing:     5    8   0.4      8       9
Waiting:        4    8   0.4      8       9
Total:          7    8   0.5      8      13

Percentage of the requests served within a certain time (ms)
  50%      8
  66%      8
  75%      8
  80%      8
  90%      9
  95%      9
  98%      9
  99%      9
 100%     13 (longest request)
ab -c 100 -n 10000 -k -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        48 bytes

Concurrency Level:      100
Time taken for tests:   1.001 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      1430000 bytes
Total body sent:        2060000
HTML transferred:       480000 bytes
Requests per second:    9991.58 [#/sec] (mean)
Time per request:       10.008 [ms] (mean)
Time per request:       0.100 [ms] (mean, across all concurrent requests)
Transfer rate:          1395.31 [Kbytes/sec] received
                        2010.02 kb/s sent
                        3405.33 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.4      0       5
Processing:     3   10   0.4     10      11
Waiting:        3   10   0.4     10      11
Total:          8   10   0.5     10      15

Percentage of the requests served within a certain time (ms)
  50%     10
  66%     10
  75%     10
  80%     10
  90%     11
  95%     11
  98%     11
  99%     11
 100%     15 (longest request)
```

## Flask (1.0.3)

```
ab -c 100 -n 10000 "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        20 bytes

Concurrency Level:      100
Time taken for tests:   3.053 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1100000 bytes
HTML transferred:       200000 bytes
Requests per second:    3275.69 [#/sec] (mean)
Time per request:       30.528 [ms] (mean)
Time per request:       0.305 [ms] (mean, across all concurrent requests)
Transfer rate:          351.88 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.9      0      11
Processing:     2   30   2.0     30      36
Waiting:        1   30   2.1     30      36
Total:         12   30   1.6     30      36

Percentage of the requests served within a certain time (ms)
  50%     30
  66%     30
  75%     31
  80%     31
  90%     33
  95%     34
  98%     34
  99%     35
 100%     36 (longest request)
ab -c 100 -n 10000 -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        192 bytes

Concurrency Level:      100
Time taken for tests:   3.888 seconds
Complete requests:      10000
Failed requests:        0
Non-2xx responses:      10000
Total transferred:      2850000 bytes
Total body sent:        1820000
HTML transferred:       1920000 bytes
Requests per second:    2571.86 [#/sec] (mean)
Time per request:       38.882 [ms] (mean)
Time per request:       0.389 [ms] (mean, across all concurrent requests)
Transfer rate:          715.80 [Kbytes/sec] received
                        457.11 kb/s sent
                        1172.91 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.2      0       3
Processing:     4   39   2.6     38      46
Waiting:        4   39   2.6     38      46
Total:          4   39   2.6     38      46

Percentage of the requests served within a certain time (ms)
  50%     38
  66%     39
  75%     39
  80%     39
  90%     41
  95%     42
  98%     43
  99%     46
 100%     46 (longest request)
ab -c 100 -n 10000 -k "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        20 bytes

Concurrency Level:      100
Time taken for tests:   2.196 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      1150000 bytes
HTML transferred:       200000 bytes
Requests per second:    4553.29 [#/sec] (mean)
Time per request:       21.962 [ms] (mean)
Time per request:       0.220 [ms] (mean, across all concurrent requests)
Transfer rate:          511.36 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       5
Processing:    20   22   1.0     22      28
Waiting:       20   22   1.0     22      28
Total:         21   22   1.1     22      29

Percentage of the requests served within a certain time (ms)
  50%     22
  66%     22
  75%     22
  80%     22
  90%     23
  95%     24
  98%     27
  99%     28
 100%     29 (longest request)
ab -c 100 -n 10000 -k -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        192 bytes

Concurrency Level:      100
Time taken for tests:   3.065 seconds
Complete requests:      10000
Failed requests:        0
Non-2xx responses:      10000
Keep-Alive requests:    10000
Total transferred:      2900000 bytes
Total body sent:        2060000
HTML transferred:       1920000 bytes
Requests per second:    3262.84 [#/sec] (mean)
Time per request:       30.648 [ms] (mean)
Time per request:       0.306 [ms] (mean, across all concurrent requests)
Transfer rate:          924.05 [Kbytes/sec] received
                        656.39 kb/s sent
                        1580.44 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       4
Processing:    21   31   2.1     30      40
Waiting:       21   31   2.1     30      40
Total:         25   31   2.1     30      40

Percentage of the requests served within a certain time (ms)
  50%     30
  66%     30
  75%     31
  80%     31
  90%     32
  95%     37
  98%     38
  99%     39
 100%     40 (longest request)
```

## Falcon (2.0.0, Cython compiled)

```
ab -c 100 -n 10000 "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        22 bytes

Concurrency Level:      100
Time taken for tests:   0.879 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1120000 bytes
HTML transferred:       220000 bytes
Requests per second:    11373.56 [#/sec] (mean)
Time per request:       8.792 [ms] (mean)
Time per request:       0.088 [ms] (mean, across all concurrent requests)
Transfer rate:          1243.98 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       5
Processing:     1    9   1.1      9      14
Waiting:        1    9   1.1      9      14
Total:          4    9   0.9      9      14

Percentage of the requests served within a certain time (ms)
  50%      9
  66%      9
  75%      9
  80%      9
  90%     10
  95%     10
  98%     10
  99%     12
 100%     14 (longest request)
ab -c 100 -n 10000 -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        57 bytes

Concurrency Level:      100
Time taken for tests:   0.883 seconds
Complete requests:      10000
Failed requests:        0
Total transferred:      1470000 bytes
Total body sent:        1820000
HTML transferred:       570000 bytes
Requests per second:    11324.82 [#/sec] (mean)
Time per request:       8.830 [ms] (mean)
Time per request:       0.088 [ms] (mean, across all concurrent requests)
Transfer rate:          1625.73 [Kbytes/sec] received
                        2012.81 kb/s sent
                        3638.54 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   1.0      0      11
Processing:     1    8   1.4      9      17
Waiting:        1    8   1.5      8      17
Total:          3    9   1.4      9      19

Percentage of the requests served within a certain time (ms)
  50%      9
  66%      9
  75%      9
  80%      9
  90%     10
  95%     10
  98%     15
  99%     16
 100%     19 (longest request)
ab -c 100 -n 10000 -k "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        22 bytes

Concurrency Level:      100
Time taken for tests:   0.449 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      1170000 bytes
HTML transferred:       220000 bytes
Requests per second:    22249.27 [#/sec] (mean)
Time per request:       4.495 [ms] (mean)
Time per request:       0.045 [ms] (mean, across all concurrent requests)
Transfer rate:          2542.15 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.9      0      10
Processing:     1    4   0.8      4      10
Waiting:        1    4   0.8      4      10
Total:          1    4   1.3      4      17

Percentage of the requests served within a certain time (ms)
  50%      4
  66%      4
  75%      4
  80%      5
  90%      6
  95%      6
  98%      7
  99%     12
 100%     17 (longest request)
ab -c 100 -n 10000 -k -p /tmp/bjoern-post.tmp "http://127.0.0.1:8080/a/b/c?k=v&k2=v2"
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:
Server Hostname:        127.0.0.1
Server Port:            8080

Document Path:          /a/b/c?k=v&k2=v2
Document Length:        57 bytes

Concurrency Level:      100
Time taken for tests:   0.444 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      1520000 bytes
Total body sent:        2060000
HTML transferred:       570000 bytes
Requests per second:    22509.29 [#/sec] (mean)
Time per request:       4.443 [ms] (mean)
Time per request:       0.044 [ms] (mean, across all concurrent requests)
Transfer rate:          3341.22 [Kbytes/sec] received
                        4528.24 kb/s sent
                        7869.46 kb/s total

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       5
Processing:     1    4   0.3      4       5
Waiting:        1    4   0.3      4       5
Total:          3    4   0.4      4       9

Percentage of the requests served within a certain time (ms)
  50%      4
  66%      4
  75%      5
  80%      5
  90%      5
  95%      5
  98%      5
  99%      5
 100%      9 (longest request)
```