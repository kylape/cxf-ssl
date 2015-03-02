#!/bin/bash

#This script assumes 
# - you want to use standalone mode
# - you have a clean installation of EAP 6
# - a JDK is installed on your $PATH
# - ant is on your $PATH
# - you have no other EAP 6/AS 7 processes running
# - JBOSS_HOME and JAVA_HOME are properly set

if [ "x$JBOSS_HOME" = "x" ]; then
  echo "Must set JBOSS_HOME"
  exit 1
fi

if [ "x$JAVA_HOME" = "x" ]; then
  echo "Must set JAVA_HOME"
  exit 1
fi

CURRENT_DIR=`pwd`
BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

cd $BASE_DIR
ant -f bin/keytool-build.xml setup-example-two-way-ssl

mvn install

echo "Copying jbossweb.keystore"
cp src/main/resources/jbossweb.keystore $JBOSS_HOME/standalone/configuration

if [ $? -gt 0 ]; then
  exit $?
fi

echo "Starting JBoss..."
$JBOSS_HOME/bin/standalone.sh -Djavax.net.debug=ssl,handshake > server.log &
sleep 5
echo "Adding HTTPS connector..."
$JBOSS_HOME/bin/jboss-cli.sh -c --file=bin/installHttps.cli

mvn jboss-as:deploy
curl -s -H "Content-Type: text/xml" -d @bin/request.xml http://localhost:8080/cxfSsl/clientEndpoint | xmllint --format -
echo

echo "Removing HTTPS connector..."
$JBOSS_HOME/bin/jboss-cli.sh -c --file=bin/uninstallHttps.cli
echo "Stopping JBoss..."
kill `jps | grep "jboss-modules.jar" | cut -f 1 -d " "`

#Clean things up so this script can be re-run more easily
rm src/main/resources/jbossweb.keystore* src/main/resources/client.keystore*

cd $CURRENT_DIR
