In this guide we will describe required steps to announce hosts from first host group as /32 with specific community (blackhole for example) and hosts from second host group as /24 with different community (to redirect traffic to scrubbing centre for example). Host group is a group of multiple networks in CIDR format.

This [guide](https://fastnetmon.com/docs-fnm-advanced/selective-bgp-blackhole-or-traffic-diversion-in-fastnetmon-advanced/) assumes that you have configured BGP connection. Please follow quick start guide for it.

After configuring BGP, please disable any standard actions for BGP. We will use notify script instead because we need custom logic:
```
sudo fcli set main gobgp_announce_host disable
sudo fcli set main gobgp_announce_whole_subnet disable
sudo fcli commit
```

First of all, convert (split or aggregate) all your networks in networks_list (sudo fcli show main networks_list) to /24 CIDR networks only.

You can remove existing networks from this list this way:
```
sudo fcli delete main networks_list 11.22.33.44/32
```

And add new ones this way:
```
sudo fcli set main networks_list 11.22.33.44/24
```

Then, you need to create two host groups.

First one for hosts where you need blackhole action.
```
sudo fcli set hostgroup host_to_blackhole
sudo fcli set hostgroup host_to_blackhole threshold_mbps 100
sudo fcli set hostgroup host_to_blackhole ban_for_bandwidth enable
sudo fcli set hostgroup host_to_blackhole enable_ban enable
sudo fcli set hostgroup host_to_blackhole networks 11.22.33.44/24
```

Second one for hosts where you need traffic diversion action:
```
sudo fcli set hostgroup host_to_scrubbing
sudo fcli set hostgroup host_to_scrubbing threshold_mbps 100
sudo fcli set hostgroup host_to_scrubbing ban_for_bandwidth enable
sudo fcli set hostgroup host_to_scrubbing enable_ban enable
sudo fcli set hostgroup host_to_scrubbing networks 10.10.10.10/24
```

Please install JSON processing library for Perl:
```
sudo apt-get install -y libjson-perl git 
```

Finally, you need to download script from GitHub:
```
git clone git@github.com:FastNetMon/selective_blackhole_traffic_diversion.git
cd selective_blackhole_traffic_diversion
sudo cp notify_json.pl /usr/local/bin/notify_json.pl
```

And configure it for your FastNetMon instance to call it when FastNetMon detects an attack.
```
sudo fcli set main notify_script_enabled enable
sudo fcli set main notify_script_format json
sudo fcli set main notify_script_path /usr/local/bin/notify_json.pl
sudo fcli commit
```

After initial setup, we suggest manual check for hosts from each group and test FastNetMon’s behaviour in each case.

To test host from group host_to_blackhole:
```
sudo fcli set blackhole 11.22.33.44
```

To test host from group host_to_scrubbing:
```
sudo fcli set blackhole 10.10.10.10
```

You can debug actions from our script using this command:
```
sudo tail -f /tmp/fastnetmon_notify_script.log
```
