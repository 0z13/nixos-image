#!/usr/bin/env bash
#
set -xeuo pipefail
shopt -s lastpipe

build_kexec_installer() {
  declare -r tag=$1 arch=$2 tmp=$3 variant=$4
  out=$(nix build --print-out-paths --option accept-flake-config true -L ".#packages.${arch}.kexec-installer-${tag//./}${variant}")
  echo "$out/nixos-kexec-installer${variant}-$arch.tar.gz"
}

main() {
  declare -r tag=${1:-nixos-unstable} arch=${2:-x86_64-linux}
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' EXIT
  (
    build_kexec_installer "$tag" "$arch" "$tmp" ""
  ) | readarray -t assets
  for asset in "${assets[@]}"; do
    pushd "$(dirname "$asset")"
    popd
  done

  if ! gh release view "$tag"; then
    gh release create --title "$tag (build $(date +"%Y-%m-%d"))" "$tag"
  fi
  gh release upload --clobber "$tag" "${assets[@]}"
}

main "$@"
