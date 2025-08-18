#!/usr/bin/env bash
set -euo pipefail
set -ex

# 1. Parameters -----------------------------------------------------------
DOMAIN="${1:-vpn.jerryberry.nl}"
NAMESPACE="${2:-outline-system}"
SEALED_SECRET_NAME="tls-outline-vpn-imported"
REPO_ROOT="$(git rev-parse --show-toplevel)"
SEALED_SECRET_PATH="${REPO_ROOT}/argo-app/outline-vpn/${SEALED_SECRET_NAME}.yaml"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo REPO_ROOT: "$REPO_ROOT"

# 2. Clean temp area ------------------------------------------------------
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT
cd "$TMP"

# 3. Generate fresh cert --------------------------------------------------
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout tls.key -out tls.crt -days 365 \
  -subj "/CN=${DOMAIN}"

# 4. Create raw K8s Secret ------------------------------------------------
kubectl create secret tls "$SEALED_SECRET_NAME" \
  --cert=tls.crt --key=tls.key \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml > secret.yaml

# 5. Seal it --------------------------------------------------------------
kubeseal --format yaml < secret.yaml > "$SEALED_SECRET_PATH"

# 6. Commit & push --------------------------------------------------------
cd $REPO_ROOT
git add "$SEALED_SECRET_PATH"
git commit -m "chore: renew Outline VPN cert for ${DOMAIN}"
git push origin "$(git branch --show-current)"
cd "$TMP"

# 7. Wait for rollout -----------------------------------------------------
echo "Waiting for Argo CD sync & pod restart …"
kubectl -n "$NAMESPACE" rollout status deployment outline-vpn --timeout=120s

# 8. Compute fingerprint --------------------------------------------------
SHA256=$(openssl x509 -in tls.crt -noout -fingerprint -sha256 | \
         sed 's/://g' | cut -d= -f2)

# 9. Output Outline Manager JSON ------------------------------------------
cat <<EOF

----------------------------------------------------------
Copy-paste into Outline Manager → “Set up Outline anywhere”
----------------------------------------------------------
{
  "apiUrl": "https://${DOMAIN}:60000/b782eecb-bb9e-58be-614a-d5de1431d6b3",
  "certSha256": "${SHA256}"
}
----------------------------------------------------------
EOF