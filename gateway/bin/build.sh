#!/bin/sh

root=`pwd`

test -d src || mkdir src
cd src
if ! test -d nginx-1.2.7; then
  curl http://nginx.org/download/nginx-1.2.7.tar.gz | tar xz
fi
if ! test -d ngx_devel_kit-0.2.18; then
  curl -L https://github.com/simpl/ngx_devel_kit/archive/v0.2.18.tar.gz | tar xz
fi
if ! test -d lua-nginx-module-0.8.1; then
  curl -L https://github.com/chaoslawful/lua-nginx-module/archive/v0.8.1.tar.gz | tar xz
fi
if ! test -d redis2-nginx-module-0.10; then
  curl -L https://github.com/agentzh/redis2-nginx-module/archive/v0.10.tar.gz | tar xz
fi
if ! test -d nginx-push-stream-module-0.3.4; then
  curl -L https://github.com/wandenberg/nginx-push-stream-module/archive/0.3.4.tar.gz | tar xz
fi

cd nginx-1.2.7

export LUAJIT_LIB=/usr/local/Cellar/luajit/2.0.1/lib
export LUAJIT_INC=/usr/local/Cellar/luajit/2.0.1/include/luajit-2.0
./configure \
  --with-ld-opt="-L/usr/local/lib" \
  --with-cc-opt="-I/usr/local/include" \
  --prefix=$root/nginx \
  --add-module=$root/src/ngx_devel_kit-0.2.18 \
  --add-module=$root/src/redis2-nginx-module-0.10 \
  --add-module=$root/src/nginx-push-stream-module-0.3.4 \
  --add-module=$root/src/lua-nginx-module-0.8.1

make -j2
make install

cd $root
luarocks install sha2
luarocks install lua-cjson
