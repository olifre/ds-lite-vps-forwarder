#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later

LANG=C

. /etc/home-forwarder.conf

if [ -z "${HOME_HOSTNAME}" ]; then
	echo "Error: HOME_HOSTNAME not set in /etc/home-forwarder.conf!"
	exit 1
fi

if [ -e /etc/home-address-ipv4 ]; then
	. /etc/home-address-ipv4
fi

NEW_IPV4_ADDRESS=$(dig +short ${HOME_HOSTNAME} A)

if [ "${HOME_IPV4_ADDRESS}" != "${NEW_IPV4_ADDRESS}" ]; then
	echo "Home IPv4 address changed: ${HOME_IPV4_ADDRESS} => ${NEW_IPV4_ADDRESS}"
	if [ -n "${SEND_MAILS_TO}" ]; then
		echo "resolved ${HOME_HOSTNAME}" | mail -s "Home IPv4 address changed: ${HOME_IPV4_ADDRESS} => ${NEW_IPV4_ADDRESS}" "${SEND_MAILS_TO}"
	fi
	echo "HOME_IPV4_ADDRESS=${NEW_IPV4_ADDRESS}" > /etc/home-address-ipv4
fi


if [ -e /etc/home-address-ipv6 ]; then
	. /etc/home-address-ipv6
fi

NEW_IPV6_ADDRESS=$(dig +short ${HOME_HOSTNAME} AAAA)

if [ "${HOME_IPV6_ADDRESS}" != "${NEW_IPV6_ADDRESS}" ]; then
	echo "Home IPv6 address changed: ${HOME_IPV6_ADDRESS} => ${NEW_IPV6_ADDRESS}"
	if [ -n "${SEND_MAILS_TO}" ]; then
		echo "resolved ${HOME_HOSTNAME}" | mail -s "Home IPv6 address changed: ${HOME_IPV6_ADDRESS} => ${NEW_IPV6_ADDRESS}" "${SEND_MAILS_TO}"
	fi
	echo "HOME_IPV6_ADDRESS=${NEW_IPV6_ADDRESS}" > /etc/home-address-ipv6
fi
