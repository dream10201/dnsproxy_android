#!/system_ext/bin/bash
# Notes:
## resetprop (without -n) = deletes a property then modifies it, this forces property_service to update that property immediately.
## Avoid changing props that can be important to a niche group of users, such as "persist.traced.enable".

# 'dun' persistently tells the telecom that tethering was used.
# Only a reboot can remove the 'dun' APN flag; but here we disable setting 'dun' in the first place.
resetprop tether_dun_required 0

# Don't tell the telecom to check if tethering is even allowed for your data plan.
resetprop net.tethering.noprovisioning true
resetprop tether_entitlement_check_state 0

# Fully shut-down the device to prevent connection issues; never hibernate on "Power off".
resetprop -p persist.ro.config.hw_quickpoweron false
resetprop -p persist.ro.warmboot.capability 0


#== Performance tweaks ==
sysctl -w kernel.sched_schedstats=0
echo off > /proc/sys/kernel/printk_devkmsg
for disks in /sys/block/*/queue; do
    # Don't log I/O statistics.
    echo 0 > "$disks/iostats" 
done
# Use "Explicit Congestion Notification" for both incoming and outgoing packets.
sysctl -w net.ipv4.tcp_ecn=1
# Consume more battery while semi-idle to have more stable internet.
## For some devices with old Linux kernels, this lessens CPU interrupts and thus saves battery.
sysctl -w kernel.timer_migration=0


# Use the best available TCP congestion algorithm.
sysctl -w net.ipv4.tcp_congestion_control=cubic
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.ipv4.tcp_congestion_control=bbr2
sysctl -w net.ipv4.tcp_congestion_control=bbr3

# Don't apply iptables rules until Android has fully booted.
until [ "$(getprop sys.boot_completed)" -eq 1 ]; do
    sleep 1s
done

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

