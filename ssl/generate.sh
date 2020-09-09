#!/bin/bash

if test \! -x ./generate.sh
then
  echo "must be run from the ssl directory"
  exit 1
fi
if test -z "$(command -v openssl)" -o -z "$(command -v keytool)"
then
  echo "Need openssl and (Java) keytool commands."
  exit 1
fi

PASS="foobar"
USERS="broker client superuser" # Will be signed by trusted CA
BAD_USER="bad"                  # Certificate that is not signed by the trusted CA
KEYSTORE_EXT="keystore.p12"
TRUSTSTORE_EXT="truststore.p12"
VALIDITY_DAYS="3650"

echo "$PASS" > password.txt

if test \! -f ca.crt
then
    echo "No ca.crt found. Generating one."
    openssl req -new -x509 -days "$VALIDITY_DAYS" -keyout ca.key -out ca.crt -subj "/C=NO/CN=CA" -passout "pass:$PASS"
    keytool -import -file ca.crt -keystore "$TRUSTSTORE_EXT" -storetype pkcs12 -alias ca -storepass "$PASS" -noprompt
    for USER in $USERS
    do
	rm -f "$USER.$KEYSTORE_EXT"
    done
fi

for USER in $USERS
do
    if test \! -f "$USER.$KEYSTORE_EXT"
    then
	echo "Generating for $USER"
	keytool -genkey -keystore "$USER.$KEYSTORE_EXT" -deststoretype pkcs12 -storepass "$PASS" -alias "$USER" -dname CN="$USER" -keyalg RSA -validity "$VALIDITY_DAYS" -keypass "$PASS"
	keytool -certreq -keystore "$USER.$KEYSTORE_EXT" -alias "$USER" -file "$USER.unsigned.crt" -storepass "$PASS"
	openssl x509 -req -CA ca.crt -CAkey ca.key -in "$USER.unsigned.crt" -out "$USER.crt" -days "$VALIDITY_DAYS" -CAcreateserial -passin "pass:$PASS"
	keytool -import -file ca.crt -keystore "$USER.$KEYSTORE_EXT" -alias ca -storepass "$PASS" -noprompt
	keytool -import -file "$USER.crt" -keystore "$USER.$KEYSTORE_EXT" -alias "$USER" -storepass "$PASS" -noprompt
	rm ca.srl "$USER.crt" "$USER.unsigned.crt"
    fi
done

if test \! -f "$BAD_USER.$KEYSTORE_EXT"
then
  keytool -genkey -keystore "$BAD_USER.$KEYSTORE_EXT" -deststoretype pkcs12 -storepass "$PASS" -alias "$BAD_USER" -dname CN="$BAD_USER" -keyalg RSA -validity "$VALIDITY_DAYS" -keypass "$PASS"
fi

for USER in $USERS $BAD_USER
do
  cp "$TRUSTSTORE_EXT" "$USER.$TRUSTSTORE_EXT"
  cat <<EOT > "$USER.properties"
security.protocol=SSL
ssl.keystore.location=$USER.$KEYSTORE_EXT
ssl.keystore.password=$PASS
ssl.key.password=$PASS
ssl.truststore.location=$USER.$TRUSTSTORE_EXT
ssl.truststore.password=$PASS
EOT
done
