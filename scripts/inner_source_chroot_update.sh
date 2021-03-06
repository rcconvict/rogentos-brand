#!/bin/bash

source /etc/profile
env-update
source /etc/profile

# Setup environment vars
export ETP_NONINTERACTIVE=1
if [ -d "/usr/portage/licenses" ]; then
	export ACCEPT_LICENSE="$(ls /usr/portage/licenses -1 | xargs)"
fi

export FORCE_EAPI=2

updated=0
for ((i=0; i < 6; i++)); do
		equo update && {
				updated=1;
				break;
		}
		sleep 1200 || exit 1
done

if [ "${updated}" = "0" ]; then
		exit 1
fi

export ETP_NOINTERACTIVE=1
equo upgrade || exit 1
echo "-5" | equo conf update
rm -rf /var/lib/entropy/client/packages

# Copy updated portage config files to /etc/portage
arch=$(uname -m)
if [ "${arch}" = "x86_64" ]; then
	arch="amd64"
elif [ "${arch}" = "i686" ]; then
	arch="x86"
fi
SABAYON_REPO_DIR="/var/lib/entropy/client/database/${arch}/sabayonlinux.org/standard/${arch}/5"
ROGENTOS_REPO_DIR="/var/lib/entropy/client/database/${arch}/rogentoslinux/standard/${arch}/5"
for cfg in package.mask package.unmask package.keywords package.use make.conf; do
	cfg_path="${SABAYON_REPO_DIR}/${cfg}"
	if [ ! -f "${cfg_path}" ]; then
		continue
	fi

	dest_cfg_path="/etc/portage/${cfg}"
	if [ "${cfg}" = "make.conf" ]; then
		dest_cfg_path="/etc/make.conf"
	fi
	cp "${cfg_path}" "${dest_cfg_path}" # ignore failures
done

equo query list installed -qv > /etc/rogentos-pkglist
