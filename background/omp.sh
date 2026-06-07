#!/bin/bash

if ! command -v omp >/dev/null; then
  echo "Installing oh-my-pi (omp)..."
  bun install -g @oh-my-pi/pi-coding-agent
fi
