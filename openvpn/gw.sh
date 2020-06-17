#!/bin/bash

# Wait for IP address to be assigned to tun0
sleep 10

echo "Default route added for better compatibility with torrent clients"
ip netns exec pia route add default gw $(ip netns exec pia ifconfig tun0 | grep "destination" | grep -o "[^ ]*$") tun0

echo "Requesting to enable port forwarding on VPN connection"
client_id=$(ip netns exec pia head -n 100 /dev/urandom | sha256sum | tr -d " -")
ip netns exec pia curl -o "/etc/openvpn/piaport" "http://209.222.18.222:2000/?client_id=${client_id}"

port="$(cat /etc/openvpn/piaport | jq -r '.port')"
echo "PIA Port set to ${port}"
echo "PORT=${port}" > /opt/qBittorrent/ENV

if pgrep -x "qbittorrent-nox" > /dev/null; then
	echo "qBittorrent is running, setting port to ${port}"
	curl -k -i -X POST -d "json={\"listen_port\": ${port}}" "http://localhost:8080/api/v2/app/setPreferences" &> /dev/null
else
	echo "qBittorrent is not running, port stored for qBittorrent startup script."
fi
