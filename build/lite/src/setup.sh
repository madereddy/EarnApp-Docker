#!/bin/bash
wget -qO- https://brightdata.com/static/earnapp/install.sh > /app/src/earnapp.sh

archs=`uname -m`
PRODUCT="earnapp"
VERSION=$(grep VERSION= /app/src/earnapp.sh | cut -d'"' -f2)

if [ $archs = "x86_64" ]; then
    file=$PRODUCT-x64-$VERSION
elif [ $archs = "amd64" ]; then
    file=$PRODUCT-x64-$VERSION
elif [ $archs = "armv7l" ]; then
    file=$PRODUCT-arm7l-$VERSION
elif [ $archs = "armv6l" ]; then
    file=$PRODUCT-arm7l-$VERSION
elif [ $archs = "aarch64" ]; then
    file=$PRODUCT-aarch64-$VERSION
elif [ $archs = "arm64" ]; then
    file=$PRODUCT-aarch64-$VERSION
else
    file=$PRODUCT-arm7l-$VERSION
fi
mkdir /download
wget -cq --no-check-certificate https://cdn-earnapp.b-cdn.net/static/$file -O /download/earnapp
echo | md5sum /download/earnapp
chmod +x /download/earnapp