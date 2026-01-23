#!/bin/bash
  
TF_STATE_APP_NAME=""

CUR_VAL(){
CUR_NODEGROUP_NAME=$(aws eks --region ${REGION} list-nodegroups --cluster-name ${EKS_CLUSTER_NAME} \
                     --query "nodegroups[?contains(@, '${NODEGROUP_NAME}')]" --output text)
CUR_DesiredSize=$(aws eks --region ${REGION} describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
                  --query "nodegroup.scalingConfig.desiredSize")
}

GET_ASG_NAME(){
aws eks --region ${REGION} describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
--query "nodegroup.resources.autoScalingGroups[0].name" --output text
}

ASG_minSize(){
aws eks --region ${REGION} describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
--query "nodegroup.scalingConfig.minSize"
}

ASG_maxSize(){
aws eks --region ${REGION} describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
--query "nodegroup.scalingConfig.maxSize"
}

ASG_DesiredSize(){
aws eks --region ${REGION} describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
--query "nodegroup.scalingConfig.desiredSize"
}

NODE_SCALE_UP(){
if [[ ${DesiredSizePlus} -gt 0 ]]; then
   if [[ $((${CUR_DesiredSize}+${DesiredSizePlus})) -le $(ASG_maxSize) ]]; then
       local SET_DesiredSizePlus=$((${CUR_DesiredSize}+${DesiredSizePlus}))
     else 
       local SET_DesiredSizePlus=$(ASG_maxSize)
   fi    
   aws eks --region ${REGION} update-nodegroup-config --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name ${CUR_NODEGROUP_NAME} \
   --scaling-config desiredSize=${SET_DesiredSizePlus},minSize=$(ASG_minSize),maxSize=$(ASG_maxSize)
     while [[ $(ASG_DesiredSize) -lt ${SET_DesiredSizePlus} ]]; do
           echo -en "$(ASG_DesiredSize)❱ "
     done
   echo "$(ASG_DesiredSize)❱"
 else 
  echo "Value DesiredSizePlus ${DesiredSizePlus}"
fi
}

INIT(){
if [[ ! ($EKS_CLUSTER_NAME && $APP_NAME && $REPOSITORY_NAME && $TAG && $REGION && $BUILD && $TFVARS) ]]; then
 echo "!!! You must define all this variables !!!"
 echo EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME
 echo APP_NAME=$APP_NAME
 echo REPOSITORY_NAME=$REPOSITORY_NAME
 echo TAG=$TAG
 echo REGION=$REGION
 echo BUILD=$BUILD
 echo TFVARS=$TFVARS
 exit 1
fi
[[ -d .terraform ]] && rm -rf .terraform
[[ -e .terraform.lock.hcl ]] && rm -f .terraform.lock.hcl
[[ -e state.tf ]] && rm -f state.tf
return 0
}

K8S_USE_CONTEXT(){
if [[ "$(kubectl config current-context)" != "${EKS_CLUSTER_NAME_CHECKOUT}" ]]; then
  kubectl config use-context ${EKS_CLUSTER_NAME_CHECKOUT} && \
  kubectl config get-contexts --no-headers=true | awk '{if ( $1 ~ /[\s]+/ ){print $2} else {print $2"\tActive "$1}}' || \
  exit 1
else
  kubectl config get-contexts --no-headers=true | awk '{if ( $1 ~ /[\s]+/ ){print $2} else {print $2"\tActive "$1}}'
fi
}

STATE(){
cat << EOF >state.tf
terraform {
  backend "s3" {
    bucket = "${APP_S3_BUCKET}"
    region = "us-east-1" # !!!!! Always stored in this region 
    key    = "${APP_S3_KEY}" # !!!!! Always unique key for EACH application
  }
}
EOF
}

TF_STATE_CHECK(){
STATE_PATH="s3://${APP_S3_BUCKET}/${APP_S3_KEY}"
TF_STATE_EXIST=$(aws s3api head-object --bucket ${APP_S3_BUCKET} --key ${APP_S3_KEY} 2>/dev/null 1>/dev/null; echo $?)
if [[ ${TF_STATE_EXIST} -eq 0 ]]; then
TF_STATE_APP_NAME=$(terraform -chdir="${TERRAFORM_MODULE_PATH}" state show -state=${STATE_PATH} data.template_file.helm_values -no-color | \
                    grep -P "\"app_name\"[\s\t]+\=" | awk -F= '{gsub(/("| )/, ""); print $2}')
  if [[ ${TF_STATE_APP_NAME} != ${APP_NAME} ]]; then
    echo -e "\nTF_STATE_APP_NAME ${TF_STATE_APP_NAME} != APP_NAME ${APP_NAME} !!!\n"
    exit 1
  fi
else
  echo -e "\n *** ${APP_NAME} s3://${APP_S3_BUCKET}/${APP_S3_KEY} file does not exist - create a new ***\n"
fi
}

PLAN(){
#set -eE
if [[ ! -e state.tf ]]; then echo "state.tf - file does not exist"; exit 1; fi
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" init -no-color || exit 1
TF_STATE_CHECK
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" validate -no-color || exit 1
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" plan \
-var "app_name=${APP_NAME}" \
-var "repository_name=${REPOSITORY_NAME}" \
-var "image_tag=${TAG}" \
-var "chart_version=${CHART_VERSION}" \
-var "region=${REGION}" \
-var-file="${TFVARS}" \
-no-color || exit 1
#set +eE
}

APPLY(){
#set -eE
if [[ ! -e state.tf ]]; then echo "state.tf - file does not exist"; exit 1; fi
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" init -no-color || exit 1
TF_STATE_CHECK
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" validate -no-color || exit 1
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" apply \
-var "app_name=${APP_NAME}" \
-var "repository_name=${REPOSITORY_NAME}" \
-var "image_tag=${TAG}" \
-var "chart_version=${CHART_VERSION}" \
-var "region=${REGION}" \
-var-file="${TFVARS}" \
--auto-approve -no-color || exit 1
#set +eE
}

DESTROY(){
#set -eE
if [[ ! -e state.tf ]]; then echo "state.tf - file does not exist"; exit 1; fi
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" init -no-color || exit 1
TF_STATE_CHECK
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" validate -no-color || exit 1
TERM=dumb terraform -chdir="${TERRAFORM_MODULE_PATH}" destroy \
-var "app_name=${APP_NAME}" \
-var "repository_name=${REPOSITORY_NAME}" \
-var "image_tag=${TAG}" \
-var "chart_version=${CHART_VERSION}" \
-var "region=${REGION}" \
-var-file="${TFVARS}" \
--auto-approve -no-color || exit 1
aws s3 rm s3://${APP_S3_BUCKET}/${APP_S3_KEY} --region us-east-1
#set +eE
}


