nmcli con add con-name charon type macvlan ifname charon ip4 10.6.6.7/32 dev enp42s0 mode bridge
nmcli con mod charon +ipv4.routes "10.6.6.8/29"
nmcli con mod charon +ipv4.routes "10.6.6.16/29"
nmcli con up charon
