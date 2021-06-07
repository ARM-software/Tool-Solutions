#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}
if [ "${USER_ID}" == "0" ];
then
    exec /usr/sbin/gosu root "$@"
else
    echo "Starting docker contaner with UID : $USER_ID"
    echo ""
    useradd -p docker --shell /bin/bash -u $USER_ID -o -c "" -m user 
    adduser user sudo 
    sed -i -e '/\%sudo/ c \%sudo ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
    echo "user:docker" | chpasswd
    export HOME=/home/user

    exec /usr/sbin/gosu user "$@"
fi
