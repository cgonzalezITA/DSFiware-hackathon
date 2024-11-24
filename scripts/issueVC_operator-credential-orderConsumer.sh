#!/bin/bash
#********************************************************************************
# fiwaredsc.ita.es
# Version: 1.0.0 
# Copyright (c) 2024 Instituto Tecnologico de Aragon (www.ita.es)
# Date: October 2024
# Authors: 
#          Carlos Gonzalez Muñoz                    cgonzalez@ita.es
# All rights reserved 
#********************************************************************************
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

URL_VCISSUER=https://fiwaredsc-consumer.ita.es/realms/consumerRealm
# https://fiwaredsc-consumer.ita.es/realms/consumerRealm/account/oid4vci to retrieve the equivalent from a browser using a VCWallet
ADMIN_CLI=admin-cli
USER_01=oc-user
USER_01_PASSWORD=test
CREDENTIAL_TYPE=operator-credential

$BASEDIR/_retrieveVC.sh --vcIssuer $URL_VCISSUER --user $USER_01 --password $USER_01_PASSWORD --credentialType $CREDENTIAL_TYPE $@