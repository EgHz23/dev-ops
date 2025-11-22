#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip git software-properties-common ansible
