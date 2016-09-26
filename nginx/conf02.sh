#!/usr/bin/env bash

# data shared between containers goes via these definitions:
dockervol_root='/docker_volumes'
shareddata_root="${dockervol_root}/01shared_data"

# configure container
export IMGID='02'  # range from 2 .. 99; must be unique
export IMAGENAME="r2h2/nginx${IMGID}"
export CONTAINERNAME="${IMGID}nginx"
export CONTAINERUSER="nginx${IMGID}"   # group and user to run container
export CONTAINERUID="80${IMGID}"   # gid and uid for CONTAINERUSER
export BUILDARGS="
    --build-arg USERNAME=$CONTAINERUSER \
    --build-arg UID=$CONTAINERUID \
"
export ENVSETTINGS=''
export NETWORKSETTINGS="
    -p 80:8080
    -p 443:8443
    --net http_proxy
    --net-alias mdfeed.test.wpv.portalverbund.at
    --ip 10.1.1.${IMGID}
"
export VOLROOT="${dockervol_root}/$CONTAINERNAME"  # container volumes on docker host
export VOLMAPPING="
    -v $VOLROOT/etc/nginx/:/etc/nginx/:Z
    -v $VOLROOT/etc/pki/tls/:/etc/pki/tls:Z
    -v $VOLROOT/var/cache/nginx:/var/cache/nginx:Z
    -v $VOLROOT/var/log/nginx:/var/log/nginx:Z
    -v $VOLROOT/var/www:/var/www:Z
    -v $shareddata_root/testPvGvAt/md_feed:/var/www/mdfeedTestPortalverbundGvAt:ro
    -v $shareddata_root/testWpvPvAt/md_feed:/var/www/mdfeedTestWpvPortalverbundAt:ro
"
#    -v $shareddata_root/testPvGvAt/ds:/var/www/dsTestPortalverbundGvAt:ro


export STARTCMD='/start.sh'

# first create user/group/host directories if not existing
if ! id -u $CONTAINERUSER &>/dev/null; then
    groupadd -g $CONTAINERUID $CONTAINERUSER
    adduser -M -g $CONTAINERUID -u $CONTAINERUID $CONTAINERUSER
fi

# create dir with given user if not existing, relative to $HOSTVOLROOT; set/repair ownership
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$VOLROOT/$dir"
    chown -R $user:$user "$VOLROOT/$dir"
}
chkdir var/cache/nginx $CONTAINERUSER
chkdir var/log/nginx $CONTAINERUSER
chkdir var/www $CONTAINERUSER
