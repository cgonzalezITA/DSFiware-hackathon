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
    CMD="git clone $DSFIWAREHOL_GH_HTTPS $DSFIWAREHOL_FOLDER -b $DSFIWAREHOL_TAG > /dev/null 2>&1"
    echo "Running CMD=$CMD"
    bash -c "$CMD"
fi

echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

echo "# Removes previously existing apisix namespace"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 

echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20

echo "# Creating a tls secret"
mkdir -p Helms/apisix/.certs 
CERT_KEY=Helms/apisix/.certs/tls-wildcard.key
CERT_PUB=Helms/apisix/.certs/tls-wildcard.crt
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERT_KEY -out $CERT_PUB -subj "/CN=*.local" > /dev/null 2>&1

ARTIFACT=secret
ARTIFACT_NAME=wildcardlocal-tls
createArtifact $NAMESPACE $ARTIFACT $ARTIFACT_NAME \
    "kubectl create $ARTIFACT tls $ARTIFACT_NAME -n $NAMESPACE --key $CERT_KEY --cert $CERT_PUB"
    true > /dev/null 2>&1


echo -e "\n\n#### Final Verification"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_CONSUMER"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of phase01.step01. Congrats!"
    readAnswer "Now you can try it running command \"curl -k https://$DNS_CONSUMER\"" 5
    echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
    \t-The Kubernetes cluster is properly deployed
    \t-The ingress component is properly managing the https port (443)
    \t-Helm is also working as it has deployed the echo components"
else
    echo "It seems that something has failed (RC=$RC). Review the process step by step reading the documentation"
fi

echo "Script $SCRIPTNAME has finished"
cd ..