# nodes

Run computations on your own PCs over Tailscale, from any project, with one command. The manual is in
`~/docs/nodes.md`; this file is the developer's view.

- `nodes` — the CLI (Python 3.11+, standard library only). Talks to nodes with `ssh`/`scp`/`rsync`; scripts go over
  stdin (`bash -s`) or scp, never inline in the SSH command line.
- `worker/nodes-worker.sh` — runs on each node as a systemd user service; executes `~/jobs/queue/*.sh` oldest first,
  one at a time, logs to `~/jobs/log/`, writes `~/jobs/done/<id>.done` with `<exit code> <seconds>`.
- `worker/nodes-worker.service` — the unit `nodes bootstrap` installs.
- `install.sh` — symlinks the CLI into `~/.local/bin` and creates `~/.config/nodes/nodes.toml` from the example.

Conventions: projects live at `~/projects/<name>` everywhere; a project's environment is `uv sync` from its
`pyproject.toml`; jobs are plain bash scripts, so anything runs. One worker per node; a node with several GPUs
runs several jobs by giving each job its own `CUDA_VISIBLE_DEVICES` (not automated yet).

Operational note: the worker waits 5 s between jobs and `cancel` waits for the job's process group to exit, because a
cancelled GPU job can hold its memory for a few seconds and the next job then fails with an out-of-memory error.
Restart the worker service only when the node is idle: stopping the service kills the running job with it.
