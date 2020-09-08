#!/bin/bash

if test \! -x ./generate.sh
then
  echo "must be run from the ssl directory"
  exit 1
fi

PASS="foobar"
USERS="broker"
KEYSTORE_EXT="keystore.p12"
TRUSTSTORE_EXT="truststore.p12"

echo "$PASS" > password.txt

if test \! -f ca.crt
then
    echo "No ca.crt found. Generating one."
    openssl req -new -x509 -days 3650 -keyout ca.key -out ca.crt -subj "/C=NO/CN=CA" -passout "pass:$PASS"
    keytool -import -file ca.crt -keystore "$TRUSTSTORE_EXT" -alias ca -storepass "$PASS" -noprompt
    for USER in $USERS
    do
	rm -f "$USER.$KEYSTORE_EXT"
	cp "$TRUSTSTORE_EXT" "$USER.$TRUSTSTORE_EXT"
    done
fi

for USER in $USERS
do
    if test \! -f "$USER.$KEYSTORE_EXT"
    then
	echo "Generating for $USER"
	keytool -genkey -keystore "$USER.$KEYSTORE_EXT" -deststoretype pkcs12 -storepass "$PASS" -alias "$USER" -dname CN="$USER" -keyalg RSA -validity 365 -keypass "$PASS"
	keytool -certreq -keystore "$USER.$KEYSTORE_EXT" -alias "$USER" -file "$USER.unsigned.crt" -storepass "$PASS"
	openssl x509 -req -CA ca.crt -CAkey ca.key -in "$USER.unsigned.crt" -out "$USER.crt" -days 3650 -CAcreateserial -passin "pass:$PASS"
	keytool -import -file ca.crt -keystore "$USER.$KEYSTORE_EXT" -alias ca -storepass "$PASS" -noprompt
	keytool -import -file "$USER.crt" -keystore "$USER.$KEYSTORE_EXT" -alias "$USER" -storepass "$PASS" -noprompt
	rm ca.srl "$USER.crt" "$USER.unsigned.crt"
    fi
done
