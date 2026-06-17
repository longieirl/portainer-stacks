#!/bin/bash
# Appends required env vars to ~/.zshrc and ~/.bashrc

VARS='
# portainer-stacks env vars
export DOCKER_DATA_HOME="${HOME}/Documents/docker/data"
export DOCKER_SHARED_HOME="${HOME}/Documents/docker/shared"
'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC" ]; then
    if grep -q "DOCKER_DATA_HOME" "$RC"; then
      echo "$RC already has DOCKER_DATA_HOME — skipping"
    else
      echo "$VARS" >> "$RC"
      echo "Appended to $RC"
    fi
  else
    echo "$RC not found — skipping"
  fi
done

echo "Done. Run: source ~/.zshrc"
