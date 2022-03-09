# [WIP - NOT COMPLETE] Vagrant Ansible AWX demo

This project is to quickly stand-up an AWX instance for demo purposes.

Vagrant

* `awx` - AWX server
  * minikube
  * awx-operator
* `server01` - Example server for testing


```bash
vagrant up
```

Install [Avahi](https://www.avahi.org/), so local mDNS names resolve.

```bash
sudo dnf -y install avahi avahi-tools nss-mdns
sudo systemctl enable --now avahi-daemon
```

Install
[podman](https://podman.io/getting-started/installation.html) and
[minikube](https://minikube.sigs.k8s.io/docs/start/) following the
[awx-operator README.md](https://github.com/ansible/awx-operator/blob/devel/README.md#basic-install).

```bash
echo 'set enable-bracketed-paste off' > ~/.inputrc

sudo dnf -y install podman git @development-tools

# sudo dnf -y install https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo dnf -y install https://storage.googleapis.com/minikube/releases/latest/minikube-1.23.2-0.x86_64.rpm

minikube start --cpus=4 --memory=6g --addons=ingress

sudo ln -s $(which minikube) /usr/local/bin/kubectl

git clone https://github.com/ansible/awx-operator.git ~/src/awx-operator/
cd ~/src/awx-operator/

latest="0.14.0"
# latest=$(git tag | sort --version-sort | tail -n 1)
git checkout "$latest"

export NAMESPACE="awx"
make deploy
#kubectl config set-context --current --namespace="$NAMESPACE"
kubectl apply -n "$NAMESPACE" -f awx-demo.yml


# kubectl proxy --address='0.0.0.0' --disable-filter=true

# -- diag --
# watch kubectl get pods -A
# kubectl logs -n "$NAMESPACE" -f deployments/awx-operator-controller-manager -c manager
# kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/managed-by=awx-operator"
# kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/managed-by=awx-operator"
# minikube dashboard --url
# kubectl proxy --address='0.0.0.0' --disable-filter=true

minikube service -n "$NAMESPACE" awx-demo-service --url

kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo

curl -L -q $(minikube service awx-demo-service --url -n "$NAMESPACE")/api/v2/ping 2>/dev/null | python -m json.tool

```


Install some other niceties.

```bash
sudo dnf -y install vim bind-utils bash-completion

mkdir -p ~/.bashrc.d
cat <<- EOF > ~/.bashrc.d/minikube
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
EOF
source ~/.bashrc.d/minikube
```


* <https://app.vagrantup.com/fedora/boxes/34-cloud-base>
* <https://github.com/ansible/awx>
* <https://minikube.sigs.k8s.io/docs/start/>

--------------------------------------------------------------------------------

awx-nginx-ingress.yml

```bash
cat << EOF > awx-nginx.yml
---                                                          
apiVersion: awx.ansible.com/v1beta1                              
kind: AWX
metadata:
  name: awx-nginx
spec:
  service_type: clusterip
  ingress_type: ingress
  hostname: awx.local
EOF
```

--------------------------------------------------------------------------------

Simple web server

```bash
# helpful but not necessary
dnf install -y \
  @core \
  @development-tools \
  vim \
  git \
  bind-utils \
  ansible \
  ansible-lint 

dnf install -y httpd
systemctl enable --now httpd
echo '<html><body><h1>server01</h1></body></html>' > /var/www/html/index.html
dnf update -y && reboot
```

--------------------------------------------------------------------------------

Cleanup AWX namespace (delete everything)

```bash
kubectl -n "$NAMESPACE" delete all --all
```

