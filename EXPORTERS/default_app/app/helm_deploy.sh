#!/bin/bash

[[ -f ../func_deploy.sh ]] || exit 1
. ../func_deploy.sh

export TERRAFORM_MODULE_PATH="$(pwd)"

# ----- External -----
export BUILD="${BUILD:-}"

# ----- Internal -----
export REGION="${REGION:-us-east-1}"
export EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-thoth-sandbox}"
export APP_NAME="${APP_NAME:-thoth-monolith-demo-async}"
export REPOSITORY_NAME="${REPOSITORY_NAME:-thoth-monolith-demo}"
export TFVARS="${TFVARS:-"tfvars/trunk.tfvars"}"

# ----- Const -----
export AWS_ACCOUNT_ID="381142409470"
export EKS_CLUSTER_NAME_CHECKOUT="arn:aws:eks:${REGION}:${AWS_ACCOUNT_ID}:cluster/${EKS_CLUSTER_NAME}"
export TAG="${TAG:-"${REPOSITORY_NAME}-${BUILD}"}"
export CHART_VERSION="${CHART_VERSION:-$(helm repo update universal-chart 2>&1 >/dev/null && helm show chart universal-chart/universal-chart | awk '/^version/{print $2}')}"
export APP_S3_BUCKET="tf.k8s.state"
export APP_S3_KEY="${REGION}/${EKS_CLUSTER_NAME}/apps/${APP_NAME}/terraform.tfstate"

# ----- SCALE UP NODE -----
export DesiredSizePlus="${DesiredSizePlus:-0}"
export NODEGROUP_NAME="${NODEGROUP_NAME:-thoth-sandbox-xlarge}"

case "$1" in
   scale)
         K8S_USE_CONTEXT && CUR_VAL && NODE_SCALE_UP
         ;;
    plan)
         K8S_USE_CONTEXT && INIT && STATE && PLAN
         ;;
   apply)
         K8S_USE_CONTEXT && INIT && STATE && APPLY
         ;;
   destroy)
             K8S_USE_CONTEXT && INIT && STATE && DESTROY
             ;;
    *) echo -e "Usage: EKS_CLUSTER_NAME=\"XXX\" APP_NAME=\"XXX\" REPOSITORY_NAME=\"XXX\" REGION=\"XXX\" BUILD=\"XXX\" TFVARS=\"XXX\" $0 {plan|apply|destroy}"
       exit 0
esac


