#!/bin/bash
set -euo pipefail

docker build -t bjoern .
docker run -it --rm -v $(pwd):/bjoern -w /bjoern bjoern bash

