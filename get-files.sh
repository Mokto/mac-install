#!/bin/bash

echo "ip?"
read ip

echo "username?"
read username

scp $username@$ip:/Users/$username/Documents/web_dev.pem ~/Documents/web_dev.pem | true
scp $username@$ip:/Users/$username/.zhistory ~/.zhistory
scp -r $username@$ip:/Users/$username/.aws ~/.aw