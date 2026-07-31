#!/bin/sh
COMBINED_SSID='OpenWrt-Home'
SEPARATE_2G_SSID='OpenWrt-Home-2G'
SEPARATE_5G_SSID='OpenWrt-Home-5G'
MAIN_WIFI_PASSWORD='ChangeMe123!'
GUEST_SSID='OpenWrt-Guest'
GUEST_WIFI_PASSWORD='ChangeMeGuest123!'
SQM_SHAPER_KBIT='40500'
[ "$(cat /tmp/sysinfo/board_name 2>/dev/null)" = 'tplink,archer-c6-v3' ]||exit 0
M=/etc/.c6;G=/etc/.c6-v44;F=0;[ -e $M ]||{ [ -e /etc/config/smartconnect ]&&>$M||F=1;}
L=/usr/share/luci/menu.d;R=/usr/share/rpcd/acl.d;V=/www/luci-static/resources/view;Z=/etc/sysupgrade.conf
C(){ [ -f /etc/config/$1 ]&&uci -q commit $1;};E(){ [ -x /etc/init.d/$1 ]&&/etc/init.d/$1 enable >/dev/null 2>&1;};P(){ grep -qxF "$1" $Z 2>/dev/null||echo "$1">>$Z;}
if [ $F = 1 ];then
detect_wan_device(){ device="$(ubus call network.interface.wan status 2>/dev/null|jsonfilter -e '@.l3_device' 2>/dev/null)";[ -n "$device" ]||device="$(uci -q get network.wan.device)";echo "${device:-wan}";}
WAN_DEVICE="$(detect_wan_device)"
WAN_DEVICE_SECTION="$(uci show network 2>/dev/null|sed -n "s/^network\.\([^.=]*\)\.name='$WAN_DEVICE'$/\1/p"|head -n1)"
if [ -z "$WAN_DEVICE_SECTION" ];then WAN_DEVICE_SECTION=isp_wan_mac;uci -q delete network.$WAN_DEVICE_SECTION;uci set network.$WAN_DEVICE_SECTION=device;uci set network.$WAN_DEVICE_SECTION.name="$WAN_DEVICE";fi
for IFACE in $(uci show wireless 2>/dev/null|sed -n "s/^wireless\.\([^.=]*\)=wifi-iface$/\1/p");do uci -q delete wireless."$IFACE";done
RADIO_2G="$(uci show wireless 2>/dev/null|sed -n "s/^wireless\.\([^.=]*\)\.band='2g'$/\1/p"|head -n1)";RADIO_2G=${RADIO_2G:-radio0}
RADIO_5G="$(uci show wireless 2>/dev/null|sed -n "s/^wireless\.\([^.=]*\)\.band='5g'$/\1/p"|head -n1)";RADIO_5G=${RADIO_5G:-radio1}
[ -f /etc/config/usteer ]||:>/etc/config/usteer
uci -q get usteer.@usteer[0] >/dev/null||uci add usteer usteer >/dev/null
for X in "$RADIO_2G.channels" "$RADIO_5G.channels" home2g home5g guest2g guest5g;do uci -q delete wireless.$X;done
for X in guest_dev guest;do uci -q delete network.$X;done
uci -q delete dhcp.guest
for X in guest guest_wan guest_dns guest_dhcp;do uci -q delete firewall.$X;done
uci -q delete usteer.@usteer[0].ssid_list
uci -q batch <<CFG
set system.@system[0].hostname='Archer-C6'
set system.@system[0].zonename='Asia/Kolkata'
set system.@system[0].timezone='IST-5:30'
set luci.main.mediaurlbase='/luci-static/material'
set network.wan.macsection='$WAN_DEVICE_SECTION'
set firewall.@defaults[0].flow_offloading='0'
set firewall.@defaults[0].flow_offloading_hw='0'
set firewall.@defaults[0].input='REJECT'
set firewall.@defaults[0].forward='REJECT'
set firewall.@defaults[0].synflood_protect='1'
set wireless.$RADIO_2G.country='IN'
set wireless.$RADIO_2G.channel='auto'
add_list wireless.$RADIO_2G.channels='1'
add_list wireless.$RADIO_2G.channels='6'
add_list wireless.$RADIO_2G.channels='11'
set wireless.$RADIO_2G.htmode='HT20'
set wireless.$RADIO_2G.disabled='0'
set wireless.$RADIO_5G.country='IN'
set wireless.$RADIO_5G.channel='auto'
add_list wireless.$RADIO_5G.channels='36'
add_list wireless.$RADIO_5G.channels='40'
add_list wireless.$RADIO_5G.channels='44'
add_list wireless.$RADIO_5G.channels='48'
set wireless.$RADIO_5G.htmode='VHT80'
set wireless.$RADIO_5G.disabled='0'
set wireless.home2g='wifi-iface'
set wireless.home2g.device='$RADIO_2G'
set wireless.home2g.mode='ap'
set wireless.home2g.network='lan'
set wireless.home2g.ssid='$COMBINED_SSID'
set wireless.home2g.encryption='sae-mixed'
set wireless.home2g.key='$MAIN_WIFI_PASSWORD'
set wireless.home2g.ieee80211k='1'
set wireless.home2g.bss_transition='1'
set wireless.home2g.rrm_neighbor_report='1'
set wireless.home2g.rrm_beacon_report='1'
set wireless.home2g.disabled='0'
set wireless.home5g='wifi-iface'
set wireless.home5g.device='$RADIO_5G'
set wireless.home5g.mode='ap'
set wireless.home5g.network='lan'
set wireless.home5g.ssid='$COMBINED_SSID'
set wireless.home5g.encryption='sae-mixed'
set wireless.home5g.key='$MAIN_WIFI_PASSWORD'
set wireless.home5g.ieee80211k='1'
set wireless.home5g.bss_transition='1'
set wireless.home5g.rrm_neighbor_report='1'
set wireless.home5g.rrm_beacon_report='1'
set wireless.home5g.disabled='0'
set network.guest_dev='device'
set network.guest_dev.name='br-guest'
set network.guest_dev.type='bridge'
set network.guest='interface'
set network.guest.proto='static'
set network.guest.device='br-guest'
set network.guest.ipaddr='192.168.30.1'
set network.guest.netmask='255.255.255.0'
set dhcp.guest='dhcp'
set dhcp.guest.interface='guest'
set dhcp.guest.start='100'
set dhcp.guest.limit='100'
set dhcp.guest.leasetime='6h'
set firewall.guest='zone'
set firewall.guest.name='guest'
add_list firewall.guest.network='guest'
set firewall.guest.input='REJECT'
set firewall.guest.output='ACCEPT'
set firewall.guest.forward='REJECT'
set firewall.guest_wan='forwarding'
set firewall.guest_wan.src='guest'
set firewall.guest_wan.dest='wan'
set firewall.guest_dns='rule'
set firewall.guest_dns.name='Allow-Guest-DNS'
set firewall.guest_dns.src='guest'
set firewall.guest_dns.dest_port='53'
set firewall.guest_dns.proto='tcp udp'
set firewall.guest_dns.target='ACCEPT'
set firewall.guest_dhcp='rule'
set firewall.guest_dhcp.name='Allow-Guest-DHCP'
set firewall.guest_dhcp.src='guest'
set firewall.guest_dhcp.src_port='68'
set firewall.guest_dhcp.dest_port='67'
set firewall.guest_dhcp.proto='udp'
set firewall.guest_dhcp.family='ipv4'
set firewall.guest_dhcp.target='ACCEPT'
set wireless.guest2g='wifi-iface'
set wireless.guest2g.device='$RADIO_2G'
set wireless.guest2g.mode='ap'
set wireless.guest2g.network='guest'
set wireless.guest2g.ssid='$GUEST_SSID'
set wireless.guest2g.encryption='sae-mixed'
set wireless.guest2g.key='$GUEST_WIFI_PASSWORD'
set wireless.guest2g.isolate='1'
set wireless.guest2g.disabled='1'
set wireless.guest5g='wifi-iface'
set wireless.guest5g.device='$RADIO_5G'
set wireless.guest5g.mode='ap'
set wireless.guest5g.network='guest'
set wireless.guest5g.ssid='$GUEST_SSID'
set wireless.guest5g.encryption='sae-mixed'
set wireless.guest5g.key='$GUEST_WIFI_PASSWORD'
set wireless.guest5g.isolate='1'
set wireless.guest5g.disabled='1'
set usteer.@usteer[0].network='lan'
set usteer.@usteer[0].local_mode='1'
set usteer.@usteer[0].ipv6='0'
set usteer.@usteer[0].syslog='0'
set usteer.@usteer[0].debug_level='0'
set usteer.@usteer[0].assoc_steering='0'
set usteer.@usteer[0].probe_steering='0'
set usteer.@usteer[0].aggressiveness='1'
set usteer.@usteer[0].band_steering_threshold='1'
set usteer.@usteer[0].band_steering_interval='60000'
set usteer.@usteer[0].band_steering_min_snr='-60'
set usteer.@usteer[0].band_steering_signal_threshold='5'
set usteer.@usteer[0].link_measurement_interval='60000'
add_list usteer.@usteer[0].ssid_list='$COMBINED_SSID'
CFG
for X in home2g home5g guest2g guest5g;do uci -q set wireless.$X.ieee80211w='1';uci -q set wireless.$X.sae_pwe='2';done
for X in guest2g guest5g;do uci -q set wireless.$X.bridge_isolate='1';done
[ -f /etc/config/dropbear ]&&uci -q batch <<U
set dropbear.@dropbear[0].Interface='lan'
set dropbear.@dropbear[0].GatewayPorts='0'
set dropbear.@dropbear[0].MaxAuthTries='3'
set dropbear.@dropbear[0].mdns='0'
U
cat > /etc/config/smartconnect <<CFG
config settings 'main'
option enabled '1'
option combined_ssid '$COMBINED_SSID'
option combined_password '$MAIN_WIFI_PASSWORD'
option encryption 'sae-mixed'
option ssid_2g '$SEPARATE_2G_SSID'
option password_2g '$MAIN_WIFI_PASSWORD'
option ssid_5g '$SEPARATE_5G_SSID'
option password_5g '$MAIN_WIFI_PASSWORD'
option guest_enabled '0'
option guest_ssid '$GUEST_SSID'
option guest_password '$GUEST_WIFI_PASSWORD'
option radio_2g '$RADIO_2G'
option radio_5g '$RADIO_5G'
CFG
>$M
fi
[ -f /etc/config/uhttpd ]&&{ uci -q set uhttpd.main.redirect_https=0;for X in listen_https cert key;do uci -q delete uhttpd.main.$X;done;rm -f /etc/uhttpd.crt /etc/uhttpd.key;};C uhttpd;sed -i '/glass/d' $Z 2>/dev/null
cat > /usr/sbin/smart-connect-apply <<'SMARTAPPLY'
#!/bin/sh
. /lib/functions.sh
config_load smartconnect
config_get_bool S main enabled 1
config_get C main combined_ssid 'OpenWrt-Home'
config_get K main combined_password 'ChangeMe123!'
config_get E main encryption 'sae-mixed'
config_get A main ssid_2g 'OpenWrt-Home-2G'
config_get B main password_2g 'ChangeMe123!'
config_get D main ssid_5g 'OpenWrt-Home-5G'
config_get F main password_5g 'ChangeMe123!'
config_get_bool G main guest_enabled 0
config_get H main guest_ssid 'OpenWrt-Guest'
config_get J main guest_password 'ChangeMeGuest123!'
config_get R2 main radio_2g radio0
config_get R5 main radio_5g radio1
if [ "$S" = 1 ];then [ ${#K} -ge 8 ]||exit 1;A=$C;D=$C;B=$K;F=$K;else [ ${#B} -ge 8 ]&&[ ${#F} -ge 8 ]||exit 1;fi
[ "$G" != 1 ]||[ ${#J} -ge 8 ]||exit 1
case "$E" in sae-mixed|psk2);;*)E=sae-mixed;;esac
w(){ uci -q set wireless.$1.$2="$3";}
for X in home2g home5g guest2g guest5g;do w $X encryption "$E";done
w home2g ssid "$A";w home2g key "$B";w home2g disabled 0
w home5g ssid "$D";w home5g key "$F";w home5g disabled 0
w guest2g ssid "$H";w guest2g key "$J";w guest2g disabled "$([ "$G" = 1 ]&&echo 0||echo 1)"
w guest5g ssid "$H";w guest5g key "$J";w guest5g disabled "$([ "$G" = 1 ]&&echo 0||echo 1)"
w "$R2" disabled 0;w "$R5" disabled 0
uci -q delete usteer.@usteer[0].ssid_list;uci -q add_list usteer.@usteer[0].ssid_list="$C"
uci commit wireless;uci commit usteer;wifi reload>/dev/null 2>&1
if [ "$S" = 1 ];then /etc/init.d/usteer enable;/etc/init.d/usteer restart;else /etc/init.d/usteer stop;/etc/init.d/usteer disable;fi>/dev/null 2>&1
SMARTAPPLY
cat > /etc/init.d/smart-connect <<'SMARTINIT'
#!/bin/sh /etc/rc.common
START=98
STOP=12
start(){ /usr/sbin/smart-connect-apply;}
reload(){ start;}
restart(){ start;}
stop(){ /etc/init.d/usteer stop>/dev/null 2>&1;}
SMARTINIT
mkdir -p /usr/share/luci/menu.d /usr/share/rpcd/acl.d /www/luci-static/resources/view
cat > $L/luci-app-smart-connect.json <<'SMARTMENU'
{"admin/network/smart-connect":{"title":"Smart Connect","order":55,"action":{"type":"view","path":"smart-connect-v7"},"depends":{"acl":["luci-app-smart-connect"]}}}
SMARTMENU
cat > $R/luci-app-smart-connect.json <<'SMARTACL'
{"luci-app-smart-connect":{"read":{"uci":["smartconnect"]},"write":{"uci":["smartconnect"],"ubus":{"uci":["commit"],"luci":["setInitAction"]}}}}
SMARTACL
cat > $V/smart-connect-v7.js <<'SMARTJS'
'use strict';'require view';'require form';'require ui';'require rpc';var c=rpc.declare({object:'uci',method:'commit',params:['config']}),i=rpc.declare({object:'luci',method:'setInitAction',params:['name','action']});function v(s,n,t,p,d){var o=s.option(form.Value,n,_(t));if(p)o.password=true,o.datatype='wpakey';if(d)o.depends(d[0],d[1])}function e(s,n,t,d){var o=s.option(form.ListValue,n,_(t));o.value('sae-mixed',_('WPA2/WPA3 Mixed'));o.value('psk2',_('WPA2 Personal'));if(d)o.depends(d[0],d[1])}return view.extend({handleSaveApply:function(){return this.map.save().then(()=>c('smartconnect')).then(()=>i('smart-connect','restart')).then(()=>ui.addNotification(null,E('p',_('Wi-Fi applied.')),'success')).catch(e=>ui.addNotification(null,E('p',_('Apply failed: %s').format(e.message||e)),'error'))},render:function(){var m=this.map=new form.Map('smartconnect',_('Smart Connect and Guest Wi-Fi')),s=m.section(form.NamedSection,'main','settings',_('Main Wi-Fi')),o;s.anonymous=true;o=s.option(form.Flag,'enabled',_('Smart Connect'));o.default=o.enabled;o.forcewrite=true;v(s,'combined_ssid','Combined SSID');v(s,'combined_password','Combined password',1);e(s,'encryption','Encryption');v(s,'ssid_2g','2.4 GHz SSID',0,['enabled','0']);v(s,'password_2g','2.4 GHz password',1,['enabled','0']);v(s,'ssid_5g','5 GHz SSID',0,['enabled','0']);v(s,'password_5g','5 GHz password',1,['enabled','0']);s=m.section(form.NamedSection,'main','settings',_('Guest Wi-Fi'));s.anonymous=true;o=s.option(form.Flag,'guest_enabled',_('Guest Wi-Fi'));o.default=o.disabled;o.forcewrite=true;v(s,'guest_ssid','Guest SSID',0,['guest_enabled','1']);v(s,'guest_password','Guest password',1,['guest_enabled','1']);return m.render().then(r=>(r.appendChild(E('style',{},'.cbi-map .cbi-value.hidden{display:flex!important;opacity:.45;pointer-events:none}')),r))}});
SMARTJS
if { [ $F = 1 ]||[ ! -e $G ];}&&[ -f /etc/config/nlbwmon ]&&uci -q get nlbwmon.@nlbwmon[0] >/dev/null;then
uci -q batch <<U
set nlbwmon.@nlbwmon[0].refresh_interval='300s'
set nlbwmon.@nlbwmon[0].database_interval='1'
set nlbwmon.@nlbwmon[0].commit_interval='1h'
set nlbwmon.@nlbwmon[0].database_generations='3'
set nlbwmon.@nlbwmon[0].database_limit='5000'
U
>$G
fi
mkdir -p /usr/libexec
cat > /usr/libexec/router-connected-clients <<'CLIENTLIST'
#!/bin/sh
T=/tmp/router-clients.$$;A=$T.ap;E=$T.eth;N=$T.neigh;O=$T.out;LI=$T.ip;LM=$T.mac
trap 'rm -f "$T" "$A" "$E" "$N" "$O" "$LI" "$LM"' EXIT INT TERM
:>"$A";:>"$E";:>"$O"
for D in $(ubus call network.wireless status 2>/dev/null|jsonfilter -e '@.*.interfaces[*].ifname' 2>/dev/null);do
[ "$(ubus call iwinfo info "{\"device\":\"$D\"}" 2>/dev/null|jsonfilter -e '@.mode' 2>/dev/null)" = Master ]||continue
ubus call iwinfo assoclist "{\"device\":\"$D\"}" 2>/dev/null|jsonfilter -e '@.results[*].mac' 2>/dev/null
done|tr A-F a-f|sort -u >"$A"
ip -4 addr show 2>/dev/null|awk '/ inet /{split($2,a,"/");print a[1]}' >"$LI"
for F in /sys/class/net/*/address;do cat "$F" 2>/dev/null;done|tr A-F a-f|sort -u >"$LM"
bridge fdb show br br-lan 2>/dev/null|awk '{d="";p=0;for(i=1;i<=NF;i++){if($i=="dev")d=$(i+1);if($i=="permanent"||$i=="self")p=1}if(!p&&(d~/^lan[0-9]+$/||d~/^eth[0-9.]+$/))print tolower($1)}'|sort -u >"$E"
ip -4 neigh show dev br-lan 2>/dev/null|awk '$0!~/ (FAILED|INCOMPLETE)( |$)/{m="";for(i=1;i<=NF;i++)if($i=="lladdr")m=tolower($(i+1));if(m)print m,$1}'|sort -k1,1 -u >"$N"
add(){ M=$1;I=$2;[ -n "$I" ]||I=$(awk -v m="$M" 'tolower($2)==m{print $3;exit}' /tmp/dhcp.leases 2>/dev/null);[ -n "$I" ]||return;grep -qxF "$I" "$LI"&&return;grep -qxF "$M" "$LM"&&return;grep -q "^$M $I$" "$O"||printf '%s %s\n' "$M" "$I">>"$O";}
while read -r M;do [ -n "$M" ]&&add "$M" "$(awk -v m="$M" '$1==m{print $2;exit}' "$N")";done<"$A"
while read -r M I;do grep -qxF "$M" "$A"||{ grep -qxF "$M" "$E"&&add "$M" "$I";};done<"$N"
[ "$1" = --count ]&&{ wc -l<"$O"|tr -d ' ';exit;}
e(){ printf '%s' "$1"|sed 's/\\/\\\\/g;s/"/\\"/g';}
printf '[';F=1
while read -r M I;do H=$(awk -v m="$M" 'tolower($2)==m{print $4;exit}' /tmp/dhcp.leases 2>/dev/null);[ -n "$H" ]&&[ "$H" != '*' ]||H='Unknown device';[ $F = 1 ]||printf ',';F=0;printf '{"ip":"%s","mac":"%s","name":"%s"}' "$(e "$I")" "$(e "$(printf %s "$M"|tr a-f A-F)")" "$(e "$H")";done<"$O"
printf ']\n'
CLIENTLIST
cat > /usr/libexec/router-dashboard-state <<'DASHSTATE'
#!/bin/sh
g(){ uci -q get "$1" 2>/dev/null;}
b(){ case "$1" in 1|true|on|yes)printf true;;*)printf false;;esac;}
e(){ printf '%s' "$1"|sed 's/\\/\\\\/g;s/"/\\"/g';}
W2=$(g wireless.home2g.ssid);W5=$(g wireless.home5g.ssid);[ -n "$W2" ]||W2=$(g smartconnect.main.ssid_2g);[ -n "$W5" ]||W5=$(g smartconnect.main.ssid_5g);[ -n "$W2" ]||W2=OpenWrt-Home-2G;[ -n "$W5" ]||W5=OpenWrt-Home-5G;[ "$W2" = "$W5" ]&&N=$W2||N="$W2 / $W5"
A=$(g adblock.global.adb_enabled);Q=$(g sqm.wan.enabled);D=$(g sqm.wan.download);U=$(g sqm.wan.upload)
G2=$(g wireless.guest2g.disabled);G5=$(g wireless.guest5g.disabled);G=0;[ "$G2" = 0 ]&&G=1;[ "$G5" = 0 ]&&G=1
LI=$(g network.lan.ipaddr);LD=$(g network.lan.device);[ -n "$LD" ]||LD=br-lan;LM=$(cat /sys/class/net/$LD/address 2>/dev/null|tr a-f A-F)
WD=$(ubus call network.interface.wan status 2>/dev/null|jsonfilter -e '@.l3_device' 2>/dev/null);[ -n "$WD" ]||WD=$(g network.wan.device);[ -n "$WD" ]||WD=$(ip -4 route|awk '/^default/{for(i=1;i<=NF;i++)if($i=="dev"){print $(i+1);exit}}')
WI=$(ip -4 addr show dev "$WD" 2>/dev/null|awk '/inet /{sub(/\/.*/,"",$2);print $2;exit}')
WM=$(cat /sys/class/net/$WD/address 2>/dev/null);[ -n "$WM" ]||WM=$(g network.wan.macaddr);WM=$(printf %s "$WM"|tr a-f A-F)
RX=$(cat /sys/class/net/$WD/statistics/rx_bytes 2>/dev/null);TX=$(cat /sys/class/net/$WD/statistics/tx_bytes 2>/dev/null)
NOW=$(date +%s);K=0;ON=false;SC=/tmp/router-dashboard-slow;SH=0
if read -r ST SK SO <"$SC" 2>/dev/null;then
case "$ST" in ''|*[!0-9]*)ST=0;;esac;case "$SK" in ''|*[!0-9]*)SK=0;;esac;case "$SO" in true|false):;;*)SO=false;;esac
AGE=$((NOW-ST));[ "$AGE" -ge 0 ]&&[ "$AGE" -lt 10 ]&&{ K=$SK;ON=$SO;SH=1;}
fi
if [ "$SH" = 0 ];then
K=$(/usr/libexec/router-connected-clients --count 2>/dev/null)
if [ -n "$WD" ]&&[ -n "$WI" ]&&(ping -c1 -W1 1.1.1.1 >/dev/null 2>&1||ping -c1 -W1 8.8.8.8 >/dev/null 2>&1);then ON=true;else ON=false;fi
printf '%s %s %s\n' "$NOW" "$K" "$ON" >"$SC"
fi
NRX=0;NTX=0;NH=0;NC=/tmp/router-dashboard-nlbw
if read -r NTS NXR NXT <"$NC" 2>/dev/null;then
for V in NTS NXR NXT;do eval X=\$$V;case "$X" in ''|*[!0-9]*)eval $V=0;;esac;done
AGE=$((NOW-NTS));[ "$AGE" -ge 0 ]&&[ "$AGE" -lt 60 ]&&{ NRX=$NXR;NTX=$NXT;NH=1;}
fi
if [ "$NH" = 0 ];then
set -- $(nlbw -c csv -g fam -o fam -n -q 2>/dev/null|awk 'NR==1{for(i=1;i<=NF;i++){if($i=="rx_bytes")r=i;if($i=="tx_bytes")t=i}next}r&&t{rx+=$r;tx+=$t}END{printf "%.0f %.0f\n",rx,tx}')
NRX=${1:-0};NTX=${2:-0};for V in NRX NTX;do eval X=\$$V;case "$X" in ''|*[!0-9]*)eval $V=0;;esac;done
printf '%s %s %s\n' "$NOW" "$NRX" "$NTX" >"$NC"
fi
NP='Current period';[ "$(g nlbwmon.@nlbwmon[0].database_interval)" = 1 ]&&NP='This month'
set -- $(awk '/^cpu /{t=0;for(i=2;i<=NF;i++)t+=$i;print t,$5+$6;exit}' /proc/stat);CT=$1;CI=$2
set -- $(awk '/MemTotal:/{t=$2}/MemAvailable:/{a=$2}END{print t*1024,(t-a)*1024}' /proc/meminfo);MT=$1;MU=$2
set -- $({ df -k /overlay 2>/dev/null||df -k / 2>/dev/null;}|awk 'END{print $2*1024,$3*1024,$4*1024}');DT=$1;DU=$2;DA=$3
/etc/init.d/watchcat enabled >/dev/null 2>&1&&WC=true||WC=false
for V in K D U RX TX NRX NTX CT CI MT MU DT DU DA;do eval X=\$$V;case "$X" in ''|*[!0-9]*)eval $V=0;;esac;done
printf '{"guest":%s,"adblock":%s,"sqm":%s,"watchcat":%s,"online":%s,"ssid":"%s","clients":%s,"sqm_download":%s,"sqm_upload":%s,"lan_ip":"%s","lan_mac":"%s","wan_ip":"%s","wan_mac":"%s","wan_dev":"%s","rx":%s,"tx":%s,"used_rx":%s,"used_tx":%s,"period":"%s","cpu_total":%s,"cpu_idle":%s,"ram_total":%s,"ram_used":%s,"disk_total":%s,"disk_used":%s,"disk_free":%s}\n' "$(b "$G")" "$(b "$A")" "$(b "$Q")" "$WC" "$ON" "$(e "$N")" "$K" "$D" "$U" "$(e "$LI")" "$(e "$LM")" "$(e "$WI")" "$(e "$WM")" "$(e "$WD")" "$RX" "$TX" "$NRX" "$NTX" "$(e "$NP")" "$CT" "$CI" "$MT" "$MU" "$DT" "$DU" "$DA"
DASHSTATE
[ $F = 1 ]&&cat > /etc/config/devicecontrol <<'LIMITCFG'
config globals 'global'
option enabled '1'
option priority_enabled '1'
LIMITCFG
cat > /usr/sbin/device-limit <<'LIMITSH'
#!/bin/sh
. /lib/functions.sh
CONFIG='devicecontrol';TABLE='device_control';TMP=/tmp/device-control.$$;trap 'rm -f "$TMP"' EXIT INT TERM
valid_ipv4(){ echo "$1"|awk -F. 'NF!=4{exit 1}{for(i=1;i<=4;i++)if($i!~/^[0-9]+$/||$i<0||$i>255)exit 1}';}
valid_uint(){ case "$1" in ''|*[!0-9]*)return 1;;*)return 0;;esac;}
valid_mac(){ echo "$1"|grep -Eq '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$';}
mac_for_ip(){
local ip="$1" s m
s=$(uci show dhcp 2>/dev/null|sed -n "s/^dhcp\.\([^.=]*\)\.ip='$ip'$/\1/p"|head -n1);[ -n "$s" ]&&m=$(uci -q get dhcp.$s.mac)
[ -n "$m" ]||m=$(awk -v i="$ip" '$3==i{print $2;exit}' /tmp/dhcp.leases 2>/dev/null)
[ -n "$m" ]||m=$(ip -4 neigh show dev br-lan 2>/dev/null|awk -v i="$ip" '$1==i{for(n=1;n<=NF;n++)if($n=="lladdr"){print $(n+1);exit}}')
printf '%s' "$m"|tr a-f A-F
}
reserve_device(){
local section="$1" ip="$2" name="$3" s rip byip oldmac
DEV_IP=$ip;DEV_MAC=$(mac_for_ip "$ip");valid_mac "$DEV_MAC"||return 0
s=$(uci show dhcp 2>/dev/null|sed -n "s/^dhcp\.\([^.=]*\)\.mac='\([^']*\)'$/\1 \2/p"|awk -v m="$DEV_MAC" 'toupper($2)==m{print $1;exit}')
if [ -n "$s" ];then rip=$(uci -q get dhcp.$s.ip);if valid_ipv4 "$rip";then DEV_IP=$rip;[ "$rip" = "$ip" ]||{ uci -q set devicecontrol.$section.ip="$rip";DVC=1;};return 0;fi;fi
byip=$(uci show dhcp 2>/dev/null|sed -n "s/^dhcp\.\([^.=]*\)\.ip='$ip'$/\1/p"|head -n1)
if [ -n "$byip" ];then oldmac=$(uci -q get dhcp.$byip.mac|tr a-f A-F);[ "$oldmac" = "$DEV_MAC" ]||{ logger -t device-limit "DHCP IP $ip already reserved for another device";return 0;};s=$byip;else s=devlimit_$(printf %s "$DEV_MAC"|tr -d ':');fi
uci -q set dhcp.$s=host;uci -q set dhcp.$s.mac="$DEV_MAC";uci -q set dhcp.$s.ip="$ip";[ -n "$name" ]&&uci -q set dhcp.$s.name="$name";DCH=1
}
emit_device(){
local section="$1" enabled internet ip name down up priority down_rate up_rate dscp
config_get_bool enabled "$section" enabled 1;[ "$enabled" = 1 ]||return 0
config_get_bool internet "$section" internet 1;config_get ip "$section" ip;config_get name "$section" name
config_get down "$section" download_mbit 0;config_get up "$section" upload_mbit 0;config_get priority "$section" priority normal
valid_ipv4 "$ip"||return 0;valid_uint "$down"||down=0;valid_uint "$up"||up=0
reserve_device "$section" "$ip" "$name";ip=$DEV_IP
if [ "$internet" != 1 ];then
valid_mac "$DEV_MAC"&&printf '  iifname "br-lan" oifname "%s" ether saddr %s counter drop\n' "$WAN_IF" "$DEV_MAC" >>"$TMP"
printf '  iifname "br-lan" oifname "%s" ip saddr %s counter drop\n  iifname "%s" oifname "br-lan" ip daddr %s counter drop\n' "$WAN_IF" "$ip" "$WAN_IF" "$ip" >>"$TMP";return 0
fi
if [ "$PRIORITY_MASTER" = 1 ];then case "$priority" in high)dscp=cs5;;low)dscp=cs1;;*)dscp='';;esac;if [ -n "$dscp" ];then printf '  iifname "br-lan" ip saddr %s ip dscp set %s counter\n' "$ip" "$dscp" >>"$TMP";printf '  oifname "br-lan" ip daddr %s ip dscp set %s counter\n' "$ip" "$dscp" >>"$TMP";fi;fi
[ "$LIMIT_MASTER" = 1 ]||return 0;down_rate=$((down*125));up_rate=$((up*125))
[ "$up_rate" -gt 0 ]&&printf '  iifname "br-lan" ip saddr %s limit rate over %s kbytes/second burst 256 kbytes counter drop\n' "$ip" "$up_rate" >>"$TMP"
[ "$down_rate" -gt 0 ]&&printf '  oifname "br-lan" ip daddr %s limit rate over %s kbytes/second burst 256 kbytes counter drop\n' "$ip" "$down_rate" >>"$TMP"
}
apply_rules(){
config_load "$CONFIG";config_get_bool LIMIT_MASTER global enabled 1;config_get_bool PRIORITY_MASTER global priority_enabled 1
WAN_IF=$(ubus call network.interface.wan status 2>/dev/null|jsonfilter -e '@.l3_device' 2>/dev/null);[ -n "$WAN_IF" ]||WAN_IF=$(uci -q get network.wan.device);[ -n "$WAN_IF" ]||WAN_IF=wan
DCH=0;DVC=0
printf 'table inet device_control {\n chain forward { type filter hook forward priority -10; policy accept;\n' >$TMP;config_foreach emit_device device;printf ' }\n}\n' >>$TMP
nft list table inet $TABLE>/dev/null 2>&1&&sed -i "1idelete table inet $TABLE" $TMP
nft -c -f $TMP>/dev/null 2>&1||return 1;nft -f $TMP||return 1
[ "$DVC" = 1 ]&&uci -q commit devicecontrol
if [ "$DCH" = 1 ];then uci -q commit dhcp;/etc/init.d/dnsmasq reload >/dev/null 2>&1;fi
}
case "$1" in apply|reload|restart)apply_rules;;stop)nft delete table inet "$TABLE" >/dev/null 2>&1;;status)nft list table inet "$TABLE";;*)echo 'Usage: device-limit {apply|stop|status}';exit 1;;esac
LIMITSH
cat > /etc/init.d/device-limit <<'LIMITINIT'
#!/bin/sh /etc/rc.common
START=95
STOP=15
start(){ /usr/sbin/device-limit apply;}
reload(){ start;}
restart(){ start;}
stop(){ /usr/sbin/device-limit stop;}
LIMITINIT
mkdir -p /usr/share/device-limit
cat > /usr/share/device-limit/firewall.include <<'LIMITFW'
#!/bin/sh
/usr/sbin/device-limit apply >/dev/null 2>&1
LIMITFW
uci -q delete firewall.device_limit_include
uci -q batch <<U
set firewall.device_limit_include='include'
set firewall.device_limit_include.type='script'
set firewall.device_limit_include.path='/usr/share/device-limit/firewall.include'
set firewall.device_limit_include.fw4_compatible='1'
U
cat > $L/luci-app-device-limit.json <<'LIMITMENU'
{"admin/network/device-limit":{"title":"Device Control","order":75,"action":{"type":"view","path":"device-limit-v7"},"depends":{"acl":["luci-app-device-limit"]}}}
LIMITMENU
cat > $R/luci-app-device-limit.json <<'LIMITACL'
{"luci-app-device-limit":{"read":{"uci":["devicecontrol","network","sqm"],"ubus":{"file":["exec"]},"file":{"/usr/libexec/router-connected-clients":["exec"]}},"write":{"uci":["devicecontrol"],"ubus":{"uci":["commit"],"luci":["setInitAction"]}}}}
LIMITACL
cat > $V/device-limit-v7.js <<'LIMITJS'
'use strict';'require view';'require form';'require ui';'require rpc';'require fs';'require uci';var c=rpc.declare({object:'uci',method:'commit',params:['config']}),i=rpc.declare({object:'luci',method:'setInitAction',params:['name','action']});return view.extend({load:()=>Promise.all([uci.load('devicecontrol'),uci.load('network'),L.resolveDefault(fs.exec('/usr/libexec/router-connected-clients'),{code:1,stdout:'[]'})]),handleSaveApply:function(){return this.map.save().then(()=>c('devicecontrol')).then(()=>i('device-limit','restart')).then(()=>ui.addNotification(null,E('p',_('Device policy applied.')),'success')).catch(e=>ui.addNotification(null,E('p',_('Apply failed: %s').format(e.message||e)),'error'))},render:function(d){var r=uci.get('network','lan','ipaddr'),b={},a=[];try{a=JSON.parse((d[2]||{}).stdout||'[]')}catch(e){}a.forEach(x=>{if(x&&x.ip&&x.ip!==r)b[x.ip]={ip:x.ip,mac:x.mac||'',name:x.name||_('Unknown device')}});uci.sections('devicecontrol','device',x=>{if(x.ip&&!b[x.ip])b[x.ip]={ip:x.ip,mac:'',name:x.name||_('Saved device')}});var l=Object.keys(b).map(x=>b[x]);l.sort((a,b)=>L.naturalCompare(a.name,b.name)||L.naturalCompare(a.ip,b.ip));var m=this.map=new form.Map('devicecontrol',_('Device Control'),_('Active and saved devices. 0 is unlimited.')),g=m.section(form.NamedSection,'global','globals',_('Master controls')),o,s;g.anonymous=true;o=g.option(form.Flag,'enabled',_('Bandwidth limiter'));o.default=o.enabled;o.forcewrite=true;o=g.option(form.Flag,'priority_enabled',_('Priority management'));o.default=o.enabled;o.forcewrite=true;s=m.section(form.GridSection,'device',_('Controlled devices'));s.anonymous=true;s.addremove=true;s.addbtntitle=_('Add Device');s.nodescriptions=true;s.sortable=false;o=s.option(form.Flag,'enabled',_('Enabled'));o.default=o.enabled;o.forcewrite=true;o.editable=true;o=s.option(form.ListValue,'internet',_('Internet access'));o.value('1',_('On'));o.value('0',_('Paused'));o.default='1';o=s.option(form.Value,'name',_('Name'));o.placeholder=_('Phone, TV, PC…');o=s.option(form.Value,'ip',_('Active or saved device'));o.datatype='ip4addr';l.forEach(x=>o.value(x.ip,x.mac?'%s — %s — %s'.format(x.name,x.ip,x.mac):'%s — %s'.format(x.name,x.ip)));o=s.option(form.ListValue,'priority',_('Priority'));o.value('high',_('High'));o.value('normal',_('Normal'));o.value('low',_('Low'));o.default='normal';o=s.option(form.Value,'download_mbit',_('Download Mbit/s'));o.datatype='uinteger';o.default='0';o=s.option(form.Value,'upload_mbit',_('Upload Mbit/s'));o.datatype='uinteger';o.default='0';return m.render()}});
LIMITJS
if [ $F = 1 ]&&[ -f /etc/config/adblock ];then
uci -q delete adblock.global.adb_feed
uci -q batch <<U
set adblock.global.adb_enabled='0'
set adblock.global.adb_debug='0'
set adblock.global.adb_nftforce='0'
set adblock.global.adb_dnsshift='0'
set adblock.global.adb_safesearch='0'
set adblock.global.adb_mail='0'
set adblock.global.adb_report='0'
set adblock.global.adb_trigger='wan'
set adblock.global.adb_triggerdelay='30'
add_list adblock.global.adb_feed='adguard'
add_list adblock.global.adb_feed='adguard_tracking'
U
fi
if [ $F = 1 ]&&[ -f /etc/config/sqm ];then
uci -q delete sqm.wan
uci -q batch <<U
set sqm.wan='queue'
set sqm.wan.enabled='1'
set sqm.wan.interface='$WAN_DEVICE'
set sqm.wan.download='$SQM_SHAPER_KBIT'
set sqm.wan.upload='$SQM_SHAPER_KBIT'
set sqm.wan.qdisc='cake'
set sqm.wan.script='layer_cake.qos'
set sqm.wan.qdisc_advanced='0'
set sqm.wan.linklayer='none'
set sqm.wan.squash_dscp='0'
set sqm.wan.squash_ingress='0'
set sqm.wan.ingress_ecn='ECN'
set sqm.wan.egress_ecn='ECN'
set sqm.wan.debug_logging='0'
set sqm.wan.verbosity='5'
U
fi
cat > /usr/sbin/sqm-wan-sync <<'SQMSYNC'
#!/bin/sh
DEVICE="$(ubus call network.interface.wan status 2>/dev/null | jsonfilter -e '@.l3_device' 2>/dev/null)"
[ -n "$DEVICE" ] || DEVICE="$(uci -q get network.wan.device)"
[ -n "$DEVICE" ] || exit 0
CURRENT="$(uci -q get sqm.wan.interface)"
[ "$CURRENT" = "$DEVICE" ] && exit 0
uci -q set sqm.wan.interface="$DEVICE"
uci -q commit sqm
/etc/init.d/sqm restart >/dev/null 2>&1
SQMSYNC
mkdir -p /etc/hotplug.d/iface
cat > /etc/hotplug.d/iface/95-sqm-wan-sync <<'SQMHOTPLUG'
#!/bin/sh
[ "$INTERFACE" = 'wan' ] || exit 0
case "$ACTION" in
ifup|ifupdate) /usr/sbin/sqm-wan-sync >/dev/null 2>&1 & ;;
esac
SQMHOTPLUG
if [ $F = 1 ]&&[ -f /etc/config/watchcat ];then
while uci -q delete 'watchcat.@watchcat[0]';do :;done
for X in wan_recover:restart_iface:5m router_reboot:ping_reboot:15m;do S=${X%%:*};Y=${X#*:};O=${Y%%:*};T=${Y#*:};uci -q batch <<U
set watchcat.$S='watchcat'
set watchcat.$S.mode='$O'
set watchcat.$S.period='$T'
set watchcat.$S.pingperiod='30s'
set watchcat.$S.pinghosts='1.1.1.1 8.8.8.8'
set watchcat.$S.pingsize='standard'
U
done
uci set watchcat.wan_recover.interface='wan'
fi
cat >$L/luci-app-wan-setup.json <<'WANMENU'
{"admin/network/wan-setup":{"title":"Setup","order":1,"action":{"type":"view","path":"wan-setup-v2"},"depends":{"acl":["luci-app-wan-setup"]}}}
WANMENU
cat >$R/luci-app-wan-setup.json <<'WANACL'
{"luci-app-wan-setup":{"read":{"uci":["network"]},"write":{"uci":["network"]}}}
WANACL
cat >$V/wan-setup-v2.js <<'WANJS'
'use strict';'require view';'require form';'require uci';var N='network',W='wan';function g(s,o){return uci.get(N,s,o)}function u(s,o,v){uci.set(N,s,o,v)}function d(s,o){uci.unset(N,s,o)}function p(o,a){a.forEach(x=>o.depends('proto',x))}function v(s,n,t,d,a,w){var o=s.option(form.Value,n,t);if(d)o.datatype=d;if(a)p(o,a);if(w)o.password=true;return o}function z(o,i){o.cfgvalue=()=>{var a=g(W,'dns');a=Array.isArray(a)?a:a?[a]:[];return a[i]||''};o.write=(x,y)=>{var a=g(W,'dns');a=Array.isArray(a)?a.slice():a?[a]:[];a[i]=y;u(W,'dns',a.filter(Boolean))};o.remove=x=>o.write(x,'');o.depends('proto','static');['dhcp','pppoe'].forEach(p=>o.depends({proto:p,peerdns:'0'}))}return view.extend({load:()=>uci.load(N),render:function(){var m=new form.Map(N,'Setup'),s=m.section(form.NamedSection,W,'interface','IPv4'),o,x;o=s.option(form.ListValue,'proto','Internet Connection');o.value('dhcp','Dynamic IP (DHCP)');o.value('static','Static IP');o.value('pppoe','PPPoE');o.value('none','Disabled');v(s,'ipaddr','IP Address','ip4addr',['static']);v(s,'netmask','Subnet Mask','ip4addr',['static']);v(s,'gateway','Gateway','ip4addr',['static']);v(s,'username','PPPoE Username',0,['pppoe']);v(s,'password','PPPoE Password',0,['pppoe'],1);o=s.option(form.Flag,'peerdns','Automatic DNS');o.default='1';p(o,['dhcp','pppoe']);z(v(s,'dns1','Primary DNS','ip4addr'),0);z(v(s,'dns2','Secondary DNS','ip4addr'),1);v(s,'mtu','MTU','uinteger',['dhcp','static','pppoe']);x=g(W,'macsection')||'isp_wan_mac';o=s.option(form.ListValue,'_mm','MAC Mode');o.value('clone','Clone MAC');o.value('hardware','Hardware MAC');o.cfgvalue=()=>g(x,'macaddr')||g(W,'macaddr')?'clone':'hardware';o.write=(i,y)=>{if(y==='hardware'){d(W,'macaddr');d(x,'macaddr')}};o=s.option(form.Value,'_ma','MAC Address');o.datatype='macaddr';o.rmempty=false;o.depends('_mm','clone');o.cfgvalue=()=>g(x,'macaddr')||g(W,'macaddr')||'';o.write=(i,y)=>{u(x,'macaddr',y);u(W,'macaddr',y)};return m.render().then(r=>(r.appendChild(E('style',{},'.cbi-value.hidden{display:flex!important;opacity:.45;pointer-events:none}')),r))}});
WANJS
cat > $L/luci-app-router-dashboard.json <<'DASHMENU'
{"admin/status/dashboard":{"title":"Dashboard","order":0,"action":{"type":"view","path":"router-dashboard-v30"},"depends":{"acl":["luci-app-router-dashboard"]}}}
DASHMENU
cat > $R/luci-app-router-dashboard.json <<'DASHACL'
{"luci-app-router-dashboard":{"read":{"ubus":{"system":["board","info"],"file":["exec"]},"file":{"/usr/libexec/router-dashboard-state":["exec"]}}}}
DASHACL
cat > $V/router-dashboard-v30.js <<'DASHJS'
'use strict';'require view';'require rpc';'require fs';'require poll';var B=rpc.declare({object:'system',method:'board',expect:{'':{}}}),I=rpc.declare({object:'system',method:'info',expect:{'':{}}}),P;function G(){return Promise.all([L.resolveDefault(B(),{}),L.resolveDefault(I(),{}),L.resolveDefault(fs.exec('/usr/libexec/router-dashboard-state'),{stdout:'{}'})])}function Z(n){n=+n||0;var u=['B','KiB','MiB','GiB','TiB','PiB'],i=0;while(n>=1024&&i<u.length-1)n/=1024,i++;return'%.1f %s'.format(n,u[i])}function U(n){n=+n||0;var d=n/86400|0,h=n%86400/3600|0,m=n%3600/60|0;return(d?d+'d ':'')+h+'h '+m+'m'}function A(l){return L.url.apply(L,l)}function C(i,t,v,d,l,c){return E('a',{'class':'m '+(c||''),href:A(l)},[E('i',{},i),E('span',{},[E('small',{},t),E('b',{},v),E('em',{},d||'')])])}function S(i,t,d,on,l){return E('a',{'class':'s '+(on?'on':''),href:A(l)},[E('i',{},i),E('span',{},[E('b',{},t),E('small',{},d)]),E('em',{},on?'On':'Off')])}function Q(i,t,d,l){return E('a',{'class':'q',href:A(l)},[E('i',{},i),E('span',{},[E('b',{},t),E('small',{},d)])])}function D(d){var b=d[0]||{},i=d[1]||{},s={};try{s=JSON.parse((d[2]||{}).stdout||'{}')}catch(e){}var on=s.online===true,n=Date.now(),rx=+s.rx||0,tx=+s.tx||0,ct=+s.cpu_total||0,ci=+s.cpu_idle||0,ds=0,us=0,cp=0;if(P){var z=(n-P.n)/1000,t=ct-P.ct;if(z>0)ds=Math.max(0,(rx-P.rx)*8/z/1e6),us=Math.max(0,(tx-P.tx)*8/z/1e6);if(t>0)cp=Math.max(0,Math.min(100,(t-(ci-P.ci))*100/t))}P={n:n,rx:rx,tx:tx,ct:ct,ci:ci};var mt=+s.ram_total||0,mu=+s.ram_used||0,dt=+s.disk_total||0,du=+s.disk_used||0,rp=mt?mu*100/mt:0,dp=dt?du*100/dt:0,sq=s.sqm===true,ge=s.guest===true,cl=+s.clients||0,dn=(+s.sqm_download||0)/1000,up=(+s.sqm_upload||0)/1000,ur=+s.used_rx||0,ut=+s.used_tx||0;return[E('style',{},'.d{padding:12px;border:1px solid rgba(127,127,127,.28);border-radius:22px;background:rgba(127,127,127,.05);color:inherit}.h{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:17px 19px;border:1px solid rgba(127,127,127,.18);border-radius:22px;background:rgba(127,127,127,.09);color:inherit}.h h2{margin:0}.ac{display:flex;gap:7px}.p{padding:7px 11px;border:1px solid rgba(127,127,127,.2);border-radius:22px;background:rgba(127,127,127,.08);text-decoration:none;color:inherit}.p.ok{color:#23a66a}.p.no{color:#d35a5a}.t{text-align:center;margin:20px 0 0;padding:8px;border-block:1px solid rgba(127,127,127,.25);border-radius:18px;background:rgba(127,127,127,.08);color:inherit}.lg,.ng,.sg,.qg{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:9px;padding:10px;border:1px solid rgba(127,127,127,.22);border-radius:22px;background:rgba(127,127,127,.04)}.m,.s,.q{color:inherit;text-decoration:none;background:rgba(127,127,127,.12);border:1px solid rgba(127,127,127,.2);border-radius:18px}.m{display:flex;gap:10px;height:96px;padding:13px;overflow:hidden}.m i,.s i,.q i{font-style:normal;font-size:1.45rem;color:var(--c,#18a8b7)}.m span,.s span,.q span{display:flex;flex-direction:column;min-width:0}.m b{font-size:1.12rem;margin:4px 0;overflow-wrap:anywhere}.c{--c:#18a8b7}.b{--c:#3f7cff}.g{--c:#22a66b}.o{--c:#f0a13c}.v{--c:#8b67d5}.s{display:flex;align-items:center;gap:8px;height:72px;padding:11px}.s span{flex:1}.s>em{color:#d35a5a;font-size:1.1rem;font-weight:800}.s.on>em{color:#23a66a}.q{display:flex;align-items:center;gap:9px;height:64px;padding:10px}@media(max-width:900px){.lg,.ng,.sg,.qg{grid-template-columns:repeat(2,1fr)}}@media(max-width:520px){.h{flex-direction:column;align-items:flex-start}.lg,.ng,.sg,.qg{grid-template-columns:1fr}}'),E('div',{'class':'d'},[E('div',{'class':'h'},[E('div',{},[E('h2',{},'Archer C6'),E('small',{},(b.model||'Archer C6 V3')+' · '+(((b.release||{}).description)||'OpenWrt'))]),E('div',{'class':'ac'},[E('a',{'class':'p',href:A(['admin','system','reboot'])},'Reboot'),E('a',{'class':'p',href:A(['admin','system','attendedsysupgrade'])},'Update'),E('span',{'class':'p '+(on?'ok':'no')},on?'Internet online':'Internet offline')])]),E('h3',{'class':'t'},'Live overview'),E('div',{'class':'lg'},[C('⇅','Live traffic','↓ '+ds.toFixed(2)+' · ↑ '+us.toFixed(2)+' Mbit/s',(s.period||'Current period')+' ↓ '+Z(ur)+' · ↑ '+Z(ut),['admin','services','nlbw'],'c'),C('●','Active clients',String(cl),'Clients',['admin','network','wireless'],'g'),C('◴','CPU usage',cp.toFixed(1)+'%','CPU',['admin','status','processes'],'o'),C('▦','RAM usage',Z(mu)+' / '+Z(mt),rp.toFixed(1)+'% · '+Z(Math.max(0,mt-mu))+' free',['admin','status','overview'],'v'),C('▣','Storage',Z(du)+' / '+Z(dt),dp.toFixed(1)+'% · '+Z(Math.max(0,dt-du))+' free',['admin','system','package-manager'],'b'),C('◷','Uptime',U(i.uptime),'Load '+L.toArray(i.load||[]).map(x=>(+x/65535).toFixed(2)).join(' / '),['admin','status','overview'],'g'),C('≈','SQM plan',sq?'%.1f / %.1f Mbit/s'.format(dn,up):'Disabled','CAKE',['admin','network','sqm'],'c'),C('⌁','Applied Wi-Fi',s.ssid||'-',ge?'Guest active':'Guest off',['admin','network','smart-connect'],'v')]),E('h3',{'class':'t'},'System'),E('div',{'class':'ng'},[C('◉','Internet',on?'Connected':'Disconnected','IPv4 '+(s.wan_ip||'-'),['admin','network','network'],'c'),C('⌘','WAN MAC',s.wan_mac||'-',s.wan_dev||'wan',['admin','network','wan-setup'],'o'),C('⌂','Router network',s.lan_ip||'-','LAN '+(s.lan_mac||'-'),['admin','network','network'],'b'),C('↗','Active uplink',s.wan_dev||'wan','IPv4 '+(s.wan_ip||'-'),['admin','network','network'],'v')]),E('h3',{'class':'t'},'Services'),E('div',{'class':'sg'},[S('◉','Guest Wi-Fi',ge?'Guest active':'Guest off',ge,['admin','network','smart-connect']),S('✦','Adblock','AdGuard',s.adblock===true,['admin','services','adblock']),S('≈','SQM QoS','CAKE',sq,['admin','network','sqm']),S('↻','Internet recovery','Recovery',s.watchcat===true,['admin','services','watchcat'])]),E('h3',{'class':'t'},'Quick access'),E('div',{'class':'qg'},[['◉','Setup','IP, DNS and MAC',['admin','network','wan-setup']],['⌁','Wireless','Wi-Fi clients',['admin','network','wireless']],['✦','Smart Connect & Guest','Wi-Fi settings',['admin','network','smart-connect']],['⚖','Device Control','Device rules',['admin','network','device-limit']],['≈','SQM QoS','CAKE',['admin','network','sqm']],['⌂','DHCP & DNS','DHCP and DNS',['admin','network','dhcp']],['⛨','Firewall','Firewall rules',['admin','network','firewall']],['✦','Adblock','Blocklists',['admin','services','adblock']],['▥','Bandwidth Monitor','Usage history',['admin','services','nlbw']],['↻','Internet Recovery','Recovery',['admin','services','watchcat']],['◉','Overview','Status',['admin','status','overview']],['⌁','Channel Analysis','Channels',['admin','status','channel_analysis']],['⌁','Realtime Graphs','Graphs',['admin','status','realtime']],['✓','Diagnostics','Network tests',['admin','network','diagnostics']],['≡','System Log','Logs',['admin','status','logs','syslog']],['↑','Firmware Update','Upgrade',['admin','system','attendedsysupgrade']],['▣','Backup / Reset','Backup',['admin','system','flash']],['⚙','System Settings','Settings',['admin','system','system']],['▣','Software','Packages',['admin','system','package-manager']],['◴','Processes','Tasks',['admin','status','processes']]].map(x=>Q(x[0],x[1],x[2],x[3])))])];}return view.extend({handleSaveApply:null,handleSave:null,handleReset:null,load:G,render:function(d){var r=E('div',{},D(d));poll.add(()=>G().then(x=>r.replaceChildren.apply(r,D(x))),3);return r}});
DASHJS
chmod 0755 /usr/sbin/smart-connect-apply /etc/init.d/smart-connect /usr/libexec/router-connected-clients /usr/libexec/router-dashboard-state /usr/sbin/device-limit /etc/init.d/device-limit /usr/share/device-limit/firewall.include /usr/sbin/sqm-wan-sync /etc/hotplug.d/iface/95-sqm-wan-sync
for X in $M $G /etc/config/smartconnect /etc/config/devicecontrol /etc/init.d/smart-connect /etc/init.d/device-limit /usr/sbin/smart-connect-apply /usr/sbin/device-limit /usr/sbin/sqm-wan-sync /usr/libexec/router-connected-clients /usr/libexec/router-dashboard-state /etc/hotplug.d/iface/95-sqm-wan-sync /usr/share/device-limit/firewall.include $L/luci-app-smart-connect.json $L/luci-app-device-limit.json $L/luci-app-wan-setup.json $L/luci-app-router-dashboard.json $R/luci-app-smart-connect.json $R/luci-app-device-limit.json $R/luci-app-wan-setup.json $R/luci-app-router-dashboard.json $V/smart-connect-v7.js $V/device-limit-v7.js $V/wan-setup-v2.js $V/router-dashboard-v30.js /var/lib/nlbwmon;do P $X;done
if [ $F = 1 ];then
for X in system luci network wireless dhcp firewall usteer smartconnect nlbwmon devicecontrol adblock sqm watchcat dropbear uhttpd;do C $X;done
for X in smart-connect device-limit nlbwmon adblock sqm watchcat;do E $X;done
ubus call network reload >/dev/null 2>&1||/etc/init.d/network reload >/dev/null 2>&1;sleep 2
ifdown wan >/dev/null 2>&1;ifup wan >/dev/null 2>&1
for X in firewall smart-connect device-limit nlbwmon watchcat dropbear;do /etc/init.d/$X restart >/dev/null 2>&1;done
/usr/sbin/sqm-wan-sync >/dev/null 2>&1
for X in sqm adblock;do /etc/init.d/$X restart >/dev/null 2>&1;done
fi
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache /tmp/luci-sessions/*
/etc/init.d/rpcd restart >/dev/null 2>&1
/etc/init.d/uhttpd reload >/dev/null 2>&1
exit 0