#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

#---------------------------------------------- main program ------------------------
echo "##############################"
echo "# Install the DSFiware-hackathon github repository"
DSFIWAREHOL_GH_HTTPS="https://github.com/cgonzalezITA/DSFiware-hackathon.git"
DSFIWAREHOL_TAG="phase01.step01"
DSFIWAREHOL_FOLDER="DSFiware-hackathon-$DSFIWAREHOL_TAG"
REPLY='y'
if [[ -d $DSFIWAREHOL_FOLDER ]]; then
    REPLY=$(readAnswer  "Folder $DSFIWAREHOL_FOLDER already exists. Do you want to delete it to reinstall the DSFiware-hackathon git? (Y|n*)" \
        'n');
    [[ $REPLY == 'y' ]] && sudo rm -r $DSFIWAREHOL_FOLDER;
fi
if [[ $REPLY == 'y' ]]; then
    CMD="git clone $DSFIWAREHOL_GH_HTTPS $DSFIWAREHOL_FOLDER -b $DSFIWAREHOL_TAG"
    echo "Running CMD=$CMD"
    bash -c "$CMD"
fi

echo "# $DSFIWAREHOL_TAG-Deploying a basic version of a helloWorld chart"
NAMESPACE="apisix"
ARTIFACT=ns
# createArtifact <namespace> <artifact> <artifactClue> <create_cmd>\
#                   <deleteIfExists> (true)
createArtifact $NAMESPACE $ARTIFACT $NAMESPACE "kubectl create $ARTIFACT $NAMESPACE" true

echo "# Creating a tls secret"
mkdir -p Helms/apisix/.certs 
CERT_KEY=Helms/apisix/.certs/tls-wildcard.key
CERT_PUB=Helms/apisix/.certs/tls-wildcard.crt
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERT_KEY -out $CERT_PUB -subj "/CN=*.local"

ARTIFACT=secret
ARTIFACT_NAME=wildcardlocal-tls
createArtifact $NAMESPACE $ARTIFACT $ARTIFACT_NAME \
    "kubectl create $ARTIFACT tls $ARTIFACT_NAME -n $NAMESPACE --key $CERT_KEY --cert $CERT_PUB"
    true

echo "# Registers the fiwaredsc-consumer.local at the /etc/hosts file to map the DNS with the IP address"
PUBLIC_IP=$(hostname -I | awk '{print $1}')
DNS_CONSUMER="fiwaredsc-consumer.local"
LINE="$PUBLIC_IP  $DNS_CONSUMER"
echo "# Map the local DNS at your hosts file"
MSG="# To use the DNS $DNS_CONSUMER at the host, it is required to add a new line \"$LINE\" to the '/etc/hosts' file.\n\
Do you want to insert it automatically?";
if [ $(readAnswer "$MSG (y|n*)" 'n') == 'y' ]; then
    sudo cat <<EOF >> /etc/hosts
$LINE
EOF
    if [[ "$?" -ne 0 ]]; then
        readAnswer "An error has happened. This operation requires sudo permission. Do it manually on another terminal and press any key to continue" \
            "" 120 false false
    fi
fi
readAnswer "To access it from a windows browser, add the same line into the 'C:\Windows\System32\drivers\etc\hosts' file\n\
    Press a key to continue" "" 10 false false


echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"
mkdir -p .tmp 

echo "# Deploying the apisix helm..."
ARTIFACT_NAME=apisix
hFileCommand $ARTIFACT_NAME -y -b restart >.tmp/quickInstall.log
readAnswer "On the next screen wait until all the artifacts are properly deployed (1/1)  then press Ctrl+C and the process will continue" "" 5
kGet -w -v -n $NAMESPACE

CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_CONSUMER"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of phase01.step01. Congrats!"
    readAnswer "Now you can try it running command \"curl -k https://$DNS_CONSUMER\"" 5
else
    echo "It seems that something has failed (RC=$RC). Review the process step by step reading the documentation"
fi
echo "Script $SCRIPTNAME has finished"
cd ..