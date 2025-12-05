#!/usr/bin/env bash

MODEL="mistral"
BASE_DIR="$HOME/ai-lab"
PROMPT_DIR="$BASE_DIR/prompts"
LOG_DIR="$BASE_DIR/logs"

timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

mkdir -p "$LOG_DIR"

for prompt_file in "$PROMPT_DIR"/*.txt; do
  [ -e "$prompt_file" ] || continue

  base=$(basename "$prompt_file" .txt)
  out="$LOG_DIR/${base}_$(timestamp).log"

  echo "Running $base ..."
  echo "=== MODEL: $MODEL ==="        | tee "$out"
  echo "=== PROMPT: $prompt_file ===" | tee -a "$out"
  echo                                  | tee -a "$out"
  echo ">>> Prompt content:"           | tee -a "$out"
  cat "$prompt_file"                   | tee -a "$out"
  echo                                  | tee -a "$out"
  echo ">>> Model output:"             | tee -a "$out"
  echo                                  | tee -a "$out"

  ollama run "$MODEL" < "$prompt_file" | tee -a "$out"

  echo                                  | tee -a "$out"
  echo "=== END ==="                   | tee -a "$out"
  echo
done

