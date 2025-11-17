#!/bin/bash
RED='\e[1;31m'
GREEN='\e[1;32m'
WHITE='\e[1m'
NC='\e[0m'

CLUSTER="arn:aws:eks:us-east-1:381142409470:cluster/thoth-sandbox"

stack-del(){
kubectl config use-context "${CLUSTER}" 
sleep 5

kubectl delete crd certificaterequests.cert-manager.io
kubectl delete crd certificates.cert-manager.io
kubectl delete crd challenges.acme.cert-manager.io
kubectl delete crd clusterissuers.cert-manager.io
kubectl delete crd issuers.cert-manager.io
kubectl delete crd orders.acme.cert-manager.io
}

echo -e "\n ${RED}! ! !${NC}"
echo -e "Do you really want to remove ${GREEN}certificat-manager${NC} from the ${GREEN}${CLUSTER}${NC} ? (${WHITE}y/n${NC})"
read Ask
if [[ $Ask = "y" ]] ; then
  #### **** Delete the comment for stack-del if you really want to delete it **** #### 
  # stack-del 
fi
