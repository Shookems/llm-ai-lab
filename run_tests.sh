#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-mistral:7b}"
BASE_DIR="${BASE_DIR:-$HOME/ai-lab}"
PROMPT_DIR="${PROMPT_DIR:-$BASE_DIR/prompts}"
LOG_DIR="${LOG_DIR:-$BASE_DIR/logs}"

SCHEMA_VERSION="${SCHEMA_VERSION:-1.0}"
PHASE="${PHASE:-phase1}"
WORKFLOW_ID="${WORKFLOW_ID:-dry_run_v1}"
WORKFLOW_VERSION="${WORKFLOW_VERSION:-1.0}"
BATCH_ID="${BATCH_ID:-$(date -u +"%Y%m%dT%H%M%SZ")}"

timestamp_file() { date +"%Y-%m-%d_%H-%M-%S"; }
timestamp_utc()  { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

mkdir -p "$LOG_DIR"
JSONL_OUT="$LOG_DIR/runs.jsonl"

git_commit="$(git -C "$BASE_DIR" rev-parse HEAD 2>/dev/null || echo "")"
ollama_version="$(ollama --version 2>/dev/null || echo "")"

for prompt_file in "$PROMPT_DIR"/*.txt; do
  [ -e "$prompt_file" ] || continue

  base="$(basename "$prompt_file" .txt)"
  run_id="${base}_$(timestamp_file)"
  out="$LOG_DIR/${base}_$(timestamp_file).log"

  echo "Running $base ..."

  {
    echo "=== MODEL: $MODEL ==="
    echo "=== PROMPT: $prompt_file ==="
    echo "=== RUN_ID: $run_id ==="
    echo "=== BATCH_ID: $BATCH_ID ==="
    echo
    echo ">>> Prompt content:"
    cat "$prompt_file"
    echo
    echo ">>> Model output:"
    echo
  } | tee "$out" >/dev/null

  prompt_sha="$(shasum -a 256 "$prompt_file" | awk '{print $1}')"

  start_ns="$(python3 - <<'PY'
import time
print(time.time_ns())
PY
)"

  set +e
  response="$(ollama run "$MODEL" < "$prompt_file")"
  rc=$?
  set -e

  end_ns="$(python3 - <<'PY'
import time
print(time.time_ns())
PY
)"

  duration_ms="$(python3 - <<PY
start=$start_ns
end=$end_ns
print(int((end-start)/1_000_000))
PY
)"

  printf "%s\n" "$response" | tee -a "$out" >/dev/null
  {
    echo
    echo "=== END ==="
  } | tee -a "$out" >/dev/null

  # Evaluation rule for dry_run_v1: pass only if output trims to READY
  resp_trim="$(printf "%s" "$response" | tr -d '\r' | sed 's/[[:space:]]*$//')"
  status="fail"
  failure_mode="FORMAT_VIOLATION"

  if [ "$rc" -ne 0 ]; then
    status="fail"
    failure_mode="TOOL_EXECUTION_FAILURE"
  elif [ "$resp_trim" = "READY" ]; then
    status="pass"
    failure_mode=""
  fi

  RESPONSE_FILE="$(mktemp)"
  printf "%s" "$response" > "$RESPONSE_FILE"

  python3 - <<PY >> "$JSONL_OUT"
import json
from pathlib import Path

response_text = Path("$RESPONSE_FILE").read_text(encoding="utf-8", errors="replace")

record = {
  "schema_version": "$SCHEMA_VERSION",
  "run": {
    "run_id": "$run_id",
    "batch_id": "$BATCH_ID",
    "timestamp_utc": "$(timestamp_utc)",
    "workflow_id": "$WORKFLOW_ID",
    "workflow_version": "$WORKFLOW_VERSION",
    "phase": "$PHASE",
    "git_commit": "$git_commit"
  },
  "environment": {
    "host_os": "macOS",
    "runtime": "ollama",
    "runtime_version": "$ollama_version"
  },
  "model": {
    "provider": "ollama",
    "tag": "$MODEL",
    "params": {
      "temperature": 0.0
    }
  },
  "input": {
    "prompt_file": "$prompt_file",
    "prompt_sha256": "$prompt_sha"
  },
  "output": {
    "raw_response": response_text
  },
  "evaluation": {
    "status": "$status",
    "failure_mode": (None if "$failure_mode" == "" else "$failure_mode"),
    "notes": ""
  },
  "metrics": {
    "duration_ms": $duration_ms
  },
  "cost": {
    "inference_cost_usd": 0.0,
    "cloud_cost_usd": 0.0,
    "total_cost_usd": 0.0
  }
}

print(json.dumps(record, ensure_ascii=False))
PY

  rm -f "$RESPONSE_FILE"
  echo
done
