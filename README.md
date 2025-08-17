# DS-Lite VPS forwarder

This collection of unit files and scripts can be placed on a dual-stack VPS (or similar) to enable access via IPv4 to systems which are only reachable via IPv6, e.g. a home router which is behind CG-NAT / with DS-Lite and hence not reachable via IPv4 from outside.

The unit files allows configurable port forwarding (TCP / UDP) for both IPv4 and IPv6 to target IPv6 hosts.
The target host names are resolved regularly (via a timer unit) and in addition to the forwarding units being restarted, notifications can be sent (if configured) when the addresses change.
Technically, this relies on [socat](http://www.dest-unreach.org/socat/) for the actual relaying of packets.

Note that the services will pass the corresponding hostname to `socat`, which should resolve the hostname each time a new connection is initiated. Still, when the timer unit detects any IPv6 address change, the services are forcibly restarted to ensure old connections are terminated / follow along the address change.

## Common use cases

* Reach your home network / home VPN server (e.g. Wireguard running on your router or a NAS) when you are on the road and have IPv4 connectivity only.

## Setup

1. Copy the files to their respective locations, i.e.:
   ```bash
   cp etc/systemd/system/* /etc/systemd/system/
   chmod a+x usr/local/bin/*
   cp usr/local/bin/* /usr/local/bin/
   ```

2. Reload `systemd` to let it see the new unit files:
   ```bash
   systemctl daemon-reload
   ```

3. Create and edit `/etc/home-forwarder.conf` so it contains the hostnames, a short human-readable name for them and their total count, e.g. for your home router and or home server. An example could be:
   ```
   HOME_ADDRESS_COUNT=2
   HOME_HOSTDESC_0="Fritz!Box at home"
   HOME_HOSTNAME_0=xxx.myfritz.net
   HOME_HOSTDESC_1="Home server"
   HOME_HOSTNAME_1=somedyndns.address.com
   ```

4. In case you want mails being sent to you on address change (requires local `postfix` setup on the VPS, i.e. script will just call `mail`), issue:
   ```bash
   echo "SEND_MAILS_TO=root" >> /etc/home-forwarder.conf
   ```
   This would send these mails to `root` which you might have aliased in your `postfix` config.

5. Run the hostname checking script once to check it works as expected:
    ```bash
    /usr/local/bin/home-address-update.sh
    ```
   This should fill the files:
   ```bash
   /etc/home-address-ipv4
   /etc/home-address-ipv6
   ```
   with the resolved IP addresses of your `HOME_HOSTNAME` machines.
   Note: The services will directly use the `/etc/home-forwarder.conf` as environment file, i.e. `socat` will resolve the host on any new connection.
   However, services will be restarted if the `/etc/home-address-ipv6` content changes, to ensure old connections are terminated / follow along.

6. Enable the timer unit to perform that update regularly:
    ```bash
    systemctl enable home-address-updater.timer
    systemctl start home-address-updater.timer
    ```

7. Enable the actual forwards. In this example, we want to forward `44444/tcp` to host number `0` from the config and `33333/udp` to host number `1` from the config:
    ```bash
    systemctl enable home-tcpforwarder@0:44444.service
    systemctl start home-tcpforwarder@0:44444.service
    systemctl enable home-udpforwarder@1:33333.service
    systemctl start home-udpforwarder@1:33333.service
    ```
    Note that this enables forwarding from both IPv4 and IPv6 on the VPS to IPv6 at the target to ease client configuration.
    You can of course forward as many ports as wanted.
    Note that of course you may need to adapt the VPS firewall (on the VPS / with the hosting provider) and of course open the port for IPv6 on your home router.

8. Enable the grouping "forwarder" services for TCP and UDP, and the overall grouping service for all forwarders.
   ```bash
   systemctl enable home-tcpforwarders.service
   systemctl start home-tcpforwarders.service
   
   systemctl enable home-udpforwarders.service
   systemctl start home-udpforwarders.service
   
   systemctl enable home-forwarders.service
   systemctl start home-forwarders.service
   ```
   Note: This will allow you to restart all the forwarder services by just restarting the corresponding "grouping" service. It is also used by the reloading trigger.

9. Finally, enable the path watcher to reload the services when the IPv6 address changes:
   ```bash
   systemctl enable home-address-watcher.path
   systemctl start home-address-watcher.path
   ```

10. Done! The following commands might be helpful to investigate the setup:
    ```bash
    ss -tunlp
    systemctl list-timers
    ```

11. Note that finally, you have to use the address / hostname of your VPS in any clients you want to connect to home. As both IPv4 and IPv6 are forwarded, no split configuration is required on the clients.

## Advanced use cases

This repository also ships some unused service files:

* `home-tcpforwarder-4-to-6@.service`
* `home-tcpforwarder-6-to-6@.service`
* `home-udpforwarder-4-to-6@.service`
* `home-udpforwarder-6-to-6@.service`

These are unused, as only the files:

* `home-tcpforwarder-46-to-6@.service`
* `home-udpforwarder-46-to-6@.service`

are depended on by the forwarder service templates. This is the case since `scoat` does dual-stack forwarding by default.
In case your needs differ, e.g. you only want to forward IPv4 to IPv6 and leave IPv6 alone (e.g. split configuration on the clients / different config depending on location on the clients), you can of course change the dependencies to only forward IPv4 or IPv6 packets.

## Alternative approaches

* In case you have a home server running 24/7 in addition to the VPS, you can of course use `ssh -R` to forward local targets to the VPS and make them reachable there. This bypasses the need for a publicly reachable IPv6 address at home. You may be interested in the following settings for `/etc/sshd_config`:

      GatewayPorts clientspecified
      ClientAliveInterval 120

* The `ssh` approach works for TCP only. Forwarding UDP through TCP is subject to problems when using basic approaches such as `socat`. [udp-reverse-tunnel](https://github.com/prof7bit/udp-reverse-tunnel) can be used to solve this (again, you require a home server running 24/7 and a VPS, and this bypasses the need for a publicly reachable IPv6 address at home). 
