#!/bin/bash

set -euo pipefail

WORKDIR="$1"
ROOTDIR="$2"
IMAGE="$3"

OUTPUT_DIR="${WORKDIR}/build/debos"
BASE="${IMAGE%.img}"
KEY_FILE="${OUTPUT_DIR}/root.key"
PASS_FILE="${OUTPUT_DIR}/root.password"

mkdir -p "${OUTPUT_DIR}"

if [[ -f "${KEY_FILE}" ]] && [[ -f "${PASS_FILE}" ]]; then
    echo "Root credentials already exist, reusing: ${PASS_FILE}"
    PASSWORD=$(awk '/^password:/ {print $2}' "${PASS_FILE}")
else
    PASSWORD=$(python3 -c "import secrets,string; a=string.ascii_letters+string.digits; print(''.join(secrets.choice(a) for _ in range(6)),end='')")

    rm -f "${KEY_FILE}" "${KEY_FILE}.pub"
    ssh-keygen -t ed25519 -f "${KEY_FILE}" -N "" -C "root@gemstone-tablet" -q

    chmod 600 "${KEY_FILE}"
    printf "image:    %s\npassword: %s\nkey:      %s\n" "$IMAGE" "$PASSWORD" "${KEY_FILE}" > "${PASS_FILE}"
    chmod 600 "${PASS_FILE}"

    echo "Root password: ${PASSWORD}"
    echo "Private key  : ${KEY_FILE}"
    echo "Credentials  : ${PASS_FILE}"
fi

# Her derlemede yeni imaja public key ve sifre hash'i yukle
install -d -m 700 -o 0 -g 0 "${ROOTDIR}/root/.ssh"
install -m 600 -o 0 -g 0 "${KEY_FILE}.pub" "${ROOTDIR}/root/.ssh/authorized_keys"

HASH=$(openssl passwd -6 "$PASSWORD")
python3 -c "
import sys, re
hash_val, shadow = sys.argv[1], sys.argv[2]
with open(shadow) as f:
    data = f.read()
data = re.sub(r'(?m)^(root:)[^:]*(:)', lambda m: m.group(1) + hash_val + m.group(2), data)
with open(shadow, 'w') as f:
    f.write(data)
" "$HASH" "${ROOTDIR}/etc/shadow"
