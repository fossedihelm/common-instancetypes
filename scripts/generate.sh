#!/bin/bash

set -e

if ! command -v kustomize &> /dev/null; then
    echo "kustomize is not installed, see https://kubectl.docs.kubernetes.io/installation/kustomize/ for more details."
    exit 1
fi

mkdir -p _build
cd _build || exit 1

# yamllint requires the initial `---` in the file but this isn't generated by kustomize
echo "---" > common-instancetypes-all-bundle.yaml
kustomize build .. >> common-instancetypes-all-bundle.yaml

echo "---" > common-instancetypes-bundle.yaml
kustomize build ../VirtualMachineInstancetypes >> common-instancetypes-bundle.yaml

echo "---" > common-clusterinstancetypes-bundle.yaml
kustomize build ../VirtualMachineClusterInstancetypes >> common-clusterinstancetypes-bundle.yaml

echo "---" > common-preferences-bundle.yaml
kustomize build ../VirtualMachinePreferences >> common-preferences-bundle.yaml

echo "---" > common-clusterpreferences-bundle.yaml
kustomize build ../VirtualMachineClusterPreferences >> common-clusterpreferences-bundle.yaml

# Add a version to each of the generated resources and calculate the checksum
COMMON_INSTANCETYPES_VERSION=${COMMON_INSTANCETYPES_VERSION-$(git describe --tags)}
export COMMON_INSTANCETYPES_VERSION
for bundle in common-*-bundle.yaml; do
    yq -i '.metadata.labels.["instancetype.kubevirt.io/common-instancetypes-version"]=env(COMMON_INSTANCETYPES_VERSION)' "${bundle}"
    sha256sum "${bundle}" >> CHECKSUMS.sha256
done
