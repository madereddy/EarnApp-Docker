#!/bin/bash
echo "Installing"
cp /download/earnapp /usr/bin/earnapp
chmod a+wr /etc/earnapp/
touch /etc/earnapp/status
chmod a+wr /etc/earnapp/status
printf $EARNAPP_UUID > /etc/earnapp/uuid

earnapp stop
sleep 2
earnapp start
sleep 2
echo "Earnapp is running"
earnapp run