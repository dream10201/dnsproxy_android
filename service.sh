#!/sbin/sh

dumpsys deviceidle whitelist +com.android.networkstack.overlay
dumpsys deviceidle whitelist +com.android.networkstack
dumpsys deviceidle whitelist +com.android.networkstack.tethering
dumpsys deviceidle whitelist +com.android.networkstack.tethering
iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 127.0.0.1:5353

dnsproxy -l 127.0.0.1 -p 5353 --cache --cache-optimistic --all-servers -b 119.29.29.29 -f 120.80.80.80 -u https://101.6.6.6:8443/dns-query -u https://cn-a.iqiqz.com/dns-query -u https://doh.apad.pro/dns-query -u https://2606:4700:4700::1111/dns-query -u https://2606:4700:4700::1111/dns-query -u https://2606:4700:4700::1001/dns-query
