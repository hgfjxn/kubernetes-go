echo "reset the default policies in the filter table."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "reset the default policies in the nat table."
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
echo "reset the default policies in the mangle table."
iptables -t mangle -P PREROUTING ACCEPT
iptables -t mangle -P OUTPUT ACCEPT

echo "flush all the rules in the filter and nat tables."
iptables -F
iptables -t nat -F
iptables -t mangle -F

echo "erase all chains that's not default in filter and nat table."
iptables -X
iptables -t nat -X
iptables -t mangle -X

echo "reset iptables successful"
