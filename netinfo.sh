#!/usr/bin/env bash
# Emit JSON describing wifi + vpn state for the Wi-Fi pill:
#   { "wifiEnabled":true, "ssid":"home-5G", "vpnActive":true,
#     "networks":[{"ssid","signal","secured","active"}...],
#     "vpns":[{"name","type","active"}...] }
# All via nmcli. SSIDs/names containing ':' are uncommon and not handled.
set -u

radio="$(nmcli -t -f WIFI radio 2>/dev/null)"
wenabled=false; [ "$radio" = "enabled" ] && wenabled=true

# Active SSID for the pill label.
ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -1)"
ssid_esc="$(printf '%s' "$ssid" | sed 's/\\/\\\\/g; s/"/\\"/g')"

# Visible networks, strongest-first, de-duplicated by SSID.
networks="$(nmcli -t -f SIGNAL,ACTIVE,SECURITY,SSID dev wifi 2>/dev/null \
  | sort -t: -k1,1nr \
  | awk -F: '
      { sig=$1; act=$2; sec=$3; ssid=$4 }
      ssid=="" { next }
      seen[ssid]++ { next }
      {
        gsub(/\\/,"\\\\",ssid); gsub(/"/,"\\\"",ssid);
        secured = (sec!="" && sec!="--") ? "true" : "false";
        active  = (act=="yes") ? "true" : "false";
        if (n++) printf ",";
        printf "{\"ssid\":\"%s\",\"signal\":%d,\"secured\":%s,\"active\":%s}", ssid, sig, secured, active;
      }')"

# VPN / WireGuard connection profiles.
vpns="$(nmcli -t -f TYPE,ACTIVE,NAME connection show 2>/dev/null \
  | awk -F: '
      $1=="vpn" || $1=="wireguard" {
        type=$1; act=$2; name=$0; sub(/^[^:]*:[^:]*:/,"",name);
        gsub(/\\/,"\\\\",name); gsub(/"/,"\\\"",name);
        active=(act=="yes")?"true":"false";
        if (n++) printf ",";
        printf "{\"name\":\"%s\",\"type\":\"%s\",\"active\":%s}", name, type, active;
      }')"

vpnactive=false
nmcli -t -f TYPE,ACTIVE connection show 2>/dev/null | grep -qE '^(vpn|wireguard):yes' && vpnactive=true

printf '{"wifiEnabled":%s,"ssid":"%s","vpnActive":%s,"networks":[%s],"vpns":[%s]}\n' \
  "$wenabled" "$ssid_esc" "$vpnactive" "$networks" "$vpns"
