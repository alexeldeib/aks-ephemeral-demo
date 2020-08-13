#!/bin/bash
set -euo pipefail

i=0
while true; do
    echo "Running stress iteration: ${i}"
    cat "${JOBFILE}"
    time fio "${JOBFILE}"
    ((i=i+1))
done
