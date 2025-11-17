#!/bin/bash
tx_queuelen(){
for i in $(ip -o link show|awk -F': ' '{print $2}'|grep -v '^lo$');do ip link set dev "$i" txqueuelen 5000;done
}
#------------------------------------------------------------------------------------------------------------------
tune_rx_buffers_aws(){
if ! command -v ethtool &>/dev/null;then yum install -y ethtool >/dev/null 2>&1;fi
for IF in $(ip -o link show|awk -F': ' '{print $2}'|grep -v '^lo$');do
  EOUT=$(ethtool -g "$IF" 2>/dev/null)
  [[ -z "$EOUT" ]] && continue
  MAX=$(echo "$EOUT"|grep -A 2 'Pre-set maximums'|grep 'RX:'|awk '{print $2}')
  CUR=$(echo "$EOUT"|grep -A 2 'Current hardware settings'|grep 'RX:'|awk '{print $2}')
  if [[ -n "$MAX" && -n "$CUR" ]];then
    TGT=$((MAX / 2))
    if [ "$CUR" -ne "$TGT" ];then ethtool -G "$IF" rx "$TGT" >/dev/null 2>&1;fi
  fi
done
}
#------------------------------------------------------------------------------------------------------------------
set_conntrack_max_after_cilium(){
CFILE="/proc/sys/net/netfilter/nf_conntrack_max"
DVAL="1048576"
while [ ! -f "$CFILE" ];do sleep 5;done
sleep 920
sysctl -w net.core.rmem_max=262144000 >/dev/null 2>&1
sysctl -w net.core.wmem_max=262144000 >/dev/null 2>&1
sysctl -w net.core.optmem_max=262144000 >/dev/null 2>&1
sysctl -w net.core.bpf_jit_harden=2 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_tw_reuse=1 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_fin_timeout=30 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_max_tw_buckets=262144 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
sysctl -w net.ipv4.tcp_window_scaling=1 >/dev/null 2>&1
sysctl -w net.core.netdev_max_backlog=5000 >/dev/null 2>&1
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
sysctl -w net.bridge.bridge-nf-call-iptables=1 >/dev/null 2>&1
sysctl -w vm.max_map_count=262144 >/dev/null 2>&1
sysctl -w fs.inotify.max_user_instances=8192 >/dev/null 2>&1
sysctl -w fs.inotify.max_user_watches=1048576 >/dev/null 2>&1
echo "$DVAL" > "$CFILE"
}
#------------------------------------------------------------------------------------------------------------------
/sbin/modprobe tcp_bbr >/dev/null 2>&1
sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
sysctl -w net.core.somaxconn=65535 >/dev/null 2>&1
tx_queuelen
tune_rx_buffers_aws
set_conntrack_max_after_cilium >/dev/null 2>&1 &
exit 0
