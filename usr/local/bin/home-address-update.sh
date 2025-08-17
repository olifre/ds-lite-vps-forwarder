#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later

LANG=C

. /etc/home-forwarder.conf

if [ -z "${HOME_ADDRESS_COUNT}" ]; then
	echo "Error: HOME_ADDRESS_COUNT not set in /etc/home-forwarder.conf!"
	exit 1
fi

if [ -e /etc/home-address-ipv4 ]; then
	. /etc/home-address-ipv4
fi

: > /etc/home-address-ipv4-new

for ((i = 0; i < ${HOME_ADDRESS_COUNT}; ++i)); do
	hostname_var=HOME_HOSTNAME_$i
	hostdesc_var=HOME_HOSTDESC_$i
	if [ -z "${!hostname_var}" ]; then
		echo "Error: ${hostname_var} not set in /etc/home-forwarder.conf!"
		exit 1
	fi
	if [ -z "${!hostdesc_var}" ]; then
		echo "Error: ${hostdesc_var} not set in /etc/home-forwarder.conf!"
		exit 1
	fi
	home_addr_var=HOME_IPV4_ADDRESS_$i
	NEW_IPV4_ADDRESS=$(dig +short ${!hostname_var} A)
	if [ "${!home_addr_var}" != "${NEW_IPV4_ADDRESS}" ]; then
		echo "Home IPv4 address for ${!hostdesc_var} (${i}: ${!hostname_var}) changed: ${!home_addr_var} => ${NEW_IPV4_ADDRESS}"
		if [ -n "${SEND_MAILS_TO}" ]; then
			echo "resolved ${!hostname_var}" | mail -s "Home IPv4 address for ${!hostdesc_var} (${i}: ${!hostname_var}) changed: ${!home_addr_var} => ${NEW_IPV4_ADDRESS}" "${SEND_MAILS_TO}"
		fi
	fi
	echo "${home_addr_var}=${NEW_IPV4_ADDRESS}" >> /etc/home-address-ipv4-new
done

rsync --checksum /etc/home-address-ipv4-new /etc/home-address-ipv4
rm -f /etc/home-address-ipv4-new

if [ -e /etc/home-address-ipv6 ]; then
	. /etc/home-address-ipv6
fi

: > /etc/home-address-ipv6-new

for ((i = 0; i < ${HOME_ADDRESS_COUNT}; ++i)); do
	hostname_var=HOME_HOSTNAME_$i
	hostdesc_var=HOME_HOSTDESC_$i
	if [ -z "${!hostname_var}" ]; then
		echo "Error: ${hostname_var} not set in /etc/home-forwarder.conf!"
		exit 1
	fi
	if [ -z "${!hostdesc_var}" ]; then
		echo "Error: ${hostdesc_var} not set in /etc/home-forwarder.conf!"
		exit 1
	fi
	home_addr_var=HOME_IPV6_ADDRESS_$i
	NEW_IPV6_ADDRESS=$(dig +short ${!hostname_var} AAAA)
	if [ "${!home_addr_var}" != "${NEW_IPV6_ADDRESS}" ]; then
		echo "Home IPv6 address for ${!hostdesc_var} (${i}: ${!hostname_var}) changed: ${!home_addr_var} => ${NEW_IPV6_ADDRESS}"
		if [ -n "${SEND_MAILS_TO}" ]; then
			echo "resolved ${!hostname_var}" | mail -s "Home IPv6 address for ${!hostdesc_var} (${i}: ${!hostname_var}) changed: ${!home_addr_var} => ${NEW_IPV6_ADDRESS}" "${SEND_MAILS_TO}"
		fi
	fi
	echo "${home_addr_var}=${NEW_IPV6_ADDRESS}" >> /etc/home-address-ipv6-new
done

rsync --checksum /etc/home-address-ipv6-new /etc/home-address-ipv6
rm -f /etc/home-address-ipv6-new
