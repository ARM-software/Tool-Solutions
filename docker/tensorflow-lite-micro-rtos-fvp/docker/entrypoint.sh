#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

echo "Starting docker contaner with UID : $USER_ID"
echo ""
useradd -p docker --shell /bin/bash -u $USER_ID -o -c "" -m user 
adduser user sudo 
echo "user:docker" | chpasswd
export HOME=/home/user

exec /usr/local/bin/gosu user "$@"