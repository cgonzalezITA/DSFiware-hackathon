#!/bin/bash
# Script based on steps described on https://github.com/FIWARE/data-space-connector/blob/main/doc/deployment-integration/local-deployment/LOCAL.MD
############################
## Variable Initialization #
############################
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")

VERBOSE=true
STOP=false
#############################
## Functions               ##
#############################

URL_VCISSUER=https://fiwaredsc-consumer.local/realms/consumerRealm
# https://fiwaredsc-consumer.local/realms/consumerRealm/account/oid4vci to retrieve the equivalent from a browser using a VCWallet
ADMIN_CLI=admin-cli
USER_01=op-user
USER_01_PASSWORD=test
CREDENTIAL_TYPE=operator-credential

VERIFIABLE_CREDENTIAL=$($BASEDIR/_issueVC.sh --vcIssuer $URL_VCISSUER --user $USER_01 --password $USER_01_PASSWORD --credentialType $CREDENTIAL_TYPE $@)
# echo VERIFIABLE_CREDENTIAL=$VERIFIABLE_CREDENTIAL > /dev/tty
echo $VERIFIABLE_CREDENTIAL