#!/bin/bash

set -euo pipefail

curl -fsSL https://repo.mobian-project.org/mobian.gpg -o /usr/share/keyrings/mobian-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/mobian-archive-keyring.gpg] https://repo.mobian-project.org trixie main" > /etc/apt/sources.list.d/mobian.list

apt-get update -y -qq
