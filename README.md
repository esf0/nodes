# nodes

Run computations on your own PCs over Tailscale, from any project, with one command. The manual is in
`~/docs/nodes.md`; this file is the developer's view.

- `nodes` — the CLI (Python 3.11+, standard library only). Talks to nodes with `ssh`/`scp`/`rsync`; scripts go over
  stdin (`bash -s`) or scp, never inline in the SSH command line.
- `worker/nodes-worker.sh` — runs on each node as a systemd user service; executes `~/jobs/queue/*.sh` oldest first,
  one at a time, logs to `~/jobs/log/`, writes `~/jobs/done/<id>.done` with `<exit code> <seconds>`.
- `worker/nodes-worker.service` — the unit `nodes bootstrap` installs.
- `install.sh` — symlinks the CLI into `~/.local/bin` and creates `~/.config/nodes/nodes.toml` from the example.
- Scheduler (in the CLI): `nodes submit` puts a job with requirements (VRAM, RAM, datasets, optional pin, priority,
  outputs to pull) into the control queue `~/.local/share/nodes/jobs/*.json`; `nodes scheduler` (a user service on
  the control PC via `--install`) probes the nodes every 30 s, marks finished jobs and pulls their outputs, and places
  pending jobs on the node that fits, preferring the node that already holds the data, then the shortest queue, then
  the most free VRAM; it syncs the project and pushes missing datasets before dispatching through the node's worker.
  `nodes queue` shows everything; `nodes requeue` takes a job back from a lost node.

Conventions: projects live at `~/projects/<name>` everywhere; a project's environment is `uv sync` from its
`pyproject.toml`; jobs are plain bash scripts, so anything runs. One worker per node; a node with several GPUs
runs several jobs by giving each job its own `CUDA_VISIBLE_DEVICES` (not automated yet).

Operational note: the worker waits 5 s between jobs and `cancel` waits for the job's process group to exit, because a
cancelled GPU job can hold its memory for a few seconds and the next job then fails with an out-of-memory error.
Restart the worker service only when the node is idle: stopping the service kills the running job with it.
