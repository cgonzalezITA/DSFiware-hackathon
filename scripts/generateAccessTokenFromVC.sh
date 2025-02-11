#!/bin/bash
#********************************************************************************
# fiwaredsc.ita.es
# Version: 1.0.0 
# Copyright (c) 2024 Instituto Tecnologico de Aragon (www.ita.es)
# Date: October 2024
# Authors: 
#          Carlos Gonzalez Muñoz                    cgonzalez@ita.es
# Script based on steps described on https://github.com/FIWARE/data-space-connector/blob/main/doc/deployment-integration/local-deployment/LOCAL.MD
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
VERIFIABLE_CREDENTIAL=""
# [-surl | --serviceUrl] URL base of the OIDC server (def. https://fiwaredsc-provider.local/services/hackathon-service/)
SERVICE_URL=https://fiwaredsc-provider.local/services/hackathon-service
# \t-cf | --certificatesFolder: Folder with the certificates used to sign the VP. Def. './.tmpVPCerts' \n"
CERT_FOLDER=./.tmp/VPCerts
PRIVATEKEY_FILE=private-key.pem
PUBLICKEY_FILE=public-key.pem
STOREPASSWORD_LENGTH="128"
# $(openssl rand -base64 "$STOREPASSWORD_LENGTH" | tr -dc 'a-zA-Z0-9' | head -c "$STOREPASSWORD_LENGTH")
STOREPASSWORD="hello" 
# \t-s | --scope: Scope of the requested Access Token \n"
SCOPE=operator
PFX_ALIAS=alias
# \t-t | --test | -i | --info: Just shows the values that are going to be used \n"
TEST=false
#############################
## Functions               ##
#############################
function help() {
    HELP=""
    if test "$#" -ge 1; then
        HELP=$1
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <verifiableCredentialToBeEmbeddedIntoAVerifiablePresentation> \n\
            \t[-h  | --help]: Prints help\n\
            \t[-t  | --test | -i | --info]: Just shows the values that are going to be used \n\
            \t[-v  | --verbose]: Does not show verbose info\n\
            \t[-s  | --stop]: Stops after each command is run\n\
            \t[-cf | --certificatesFolder]: Folder with the certificates used to sign the VP. Def. './.tmpVPCerts' \n
            \t[-oidc | --oidcUrl] URL base of the OIDC server (def. https://fiwaredsc-oidc.ita.es) \n
            \t[-s | --scope]: Scope of the requested Access Token"
    echo $HELP
}
function runCommand() { #CMD, [#Message], VERBOSERC
    [ "$VERBOSE" = true ] && echo > /dev/tty;
    FORMAT="runCommand <CMD> [<Debug message to be printed out>]"
    if test "$#" -lt 1; then
        echo -e "Error: Missing <CMD>:\n\t$FORMAT" > /dev/tty;
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
    CMD=$1; shift;
    MSG=""
    if test "$#" -ge 1; then
        MSG=$1; shift;
    fi

    [ "$VERBOSE" = true ] && echo -e "$MSG" > /dev/tty;
    # [ "$VERBOSE" = true ] && echo -e "Command [$CMD] is going to be run:" > /dev/tty;
    VAR=$(eval $CMD)
    RC=$?
    if test "$RC" -ne 0; then
        echo "ERROR [$RC] running command [$CMD]" > /dev/tty; 
    else 
        echo $VAR
        return 0
    fi
    [ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;
}



##############################
## Main code                ##
##############################
# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -s | --stop ) 
            STOP=true; shift ;;
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;;
        -t  | --test | -i | --info )
            # \t[-t  | --test | -i | --info]: Just shows the values that are going to be used \n\
            TEST=true; shift;;
        -cf | --certificatesFolder )
            # \t-cf | --certificatesFolder: Folder with the certificates used to sign the VP. Def. './.tmpVPCerts' \n"
            CERT_FOLDER=$2; shift; shift;;
        -oidc | --oidcUrl )
            # \t[-surl | --serviceUrl] URL base of the OIDC server (def. https://fiwaredsc-provider.local/services/hackathon-service/)
            SERVICE_URL=$2; shift; shift;;
        -s | --scope )
            # \t-s | --scope: Scope of the requested Access Token \n"
            SCOPE=$2; shift; shift;;
        * )             
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#VERIFIABLE_CREDENTIAL}" -eq 0; then
                VERIFIABLE_CREDENTIAL=$1
                shift;
            else
                shift;
            fi ;;
    esac
done

if test "${#VERIFIABLE_CREDENTIAL}" -eq 0 && [ "$TEST" == false ]; then
    echo -e $(help "ERROR: No VERIFIABLE_CREDENTIAL has been provided");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
###########
# Main flow
###########
if [ "$VERBOSE" = true ]; then
    echo "INFO: EXECUTING SCRIPT [$SCRIPTNAME]:" > /dev/tty
    echo "VERBOSE=[$VERBOSE]" > /dev/tty
    echo "TEST=[$TEST]" > /dev/tty
    echo "PAUSE=[$STOP]" > /dev/tty
    echo "VERIFIABLE_CREDENTIAL=${VERIFIABLE_CREDENTIAL: 0:10}..${VERIFIABLE_CREDENTIAL: -10}" > /dev/tty
    echo "SERVICE_URL=$SERVICE_URL" > /dev/tty
    echo "CERT_FOLDER=${CERT_FOLDER}" > /dev/tty
    echo "PRIVATEKEY_FILE=$PRIVATEKEY_FILE" > /dev/tty
    echo "PUBLICKEY_FILE=$PUBLICKEY_FILE" > /dev/tty
    echo "STOREPASSWORD_LENGTH=$STOREPASSWORD_LENGTH" > /dev/tty
    # echo "STOREPASSWORD=${STOREPASSWORD: 0:10}..${STOREPASSWORD: -10}" > /dev/tty
    echo "ACCESSTOKEN_SCOPE=$SCOPE" > /dev/tty
    echo "---" > /dev/tty
fi
[ "$STOP" = true ] && read -p "Press a key to start" || sleep 1;

# echo "Phase 1- Authenticate via OID4VP (OpenID for Verifiable Presentations) is a protocol extension that allows holders of verifiable credentials to authenticate and present them securely to verifiers, using the OpenID Connect framework."
# MSG="---\n1.1- Retrieve the access token from the OIDC (OpenID Connect) well-known endpoint. OIDC is an identity authentication protocol, an extension of open authorization (OAuth) 2.0 to standardize the process for authenticating and authorizing users when they sign in to access digital services."
OIDC_URL_WELLKNOWN="$SERVICE_URL/.well-known/openid-configuration"
CMD="curl -k -s -X GET $OIDC_URL_WELLKNOWN | jq -r '.token_endpoint'"
OIDC_ACCESSTOKEN_URL=$(runCommand "$CMD")
RC=$?
if [ "$RC" -ne 0 ]; then
    echo -e $(help "ERROR: Access to '$OIDC_URL_WELLKNOWN' returned code RC=$RC");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ ${#OIDC_ACCESSTOKEN_URL} -eq 0 ] || [ "${OIDC_ACCESSTOKEN_URL}" == "null" ]; then
    echo -e $(help "ERROR: Invalid OIDC_ACCESSTOKEN_URL retrieved from '$OIDC_URL_WELLKNOWN': $OIDC_ACCESSTOKEN_URL");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$VERBOSE" = true ]; then
    echo "OIDC_URL_WELLKNOWN=[$OIDC_URL_WELLKNOWN]" > /dev/tty
    echo "OIDC_ACCESSTOKEN_URL=[$OIDC_ACCESSTOKEN_URL]" > /dev/tty
    echo '---' > /dev/tty
fi
if [ "$TEST" == true ]; then
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
[ "$STOP" = true ] && read -p "Press a key to start" || sleep 1;

[ "$VERBOSE" = true ] && echo "Generating Certificates to sign the Verifiable Presentation" > /dev/tty
# Taken from https://github.com/wistefan/did-helper/tree/main
# Create P-256 Key and Certificate
# In order to provide a did:key of type P-256, first a key and certificate needs to be created
# generate the private key - dont get confused about the curve, openssl uses the name `prime256v1` for `secp256r1`(as defined by P-256)
mkdir -p $CERT_FOLDER
openssl ecparam -name prime256v1 -genkey -noout -out $CERT_FOLDER/$PRIVATEKEY_FILE > /dev/null 2>&1
# generate corresponding public key
openssl ec -in $CERT_FOLDER/$PRIVATEKEY_FILE -pubout -out $CERT_FOLDER/$PUBLICKEY_FILE > /dev/null 2>&1
# create a (self-signed) certificate
openssl req -new -x509 -key $CERT_FOLDER/$PRIVATEKEY_FILE -out $CERT_FOLDER/cert.pem -days 360 -subj "/C=ES/ST=Aragon/L=Zaragoza/O=ITA/CN=www.ita.es" > /dev/null
# export the keystore
openssl pkcs12 -export -inkey $CERT_FOLDER/$PRIVATEKEY_FILE -in $CERT_FOLDER/cert.pem -out $CERT_FOLDER/cert.pfx -name $PFX_ALIAS -passout pass:hello > /dev/null
# Opens the permissions
sudo chown $(id -u):$(id -g) $CERT_FOLDER -R
chmod 777 $CERT_FOLDER -R

[ "$VERBOSE" = true ] && echo "- Certificates to sign the DID generated at '$CERT_FOLDER' folder." > /dev/tty
# check the contents
# keytool -v -keystore $CERT_FOLDER/cert.pfx -list -alias $PFX_ALIAS --storepass hello
[ "$VERBOSE" = true ] && echo "- Generating did at '$CERT_FOLDER' folder." > /dev/tty
# docker run -v $CERT_FOLDER:/cert -e STORE_PASS=hello quay.io/wi_stefan/did-helper:0.1.1 > /dev/null 2>&1
cat <<EOF > $CERT_FOLDER/job-generatedid.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: job-generatedid
spec:
  ttlSecondsAfterFinished: 15
  backoffLimit: 0
  template:
    spec:
      containers:
      - name: my-container
        image: quay.io/wi_stefan/did-helper:0.1.1
        volumeMounts:
        - mountPath: /cert
          name: tmp-volume
        env:
        - name: STORE_PASS
          value: hello
      restartPolicy: Never
      volumes:
      - name: tmp-volume
        hostPath:
          path: $(pwd)/$CERT_FOLDER
          type: Directory
EOF

kubectl apply -f $CERT_FOLDER/job-generatedid.yaml > /dev/null
kubectl wait --for=condition=complete --timeout=300s job/job-generatedid > /dev/tty
CMD="cat $CERT_FOLDER/did.json | jq '.id' -r"
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

HOLDER_DID=$(runCommand "$CMD")
[ "$VERBOSE" = true ] && echo "- DID [$HOLDER_DID] to sign the Verifiable Presentation generated" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue with the VP creation" || sleep 1;


[ "$VERBOSE" = true ]&& echo -e "---\n- Generate a VerifiablePresentation, containing the Verifiable Credential:" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;
export VERIFIABLE_PRESENTATION_TEMPLATE="{
    \"@context\": [\"https://www.w3.org/2018/credentials/v1\"],
    \"type\": [\"VerifiablePresentation\"],
    \"verifiableCredential\": [
        \"${VERIFIABLE_CREDENTIAL}\"
    ],
    \"holder\": \"${HOLDER_DID}\"
  }"; 

[ "$VERBOSE" = true ]&& echo -e "\t1- Setup the header:" > /dev/tty
export JWT_HEADER=$(echo -n "{\"alg\":\"ES256\", \"typ\":\"JWT\", \"kid\":\"${HOLDER_DID}\"}"| base64 -w0 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//); 
[ "$VERBOSE" = true ]&& echo "Header: ${JWT_HEADER}" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

[ "$VERBOSE" = true ]&& echo -e "\t2- Setup the payload:" > /dev/tty
export PAYLOAD=$(echo -n "{\"iss\": \"${HOLDER_DID}\", \"sub\": \"${HOLDER_DID}\", \"vp\": ${VERIFIABLE_PRESENTATION_TEMPLATE}}" | base64 -w0 | sed s/\+/-/g |sed 's/\//_/g' |  sed -E s/=+$//); 
[ "$VERBOSE" = true ]&& echo "Payload: ${PAYLOAD}" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

[ "$VERBOSE" = true ]&& echo -e "\t3- Create the signature:" > /dev/tty
# echo echo -n "${JWT_HEADER}.${PAYLOAD}" > /dev/tty
export SIGNATURE=$(echo -n "${JWT_HEADER}.${PAYLOAD}" | openssl dgst -sha256 -binary -sign $CERT_FOLDER/$PRIVATEKEY_FILE | base64 -w0 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//); 
[ "$VERBOSE" = true ]&& echo "Signature: ${SIGNATURE}" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

[ "$VERBOSE" = true ]&& echo -e "\t4- Combine them to generate the JWT:" > /dev/tty
export VP_JWT="${JWT_HEADER}.${PAYLOAD}.${SIGNATURE}"; 
[ "$VERBOSE" = true ]&& echo "VP_JWT: ${VP_JWT}" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

[ "$VERBOSE" = true ]&& echo -e "\t5- The VP_JWT representation of the VP_JWT has to be Base64-encoded(no padding!) (This is not a JWT):" > /dev/tty
export VP_TOKEN=$(echo -n ${VP_JWT} | base64 -w0 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//); 
[ "$VERBOSE" = true ] && echo "VP_TOKEN=$VP_TOKEN" > /dev/tty

# [ "$VERBOSE" = true ]&& echo -e "\tCheck- The VP_TOKEN is recovered to check it is correct" > /dev/tty
# RECOVERED_JWT=$(echo -n "${VP_TOKEN}" | sed 's/-/+/g' | sed 's/_/\//g' | sed -E 's/.{0,2}$/&==/' | base64 -d)
# [ "$VERBOSE" = true ] && echo "RECOVERED_JWT=$RECOVERED_JWT" > /dev/tty
# [ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

MSG="---\nNext step asks for an access token to be used to request the service (This is a JWT)"
[ "$VERBOSE" = true ] && echo -e "$MSG" > /dev/tty
[ "$STOP" = true ] && read -p "Press Enter to continue" || sleep 1;

# CMD="curl -k -s -X POST $OIDC_ACCESSTOKEN_URL \
#       --header 'Accept: */*' \
#       --header 'Content-Type: application/x-www-form-urlencoded' \
#       --data grant_type=vp_token \
#       --data scope=$SCOPE\
#       --data vp_token=$VP_TOKEN";
# echo "Running command [$CMD]"
# JSON_DATA_SERVICE_ACCESS_TOKEN=$($CMD)
DATA_SERVICE_ACCESS_TOKEN=$(curl -k -s -X POST $OIDC_ACCESSTOKEN_URL \
      --header 'Accept: */*' \
      --header 'Content-Type: application/x-www-form-urlencoded' \
      --data grant_type=vp_token \
      --data scope=$SCOPE\
      --data vp_token=$VP_TOKEN | jq -r '.access_token')
[ "$VERBOSE" = true ] && echo -e "DATA_SERVICE_ACCESS_TOKEN=$DATA_SERVICE_ACCESS_TOKEN" > /dev/tty
echo $DATA_SERVICE_ACCESS_TOKEN