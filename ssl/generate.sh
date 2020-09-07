#!/bin/bash

if test \! -x ./generate.sh
then
  echo "must be run from the ssl directory"
  exit 1
fi

PASS="foobar"
USERS="broker"

if test \! -f ca.crt
then
    echo "No ca.crt found. Generating one."
    openssl req -new -x509 -days 3650 -keyout ca.key -out ca.crt -subj "/C=NO/CN=CA" -passout "pass:$PASS"
    for USER in $USERS
    do
	rm -f "$USER.p12"
    done
fi

for USER in $USERS
do
    echo "Generating for $USER"
    keytool -genkey -keystore "$USER.p12" -deststoretype pkcs12 -storepass "$PASS" -alias localhost -dname CN=localhost -keyalg RSA -validity 365 -ext san=dns:localhost -keypass "$PASS"
done
