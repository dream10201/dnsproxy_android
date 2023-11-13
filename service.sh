#!/system_ext/bin/bash

dumpsys deviceidle whitelist +com.android.networkstack.overlay
dumpsys deviceidle whitelist +com.android.networkstack
dumpsys deviceidle whitelist +com.android.networkstack.tethering
dumpsys deviceidle whitelist +com.qualcomm.qti.telephonyservice
dumpsys deviceidle whitelist +com.android.server.telecom
dumpsys deviceidle whitelist +com.android.providers.telephony
nohup bash -c "while true ; do sleep 60;dumpsys battery set level 100; done" >/dev/null 2>&1 &

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -P FORWARD ACCEPT

flag=0
while :
do
    dns_forwarding=`iptables -t nat -L | grep 5353`
	if [[ $dns_forwarding == "" ]];then
		iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 127.0.0.1:5353
	fi

	dnsproxy -l 127.0.0.1 -p 5353 --cache --cache-optimistic --http3 --all-servers -b 223.5.5.5 -b 119.29.29.29 -f 120.80.80.80 -u https://cn-a.iqiqz.com/dns-query -u https://doh.apad.pro/dns-query -u https://2606:4700:4700::1111/dns-query -u https://149.112.112.112/dns-query -u https://1.1.1.1/dns-query -u h3://dns.alidns.com/dns-query
	
    sleep 5
	if [ $flag -lt 10 ] ; then
		flag=`expr $flag + 1`
	else
		flag=0
		echo "Crashed more than 10 times consecutively."
		#break
	fi
done

