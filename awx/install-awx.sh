#!/bin/bash


minikube start --cpus=4 --memory=6g --addons=ingress

# Starting minikube
#  * https://minikube.sigs.k8s.io/docs/faq/
minikube start \
  --force-systemd=true \
  --listen-address=0.0.0.0 \
  --memory=max --cpus=max \
  --addons=ingress


git clone https://github.com/ansible/awx-operator.git ~/src/awx-operator/
cd ~/src/awx-operator/ || exit

latest="0.14.0"
# latest=$(git tag | sort --version-sort | tail -n 1)
git checkout "$latest"

export NAMESPACE="awx"
make deploy
kubectl config set-context --current --namespace="$NAMESPACE"
kubectl apply -f awx-demo.yml
kubectl wait --for=condition=Ready pods --all

# -- diag --
# kubectl logs -f deployments/awx-operator-controller-manager -c manager
# kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"
# kubectl get svc -l "app.kubernetes.io/managed-by=awx-operator"

minikube service awx-demo-service --url -n $NAMESPACE

kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo

url="$(minikube service awx-demo-service --url -n "$NAMESPACE")/api/v2/ping"
curl -L -q "$url" 2>/dev/null | python -m json.tool
