# llm-ai-lab  
A lightweight, local-first lab for adversarial LLM testing, behavioral analysis, and reproducible red-team workflows.

This project provides:
- A structured directory for prompts, logs, scripts, and documentation  
- A minimal but powerful adversarial test suite  
- A simple harness for running tests against local models (via Ollama)  
- A foundation you can extend to multi-model or multi-agent evaluations  

The goal is to evaluate model behavior safely, consistently, and repeatedly across updates or model variants.

---

## Why this lab exists

Modern LLMs behave differently across versions, settings, and contexts.  
For security work, **repeatability** is everything.

This lab gives you:
- A controlled environment for running adversarial prompts  
- A consistent way to log and compare outputs  
- A structured approach for discovering guardrail failures  
- A portable test kit you can apply to any model or agent system  

It is deliberately simple — no heavy frameworks, no complex dependencies — so it can run on any laptop.

---

## Requirements

This project assumes:

- macOS or Linux (WSL also works)
- Bash or zsh
- A local model runtime, recommended:
  - **Ollama** → https://ollama.com  
- At least one model pulled locally (such as Mistral 7B)

---

## Setup Instructions (macOS Local Model)

### 1. Install Ollama
Download and install from:

https://ollama.com

After installation, verify:

```bash
ollama --version

```

Execution

Model tests are executed via run_tests.sh, which handles prompt iteration, logging, and output capture.

