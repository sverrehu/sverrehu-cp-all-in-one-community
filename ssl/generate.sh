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
    keytool -import -file ca.crt -keystore truststore.p12 -alias ca -storepass "$PASS" -noprompt
    for USER in $USERS
    do
	rm -f "$USER.p12"
    done
fi
for USER in $USERS
do
    mkdir -p ../volumes/$USER/etc/kafka/secrets/ >/dev/null 2>&1
    echo "$PASS" > ../volumes/$USER/etc/kafka/secrets/password.txt
    cp truststore.p12 ../volumes/$USER/etc/kafka/secrets/
done

for USER in $USERS
do
    if test \! -f "$USER.p12"
    then
	echo "Generating for $USER"
	keytool -genkey -keystore "$USER.p12" -deststoretype pkcs12 -storepass "$PASS" -alias "$USER" -dname CN="$USER" -keyalg RSA -validity 365 -keypass "$PASS"
	keytool -certreq -keystore "$USER.p12" -alias "$USER" -file "$USER.unsigned.crt" -storepass "$PASS"
	openssl x509 -req -CA ca.crt -CAkey ca.key -in "$USER.unsigned.crt" -out "$USER.crt" -days 3650 -CAcreateserial -passin "pass:$PASS"
	keytool -import -file ca.crt -keystore "$USER.p12" -alias ca -storepass "$PASS" -noprompt
	keytool -import -file "$USER.crt" -keystore "$USER.p12" -alias "$USER" -storepass "$PASS" -noprompt
	rm ca.srl "$USER.crt" "$USER.unsigned.crt"
    fi
    cp "$USER.p12" ../volumes/$USER/etc/kafka/secrets/
done
