#!/bin/bash

echo "ip?"
read ip

echo "username?"
read username

scp $username@$ip:/Users/$username/.zhistory ~/.zhistory
