#!/bin/bash
# mimi_auto_gate.sh <ssh_host> <ssh_port> <run_id>
# Polls the box's python proc. When it dies, scp's .best.pt + .best.card.json
# down, runs mimi-eval + mimi-gate, and tees the verdict to /tmp.
set -u
HOST="$1"; PORT="$2"; RID="$3"
LOG=/tmp/mimi_auto_${RID}.log
exec > >(tee -a "$LOG") 2>&1
echo "$(date) watching $RID on $HOST:$PORT"
while ssh -o StrictHostKeyChecking=no -p "$PORT" root@"$HOST" "pgrep -f 'python.*train.*$RID' >/dev/null"; do sleep 180; done
echo "$(date) $RID python proc gone. fetching artefacts."
CKPT_DIR=/Users/cole/Dev/mimikyu/data/checkpoints
scp -P "$PORT" "root@${HOST}:/workspace/mimikyu/data/checkpoints/${RID}.best.pt" "$CKPT_DIR/" 2>&1 | tail -2
scp -P "$PORT" "root@${HOST}:/workspace/mimikyu/data/checkpoints/${RID}.best.card.json" "$CKPT_DIR/" 2>&1 | tail -2
scp -P "$PORT" "root@${HOST}:/workspace/mimikyu/data/checkpoints/${RID}.jsonl" "$CKPT_DIR/" 2>&1 | tail -2
echo "$(date) running mimi-eval"
( source ~/dotfiles/zsh/macos/local.zsh && mimi-eval "$RID" ) 2>&1 | tail -20
echo "$(date) running mimi-gate vs marmoset"
( source ~/dotfiles/zsh/macos/local.zsh && mimi-gate "$RID" ) 2>&1 | tail -30
echo "$(date) DONE. full log at $LOG"
