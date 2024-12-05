#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

unset DID1
#---------------------------------------------- main program ------------------------
echo "##############################"
echo "# Install the DSFiware-hackathon github repository"
DSFIWAREHOL_GH_HTTPS="https://github.com/cgonzalezITA/DSFiware-hackathon.git"
DSFIWAREHOL_TAG="phase02.step01" # TODO set phase03.step01
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

echo "# $DSFIWAREHOL_TAG-Deployment of the DID:key and DID:web"
NAMESPACE="consumer"

DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"


echo "# Deploy the did:key"
hFileCommand consumer -f key r -v -y
wait4PodsDeploymentCompleted $NAMESPACE 20

echo "# Verification"
DID1=$(kExec net -v -n $NAMESPACE -- curl -s http://did:3000/did-material/did.env)
RC=$?
echo ""
if [ "${DID1:0:3}" == "DID" ]; then
    readAnswer "DID:KEY has worked! The generated DID:key is $DID1. Congrats!" "" 15 false
else
    readAnswer "DID:KEY has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi



unset DID1
echo "# Deploy the did:web"
hFileCommand consumer -f web r -v -y

wait4PodsDeploymentCompleted $NAMESPACE 20

echo "# Verification"
DID1=$(kExec net -v -n $NAMESPACE -- curl -s http://did:3000/did-material/did.env)
RC=$?
echo ""
if [ "${DID1:0:3}" == "DID" ]; then
    echo "DID:WEB has worked! The generated DID:key is $DID1. Congrats!"
else
    echo "DID:WEB has failed (RC=$RC). Review the logs and the value file used by helm for some clues"
fi


echo "Script $SCRIPTNAME has finished"
cd ..