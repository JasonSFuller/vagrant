#!/usr/bin/env bash

##### vars #####################################################################

NAME='fedora-coreos-38.20230625.3.0'

GPG='https://fedoraproject.org/fedora.gpg'
SIG='https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230625.3.0/x86_64/fedora-coreos-38.20230625.3.0-virtualbox.x86_64.ova.sig'
IMG='https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230625.3.0/x86_64/fedora-coreos-38.20230625.3.0-virtualbox.x86_64.ova'
META='https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230625.3.0/x86_64/meta.json'

##### functions ################################################################

function pre_flight {
  set -e
  declare -gA COLOR
  COLOR=(
    [red]="$(tput setaf 1)"
    [blu]="$(tput setaf 4)"
    [yel]="$(tput setaf 3)"
    [red_b]="$(tput setaf 9)"
    [blu_b]="$(tput setaf 12)"
    [yel_b]="$(tput setaf 11)"
    [reset]="$(tput sgr0)"
  )
  BASE=$(basename "$IMG" .ova)
  SELF=$(realpath "$0")
  DIR=$(dirname "$SELF")
  TMP="$DIR/tmp"
  if ! builtin command -v jq &>/dev/null; then
    error "'jq' command missing, please install"
  fi
  if [[ ! -d "$TMP" ]]; then
    info "Creating temp dir '$TMP'..."
    mkdir "$TMP" || error "Could not create dir '$TMP'"
  fi
  cd "$TMP" || error "Could not access dir '$TMP'"
  trap 'clean_up' EXIT
}

function clean_up {
  info "Cleaning up..."
  VBoxManage unregistervm "$BASE" --delete || true
  cd "$DIR" || error "Clean up failed; could not access dir '$DIR'"
  rm -rf "$TMP"
}

function info  { echo "[${COLOR[blu_b]}INFO${COLOR[reset]}]:  ${COLOR[blu]}$*${COLOR[reset]}"; }
function warn  { echo "[${COLOR[yel_b]}WARN${COLOR[reset]}]:  ${COLOR[yel]}$*${COLOR[reset]}" >&2; }
function error { echo "[${COLOR[red_b]}ERROR${COLOR[reset]}]: ${COLOR[red]}$*${COLOR[reset]}" >&2; exit 1; }

##### main #####################################################################

pre_flight

info "Downloading the Fedora Project GPG key...";   curl -sSLC - "$GPG"  -o "${BASE}.gpg"
info "Downloading the Fedora CoreOS signature...";  curl -sSLC - "$SIG"  -o "${BASE}.sig"
info "Downloading the Fedora CoreOS meta data...";  curl -sSLC - "$META" -o "${BASE}.meta.json"
info "Downloading the Fedora CoreOS image...";      curl   -LC - "$IMG"  -o "${BASE}.ova" --progress-bar

info "Validating the GPG signature..."
gpgv --keyring "./${BASE}.gpg" "${BASE}.sig" "${BASE}.ova"

info "Writing the SHA256 checksum file..."
SUM="${BASE}.sha256"
SUM_SIZE=$(jq -r '.images.virtualbox.size' "${BASE}.meta.json")
SUM_PATH=$(jq -r '.images.virtualbox.path' "${BASE}.meta.json")
SUM_SHA256=$(jq -r '.images.virtualbox.sha256' "${BASE}.meta.json")
printf '%s *%s\n' "$SUM_SHA256" "$SUM_PATH" > "$SUM"

info "Validating the SHA256 checksum..."
if ! sha256sum -c "$SUM"; then
  rm -f "$BASE"*
  error "Image checksum failed"
fi

info "Validating the image size (in bytes)..."
IMG_SIZE=$(stat --printf=%s "${BASE}.ova")
if [[ "$IMG_SIZE" != "$SUM_SIZE" ]]; then
  rm -f "$BASE"*
  error "Image size check failed"
fi

info "Importing the OVA into VirtualBox as a temp VM..."
VBoxManage import "${BASE}.ova" --vsys 0 --vmname "$BASE" --settingsfile "${BASE}.vbox" \
  || error "OVA import failed"
UUID=$(
  VBoxManage showvminfo "$BASE" --machinereadable \
    | grep -oP '(?<=^hardwareuuid=)"?[[:alnum:]\-]+"?$' \
    | tr -d '"'
)
if [[ -z "$UUID" ]]; then error "Could not find uuid for '$BASE'"; fi

info "Exporting temp VM from VirtualBox into Vagrant box format..."
vagrant package --base "$UUID" --output "${BASE}.box" \
  || error "VM export failed"

info "Adding box to Vagrant..."
vagrant box add "${BASE}.box" --name "$NAME" \
  || error "Failed to add to Vagrant"

info "Successfully imported box! ($NAME)"
