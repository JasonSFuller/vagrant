#!/bin/bash

# https://minikube.sigs.k8s.io/docs/start/

function msg   { echo "$*"; }
function info  { msg "INFO: $*"; }
function warn  { msg "WARNING: $*" >&2; }
function error { msg "ERROR: $*" >&2; exit 1; }

if [[ "$(id -u)" != "0" ]]; then error "must run as root"; fi

#url='https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm'
url='https://storage.googleapis.com/minikube/releases/latest/minikube-1.23.2-0.x86_64.rpm'

dnf -y install "$url" bash-completion

# Make a nicer environment (for all users) with aliases, tab completion, etc.
ln -sf "$(which minikube)" /usr/local/bin/kubectl

cat <<- 'EOF' > /etc/profile.d/minikube.sh
	source <(kubectl completion bash)
	alias k=kubectl
	alias kc=kubectl
	complete -F __start_kubectl k
	EOF
