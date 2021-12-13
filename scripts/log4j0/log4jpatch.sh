#!/usr/bin/bash

# This script scans for all log4j-core-*.jar under RLI_HOME and checks for the CVE-2021-44228 vulnerability.
# NOTE: the env variable RLI_HOME must be defined and must point to the root of the RadiantOne folder,
# e.g: /some/path/radiantone/vds
# The user will be prompted for confirmation before patching each jar file.
# If the jar file is already successfully patched, this script will confirm that.
# This script is forked from officially provided log4jpatch.sh by RadiantLogic Inc. to enable customer to patch without zip dependency.

if [[ -z "${RLI_HOME}" ]]; then
  echo "RLI_HOME IS NOT DEFINED"
  exit 0
fi

mkdir -p "$RLI_HOME/backup"
IFS=$'\n'
for i in $(find "$RLI_HOME" -iname "log4j-core-*.jar" -not -path "$RLI_HOME/backup/*"); do
  "$RLI_HOME"/jdk/bin/jar tf $i | grep -q -i "org/apache/logging/log4j/core/lookup/JndiLookup.class"
  if [ $? -eq 0 ]; then
    echo "$i contains the CVE-2021-44228 vulnerability."
    echo "Patching $i"
    cp "$i" "$RLI_HOME/backup"
    workFolder="${RLI_HOME}/work/log4jfixes"
    mkdir $workFolder
    cd "$workFolder" || exit
    echo "Performing JAR extraction of $i..."
    eval "${RLI_HOME}/jdk/bin/jar -xvf ${i}" &> /dev/null
    jndilookupFile="${workFolder}/org/apache/logging/log4j/core/lookup/JndiLookup.class"
    echo "Removing offending class from extracted JAR..."
    rm "$jndilookupFile"
    eval "${RLI_HOME}/jdk/bin/jar -cvf ${i} ./" &> /dev/null
    echo "Successfully recreated the JAR for $i"
    echo "${i} has been successfully patched"
    echo "Cleaning the work folder"
    cd ..
    rm -rf $workFolder
    echo -e "JAR patching completed for $i\n"
  else
    echo -e "$i has been already been patched for CVE-2021-44228 and is safe to use.\n"
  fi
done
unset IFS

#For Versions 7.3.17 and above, the following extra steps are required, which disable the 'docs' web app.
if [ -d $RLI_HOME/vds_server/work/docs ]; then
  echo Deleting the folder $RLI_HOME/vds_server/work/docs
  rm -rf $RLI_HOME/vds_server/work/docs
fi

if [ -f $RLI_HOME/apps/web/docs.war ]; then
  echo Moving the file $RLI_HOME/apps/web/docs.war to $RLI_HOME/apps/web/disabled
  mv -f $RLI_HOME/apps/web/docs.war $RLI_HOME/apps/web/disabled
fi
