#!/bin/bash

NGX_PAGESPEED_VER='v1.9.32.1-beta'
NGX_PAGESPEED_VER_NO_V=$(echo $NGX_PAGESPEED_VER | sed "s|^v||")

echo "using $NGX_PAGESPEED_VER, you might want to check"
echo "https://github.com/pagespeed/ngx_pagespeed/releases "
echo "and see if there are new versions. If so,"
echo "include the whole string, example: 1.9.32.1-beta "

CHANGE_USER=yes
REMOVE_DAV=yes
REMOVE_FLV=yes
REMOVE_MP4=no
REMOVE_MAIL=yes
ADD_GEOIP=no

cd /tmp

wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key

echo "deb http://nginx.org/packages/debian/ squeeze nginx" > /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/debian/ squeeze nginx" >> /etc/apt/sources.list.d/nginx.list

apt-get update && apt-get upgrade -y
apt-get install dpkg-dev build-essential zlib1g-dev libpcre3 libpcre3-dev git unzip -y
apt-get build-dep nginx -y
apt-get source nginx

PSOL_VER=$(echo $NGX_PAGESPEED_VER_NO_V | cut -d \- -f 1)
NGINX_VER=$(find ./nginx* -maxdepth 0 -type d | sed "s|^\./||")
NGINX_VER_NUM=$(echo $NGINX_VER | cut -d \- -f 2)
NGINX_BUILD_DIR=/tmp/$NGINX_VER
# start clean in case this is a rebuild
rm -rf NGINX_BUILD_DIR

if [ "$CHANGE_USER" = "yes" ]; then
sed -ie s/--user=nginx/--user=www-data/g $NGINX_BUILD_DIR/debian/rules
sed -ie s/--group=nginx/--group=www-data/g $NGINX_BUILD_DIR/debian/rules
fi
if [ "$REMOVE_DAV" = "yes" ]; then
sed -i '/--with-http_dav_module \\/d' $NGINX_BUILD_DIR/debian/rules
fi
if [ "$REMOVE_FLV" = "yes" ]; then
sed -i '/--with-http_flv_module \\/d' $NGINX_BUILD_DIR/debian/rules
fi
if [ "$REMOVE_MP4" = "yes" ]; then
sed -i '/--with-http_mp4_module \\/d' $NGINX_BUILD_DIR/debian/rules
fi
if [ "$REMOVE_MAIL" = "yes" ]; then
sed -i '/--with-mail \\/d' $NGINX_BUILD_DIR/debian/rules
sed -i '/--with-mail_ssl_module \\/d' $NGINX_BUILD_DIR/debian/rules
fi
if [ "$ADD_GEOIP" = "yes" ]; then
sed -i '/--with-http_sub_module \\/i--with-http_geoip_module \\' $NGINX_BUILD_DIR/debian/rules
fi

mkdir $NGINX_BUILD_DIR/modules

wget https://github.com/pagespeed/ngx_pagespeed/archive/$NGX_PAGESPEED_VER.zip -O $NGINX_BUILD_DIR/modules/release-$NGX_PAGESPEED_VER.zip
unzip $NGINX_BUILD_DIR/modules/release-$NGX_PAGESPEED_VER.zip -d $NGINX_BUILD_DIR/modules
rm -f $NGINX_BUILD_DIR/modules/release-$NGX_PAGESPEED_VER.zip
wget https://dl.google.com/dl/page-speed/psol/$PSOL_VER.tar.gz -O $NGINX_BUILD_DIR/modules/ngx_pagespeed-$NGX_PAGESPEED_VER_NO_V/$PSOL_VER.tar.gz
tar -C $NGINX_BUILD_DIR/modules/ngx_pagespeed-$NGX_PAGESPEED_VER_NO_V -xzf $NGINX_BUILD_DIR/modules/ngx_pagespeed-$NGX_PAGESPEED_VER_NO_V/$PSOL_VER.tar.gz
rm -f $NGINX_BUILD_DIR/modules/ngx_pagespeed-$NGX_PAGESPEED_VER_NO_V/$PSOL_VER.tar.gz
sed -i '/--with-file-aio \\/i--add-module=modules/ngx_pagespeed-|NGX_PAGESPEED_VER_NO_V| \\' $NGINX_BUILD_DIR/debian/rules
sed -ie "s/|NGX_PAGESPEED_VER_NO_V|/$NGX_PAGESPEED_VER_NO_V/g" $NGINX_BUILD_DIR/debian/rules

wget "https://github.com/FRiCKLE/ngx_cache_purge/archive/master.zip" -O /tmp/ngx_cache_purge.zip
unzip /tmp/ngx_cache_purge.zip -d $NGINX_BUILD_DIR/modules/
sed -i '/--with-file-aio \\/i--add-module=modules/ngx_cache_purge-master/ \\' $NGINX_BUILD_DIR/debian/rules

wget "https://github.com/agentzh/headers-more-nginx-module/archive/master.zip" -O /tmp/nginx_headers_more.zip
unzip /tmp/nginx_headers_more.zip -d $NGINX_BUILD_DIR/modules/
sed -i '/--with-file-aio \\/i--add-module=modules/headers-more-nginx-module-master/ \\' $NGINX_BUILD_DIR/debian/rules


echo "PSOL_VER: $PSOL_VER"
echo "NGINX_VER: $NGINX_VER"
echo "NGINX_VER_NUM: $NGINX_VER_NUM"
echo "NGINX_BUILD_DIR: $NGINX_BUILD_DIR"
echo "NGX_PAGESPEED_VER: $NGX_PAGESPEED_VER"

cd $NGINX_BUILD_DIR
dpkg-buildpackage -b

echo
echo
echo
echo "***************************************************************"
echo "*  install package from /tmp like so:                         *"
echo "*  dpkg -i /tmp/nginx_$NGINX_VER_NUM~squeeze_amd64.deb               *"
echo "*  or if you want the debug version                           *"
echo "*  dpkg -i /tmp/nginx-debug_$NGINX_VER_NUM~squeeze_amd64.deb         *"
echo "*                                                             *"
if [ "$CHANGE_USER" = "yes" ]; then
echo "*  REMEMBER TO CHANGE /etc/nginx/nginx.conf user to www-data  *"
echo "*                                                             *"
fi
echo "*  To test pagespeed:                                         *"
echo "*  in the file /etc/nginx/nginx.conf                          *"
echo "*  add the following in the http { ... } block                *"
echo "*  pagespeed on;                                              *"
echo "*  pagespeed FileCachePath /var/ngx_pagespeed_cache;          *"
echo "*                                                             *"
echo "*  then:                                                      *"
echo "*  mkdir /var/ngx_pagespeed_cache                             *"
if [ "$CHANGE_USER" = "yes" ]; then
echo "*  chown www-data:www-data /var/ngx_pagespeed_cache           *"
else
echo "*  chown nginx:nginx /var/ngx_pagespeed_cache                 *"
fi
echo "*  then:                                                      *"
echo "*  /etc/init.d/nginx reload                                   *"
echo "*  curl -I -p http://localhost|grep X-Page-Speed              *"
echo "*                                                             *"
echo "*                                                             *"
echo "***************************************************************"
echo

exit 0
