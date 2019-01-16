#!/bin/sh

# Start NX server
/etc/NX/nxserver --startup

# Run tail on server log in foreground
tail -F /usr/NX/var/log/nxserver.log
