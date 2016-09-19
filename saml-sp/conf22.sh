#!/usr/bin/env bash

DOCKERVOL_ROOT='/docker_volumes'

# data shared between containers goes via these definitions:
mdfeed_dir="${DOCKERVOL_ROOT}/01shared_data/10pyff/md_feed"

# configure container
export IMGID='22'  # range from 1 .. 99; must be unique
export IMAGENAME="rhoerbe/gitlabsp${IMGID}"
export CONTAINERNAME="${IMGID}gitlabsp"
export CONTAINERUSER='0'  # run container with root, transition to non-root handled by daemons
export SHIBDUSER="shibd${IMGID}"
export SHIBDUID="80${IMGID}"
export HTTPDUSER="httpd${IMGID}"
export HTTPDUID="90${IMGID}"
export BUILDARGS="
    --build-arg "SHIBDUSER=$SHIBDUSER" \
    --build-arg "SHIBDUID=$SHIBDUID" \
    --build-arg "HTTPDUSER=$HTTPDUSER" \
    --build-arg "HTTPDUID=$HTTPDUID" \
"
export ENVSETTINGS="
"
export NETWORKSETTINGS="
    --net http_proxy
    --ip 10.1.1.${IMGID}
"
export VOLROOT="$DOCKERVOL_ROOT/$CONTAINERNAME"  # container volumes on docker host
# mounting var/lock/.., var/run to get around permission problems when starting non-root
export VOLMAPPING="
    -v $VOLROOT/etc/httpd:/opt/etc/httpd:ro
    -v $VOLROOT/etc/shibboleth:/etc/shibboleth:Z
    -v $VOLROOT/var/lock/shibboleth:/var/lock/shibboleth:Z
    -v $VOLROOT/var/lock/subsys:/var/lock/subsys:Z
    -v $VOLROOT/var/log/:/var/log:Z
    -v $VOLROOT/var/www/gitlabTestPortalverbundGvAt:/var/www/gitlabTestPortalverbundGvAt:ro
    -v $mdfeed_dir:/opt/md_feed:ro
"
#    -v $VOLROOT/etc/pki:/etc/pki:Z

export STARTCMD='/start.sh' # run1.sh starts the container with shibd

# first start: create user/group/host directories
if ! id -u $SHIBDUSER &>/dev/null; then
    groupadd -g $SHIBDUID $SHIBDUSER
    adduser -M -g $SHIBDUID -u $SHIBDUID $SHIBDUSER
fi
if ! id -u $HTTPDUSER &>/dev/null; then
    groupadd -g $HTTPDUID $HTTPDUSER
    adduser -M -g $HTTPDUID -u $HTTPDUID $HTTPDUSER
fi
# create dir with given user if not existing, relative to $HOSTVOLROOT
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$VOLROOT/$dir"
    chown -R $user:$user "$VOLROOT/$dir"
}
#chkdir etc/pki $HTTPDUSER
chkdir etc/shibboleth $SHIBDUSER
chkdir var/log/httpd $HTTPDUSER
chkdir var/lock/shibboleth $SHIBDUSER
chkdir var/lock/subsys $SHIBDUSER
chkdir var/log/shibboleth $SHIBDUSER
rm -f $VOLROOT/var/run/shibboleth/shibd.sock
