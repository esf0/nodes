#!/bin/sh
# Install the `nodes` command on a control PC: symlink into ~/.local/bin and create the inventory if missing.
set -e
D=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.local/bin ~/.config/nodes
chmod +x "$D/nodes" "$D/worker/nodes-worker.sh"
ln -sf "$D/nodes" ~/.local/bin/nodes
[ -f ~/.config/nodes/nodes.toml ] || cp "$D/nodes.toml.example" ~/.config/nodes/nodes.toml
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "add ~/.local/bin to your PATH";; esac
echo "installed: $(command -v nodes || echo ~/.local/bin/nodes); inventory: ~/.config/nodes/nodes.toml"
