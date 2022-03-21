#!/bin/sh

#Trap SIGTERM
trap 'true' SIGTERM

echo "Version ${FID_VERSION} starting..."
echo "### Container startup begin ###"
echo "=============================================================="

if [ -e /opt/radiantone/vds/vds_server/conf/cloud.properties ] ; then
        CURRENT_VERSION=$(/opt/radiantone/vds/bin/advanced/swissknife.sh com.rli.tools.ShowVersion | grep Build-Id | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
        CURRENT_BUILDID=$(/opt/radiantone/vds/bin/advanced/swissknife.sh com.rli.tools.ShowVersion | grep Build-Id | awk '{print $3}')
        echo "FID version ${CURRENT_VERSION} with Build-ID ${CURRENT_BUILDID} already installed"
        if [ "$(printf '%s\n' "$FID_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$FID_VERSION" ]; then
        	echo "Greater than or equal to $FID_VERSION"
        else
              echo "Less than $FID_VERSION"
              export CURRENT_VERSION
              ./update.sh
              if [ $? == 0 ]; then
        	echo "Success"
	      else
        	echo "Failed to update from ${CURRENT_VERSION} to ${FID_VERSION}. Please check the logs."
        	echo "Roll back to previous image with version ${CURRENT_VERSION}"
		echo "****"
        	exit 99
	      fi                
         fi
else
	./install.sh
       if [ $? == 0 ]; then
         echo "Success"
       else
         echo "Failed to install version ${FID_VERSION}. Please check the logs."
	 echo "****"
	 exit 99
       fi
       echo "Cluster: ${CLUSTER}"
        # If new first node and export file exists
       if [ "$CLUSTER" != "join" ] ;  then 
          if [ -e /migrations/export.zip ] ; then
            echo "Migration file found. Running migration..."
            ./migrate-local.sh import /migrations/export.zip

            if [ $? == 0 ]; then
              echo "Migration successful."
            else
              echo "Failed to run the migration process."
              exit 9              
            fi
          fi 
       fi
fi

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

#if [ "$CLUSTER" == "new" ] ;  then

  #echo "=============================================================="
  #echo "Starting GlassFish process..."
  # start glassfish and mq
  #/opt/radiantone/vds/bin/start_glassfish.sh

#fi

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
fi
