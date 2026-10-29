#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-vpn.jerryberry.nl}"
API_PORT="${2:-60000}"
NAMESPACE="outline-system"
SECRET_NAME="tls-outline-vpn-imported"

if command -v microk8s >/dev/null 2>&1; then
  KUBECTL=(microk8s kubectl)
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL=(kubectl)
else
  echo "Install kubectl or make the microk8s command available on PATH." >&2
  exit 1
fi

API_PREFIX=$("${KUBECTL[@]}" -n "$NAMESPACE" get deployment outline-vpn \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="SB_API_PREFIX")].value}')

if [[ -z "$API_PREFIX" ]]; then
  echo "Could not read SB_API_PREFIX from the Outline deployment." >&2
  exit 1
fi

CERT_SHA256=$("${KUBECTL[@]}" -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.crt}' |
  openssl base64 -d -A |
  openssl x509 -noout -fingerprint -sha256 |
  awk -F= '{ gsub(":", "", $2); print $2 }')

if [[ -z "$CERT_SHA256" ]]; then
  echo "Could not calculate the fingerprint from Secret $SECRET_NAME." >&2
  exit 1
fi

cat <<EOF
{
  "apiUrl": "https://${DOMAIN}:${API_PORT}/${API_PREFIX}",
  "certSha256": "${CERT_SHA256}"
}
EOF
