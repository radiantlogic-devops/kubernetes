#!/bin/sh

# This will install the product
/opt/radiantone/run.sh



#Enalbing FIPS mode if its already not installed
/opt/radiantone/vds/bin/vdsconfig.sh list-properties | grep '"fipsMode" : true,'
if [[ $? != 0 ]]; then
    echo "=============================================================="
    echo "Entering FIPS MODE .........."
    echo "=============================================================="

    echo "=============================================================="
    echo "Stopping servers ....."
    echo "=============================================================="
    /opt/radiantone/vds/bin/advanced/stop_servers.sh

    sleep 5

    echo "=============================================================="
    echo "Replacing Java.Security file ....."
    echo "=============================================================="
    sed -i '117 s/random/urandom/2' /opt/radiantone/vds/jdk/jre/lib/security/java.security

    sleep 5

    echo "=============================================================="
    echo "Running Zookeeper ....."
    echo "=============================================================="
    /opt/radiantone/vds/bin/runZooKeeper.sh

    sleep 5

    echo "=============================================================="
    echo "Enabling FIPS mode ...."
    echo "=============================================================="
    /opt/radiantone/vds/bin/vdsconfig.sh fips-mode-enable

    sleep 5


    echo "=============================================================="
    echo "Start VDS Server ...."
    echo "=============================================================="
    /opt/radiantone/vds/bin/runVDSServer.sh

    sleep 5

    echo "=============================================================="
    echo "Start Control Panel ....."
    echo "=============================================================="
    /opt/radiantone/vds/bin/launchControlPanel.sh

    sleep 5
else
    echo "FIPS is already Installed"
    echo "=============================================================="
    echo "Start VDS Server ...."
    echo "=============================================================="
    /opt/radiantone/vds/bin/runVDSServer.sh

    sleep 5

    echo "=============================================================="
    echo "Start Control Panel ....."
    echo "=============================================================="
    /opt/radiantone/vds/bin/launchControlPanel.sh
fi

if [ "$FID_LDAP_PORT" == "" ] ;  then
  FID_LDAP_PORT=2389
fi
if [ "$FID_LDAPS_PORT" == "" ] ;  then
  FID_LDAPS_PORT=2636
fi
if [ "$CP_HTTP_PORT" == "" ] ;  then
  CP_HTTP_PORT=7070
fi
if [ "$FID_ROOT_USER" == "" ] ;  then
  FID_ROOT_USER="cn=Directory Manager"
fi
#sleep 5
echo "=============================================================="
echo "Container startup complete!"
echo "FID is running on port ${FID_LDAP_PORT} (LDAP) and ${FID_LDAPS_PORT} (LDAPS)"
echo "Control Panel can be accessed at http://$(hostname):${CP_HTTP_PORT}/"
echo "Username: ${FID_ROOT_USER}"
#echo "Password: secret1234"
echo "=============================================================="
echo ""

CHECK_PORT=$FID_LDAP_PORT
if [ "$CHECK_PORT" -eq "0" -o  "$CHECK_PORT" -eq "-1" ] ;  then
  CHECK_PORT=$FID_LDAPS_PORT
fi

echo "Wating for FID to start on port $CHECK_PORT"

timeout 60 sh -c 'until nc -z $0 $1; do sleep 5; done' $(hostname) $CHECK_PORT

if [ $? == 0 ]; then
  echo "FID started"
  sh -c 'cluster.sh list'
else
  echo "Failed to start FID on port $CHECK_PORT. Please check the logs."
  sh -c 'cluster.sh list'
  sh -c 'cluster.sh check'
fi

# Tail the logs so the container does not exit

if [ "$1" == "fg" ] ;  then
  #echo "Spawning foreground process..."
  tail -f /dev/null
fi

if [ "$1" == "log" ] ;  then
  #echo "Spawning foreground process..."
  tail -f /dev/null /opt/radiantone/vds/vds_server/logs/*.log
