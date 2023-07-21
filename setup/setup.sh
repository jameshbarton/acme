#!/bin/bash

# exit if value for Solo Istio image is not supplied
if [[ -z "${ISTIO_REPO}" ]]; then
  echo ERROR: Specify a value for ISTIO_REPO environment variable
  echo Find the value for your Istio version at https://bit.ly/solo-istio-images
  echo The Istio images page requires user registration. Ask your Solo account executive for details.
  echo Exiting
  exit 1
fi

# exit if value for Gateway license key is not supplied
if [[ -z "${GLOO_GATEWAY_LICENSE_KEY}" ]]; then
  echo ERROR: Specify a value for GLOO_GATEWAY_LICENSE_KEY environment variable
  echo Ask your Solo account executive to supply one if your organization does not have one.
  echo Exiting
  exit 1
fi

# exit if value for Mesh/Gateway version is not supplied
if [[ -z "${GLOO_MESH_VERSION}" ]]; then
  echo ERROR: Specify a value for GLOO_MESH_VERSION environment variable
  echo Valid values look like this: v2.3.4
  echo Exiting
  exit 1
fi

# k3d-install
k3d cluster create --wait --config setup/k3d/gloo.yaml

echo '*******************************************'
echo Waiting to complete k3d cluster config...
echo '*******************************************'

sleep 30

# remove existing ones if they exist
kubectl config delete-cluster gloo > /dev/null 2>&1 || true
kubectl config delete-user gloo > /dev/null 2>&1 || true
kubectl config delete-context gloo > /dev/null 2>&1 || true

kubectl config rename-context k3d-gloo gloo

echo '*******************************************'
echo Installing Gloo Gateway...
echo '*******************************************'
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH

meshctl install --profiles gloo-gateway-demo \
  --set common.cluster=gloo \
  --set licensing.glooGatewayLicenseKey=$GLOO_GATEWAY_LICENSE_KEY \
  --kubecontext gloo

kubectl delete workspace gloo --namespace gloo-mesh --context gloo
kubectl delete workspacesettings default --namespace gloo-mesh --context gloo

echo '*******************************************'
echo Waiting to complete Gloo Gateway config...
echo '*******************************************'
sleep 90

meshctl check --kubecontext gloo
