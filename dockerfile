# Base
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System deps
# bc: allows the provisioning script to calculate MB/GB for the Orchestrator
# dos2unix: prevents "Command not found" or "Line ending" errors from Windows edits
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3.12-dev python3-pip python-is-python3 \
    git wget curl unzip ca-certificates nano less \
    bc dos2unix \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /data

# Recorder port
EXPOSE 8789

# Script root
WORKDIR /root/mww-scripts

# Bash environment
COPY --chown=root:root --chmod=0755 .bashrc /root/

# Root-level entrypoints
COPY --chown=root:root --chmod=0755 \
    train_wake_word \
    run_recorder.sh \
    recorder_server.py \
    requirements.txt \
    /root/mww-scripts/

# CLI folder
COPY --chown=root:root cli/ /root/mww-scripts/cli/

# Fix line endings and permissions across the entire CLI directory
RUN find /root/mww-scripts/cli -type f -print0 | xargs -0 dos2unix \
 && chmod -R a+x /root/mww-scripts/cli

# Static UI for recorder
COPY --chown=root:root --chmod=0644 static/index.html /root/mww-scripts/static/index.html

# recorder server
CMD ["/bin/bash", "-lc", "/root/mww-scripts/run_recorder.sh"]
