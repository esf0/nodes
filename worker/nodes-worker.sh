#!/bin/bash
# nodes worker: runs the job scripts that appear in ~/jobs/queue, oldest first, one at a time.
# Installed by `nodes bootstrap` as a systemd user service (nodes-worker.service). Layout:
#   ~/jobs/queue/<id>.sh   waiting            ~/jobs/run/<id>.sh + <id>.pid   running
#   ~/jobs/log/<id>.log    stdout+stderr      ~/jobs/done/<id>.done            "<exit code> <seconds>", script moved here
J="$HOME/jobs"
mkdir -p "$J/queue" "$J/run" "$J/log" "$J/done"
echo "[$(date '+%F %T')] worker started on $(hostname)" >> "$J/worker.log"
while true; do
    job=$(ls -1 "$J/queue" 2>/dev/null | grep -v '^\.' | grep '\.sh$' | sort | head -1)
    if [ -z "$job" ]; then sleep 5; continue; fi
    id="${job%.sh}"
    mv "$J/queue/$job" "$J/run/$job" 2>/dev/null || continue
    start=$(date +%s)
    echo "[$(date '+%F %T')] start $id" >> "$J/worker.log"
    # own session and process group, so `nodes cancel` can kill the whole job tree without touching the worker
    setsid -w bash "$J/run/$job" > "$J/log/$id.log" 2>&1 < /dev/null &
    pid=$!
    echo "$pid" > "$J/run/$id.pid"
    wait "$pid"
    code=$?
    secs=$(( $(date +%s) - start ))
    echo "$code $secs" > "$J/done/$id.done"
    mv "$J/run/$job" "$J/done/$job"
    rm -f "$J/run/$id.pid"
    echo "[$(date '+%F %T')] end $id exit $code after ${secs}s" >> "$J/worker.log"
    sleep 5   # let a killed job's children release the GPU before the next job starts
done
