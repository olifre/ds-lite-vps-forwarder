# DS-Lite VPS forwarder

This collection of unit files and scripts can be placed on a dual-stack VPS (or similar) to enable access via IPv4 to a system which is only reachable via IPv6, e.g. a home router which is behind CG-NAT / with DS-Lite and hence not reachable via IPv4 from outside.

The unit files allows configurable port forwarding (TCP / UDP) for both IPv4 and IPv6 to a target IPv6 host.
The target host name is resolved regularly (via a timer unit) and in addition to the forwarding units being restarted, a notification can be sent (if configured) when the addresses change.
Technically, this relies on [socat](http://www.dest-unreach.org/socat/) for the actual relaying of packets.

Note that the services will pass the hostname to `socat`, which should resolve the hostname each time a new connection is initiated. Still, when the timer unit detects an IPv6 address change, the services are forcibly restarted to ensure old connections are terminated / follow along the address change.

## Common use cases

* Reach your home network / home VPN server (e.g. Wireguard running on your router or a NAS) when you are on the road and have IPv4 connectivity only.

## Setup

1. Copy the files to their respective locations, i.e.:
      cp etc/systemd/system/* /etc/systemd/system/
      chmod a+x usr/local/bin/*
      cp usr/local/bin/* /usr/local/bin/

2. Reload `systemd` to let it see the new unit files:
      systemctl daemon-reload

3. Edit `/etc/home-address-name` so it contains a DynDNS name for your home router, i.e.:
      echo "HOME_HOSTNAME=xxx.myfritz.net" > /etc/home-forwarder.conf

4. In case you want mails being sent to you on address change (requires local `postfix` setup on the VPS, i.e. script will just call `mail`), issue:
      echo "SEND_MAILS_TO=root" >> /etc/home-forwarder.conf
   This would send these mails to `root` which you might have aliased in your `postfix` config.

5. Run the hostname checking script once to check it works as expected:
      /usr/local/bin/home-address-update.sh
   This should fill the files:
      /etc/home-address-ipv4
      /etc/home-address-ipv6
   with the resolved IP addresses of your `HOME_HOSTNAME`. 
   Note: The services will directly use the `/etc/home-forwarder.conf` as environment file, i.e. `socat` will resolve the host on any new connection.
   However, services will be restarted if the `/etc/home-address-ipv6` content changes, to ensure old connections are terminated / follow along.

6. Enable the timer unit to perform that update regularly:
      systemctl enable home-address-updater.timer
      systemctl start home-address-updater.timer

7. Enable the actual forwards. In this example, we want to forward `44444/tcp` and `33333/udp`:
      systemctl enable home-tcpforwarder@44444.service
      systemctl start home-tcpforwarder@44444.service
      systemctl enable home-udpforwarder@33333.service
      systemctl start home-udpforwarder@33333.service
   Note that this enables forwarding from both IPv4 and IPv6 on the VPS to IPv6 at the target to ease client configuration.
   You can of course forward as many ports as wanted.
   Note that of course you may need to adapt the VPS firewall (on the VPS / with the hosting provider) and of course open the port for IPv6 on your home router.

8. Enable the grouping "forwarder" services for TCP and UDP, and the overall grouping service for all forwarders.
      systemctl enable home-tcpforwarders.service
      systemctl start home-tcpforwarders.service

      systemctl enable home-udpforwarders.service
      systemctl start home-udpforwarders.service

      systemctl enable home-forwarders.service
      systemctl start home-forwarders.service
   Note: This will allow you to restart all the forwarder services by just restarting the corresponding "grouping" service. It is also used by the reloading trigger.

9. Finally, enable the path watcher to reload the services when the IPv6 address changes:
      systemctl enable home-address-watcher.path
      systemctl start home-address-watcher.path

10. Done! The following commands might be helpful to investigate the setup:
       ss -tunlp
       systemctl list-timers

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
