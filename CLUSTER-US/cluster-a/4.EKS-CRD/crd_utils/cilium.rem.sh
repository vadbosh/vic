#!/bin/bash
RED='\e[1;31m'
GREEN='\e[1;32m'
WHITE='\e[1m'
NC='\e[0m'

CLUSTER="arn:aws:eks:ap-southeast-2:381142409470:cluster/thoth-production-a"

stack-del(){
kubectl config use-context "${CLUSTER}" 
sleep 5
kubectl delete crd ciliumcidrgroups.cilium.io
kubectl delete crd ciliumclusterwidenetworkpolicies.cilium.io
kubectl delete crd ciliumendpoints.cilium.io
kubectl delete crd ciliumexternalworkloads.cilium.io
kubectl delete crd ciliumidentities.cilium.io
kubectl delete crd ciliuml2announcementpolicies.cilium.io
kubectl delete crd ciliumloadbalancerippools.cilium.io
kubectl delete crd ciliumnetworkpolicies.cilium.io
kubectl delete crd ciliumnodeconfigs.cilium.io
kubectl delete crd ciliumnodes.cilium.io
kubectl delete crd ciliumpodippools.cilium.io 
}

echo -e "\n ${RED}! ! !${NC}"
echo -e "Do you really want to remove ${GREEN}cilium${NC} from the ${GREEN}${CLUSTER}${NC} ? (${WHITE}y/n${NC})"
read Ask
if [[ $Ask = "y" ]] ; then
  #### **** Delete the comment for stack-del if you really want to delete it **** #### 
   stack-del 
fi
