# Confluent Community Edition with SSL and ACL

Based on the docker-compose file in Confluent's
[cp-all-in-one-community demo](https://github.com/confluentinc/cp-all-in-one/tree/5.5.1-post/cp-all-in-one-community)

## The `./ssl` directory

Before doing anything for the first time, execute
```
$ cd ssl
$ ./generate.sh
$ cd ..
```
This will build a self-signed CA, and certificates for users "broker", "client",
"superuser" and "bad". The latter certificate is self-signed and thus unknown
to Kafka. The others are signed by the CA created initially. For every user
there will be three files:

| File                   | Usage |
|------------------------|-------|
| `$USER.keystore.p12`   | The key store for the user, containing the private key. |
| `$USER.truststore.p12` | The trust store to be used by the user. Currently all trust stores are identical, containing only the CA certificate. |
| `$USER.properties`     | A file that can be used on the command line to set up SSL properties for Kafka command line programs. File references are relative to the current directory, so the command must be run from the directory containing all the generated SSL files. Eg. `kafka-acls --command-config superuser.properties ...` |

Every key store/key password will be `foobar`, unless changed in `generate.sh`.

The "broker" and "superuser" users are defined as `KAFKA_SUPER_USERS` on the broker,
thus having all rights.

The "client" user has no ACL rights, but will be recognized as a user, and may
be assigned new rights using ACLs.

The "bad" user should not be able to do anything.

If you need more users, add them to the `USERS` variable in the `generate.sh` script and run it again.
 
## Changes made to the original docker-compose.yml

All containers get the `./ssl` directory mounted as `/etc/kafka/secrets`.

### zookeeper

No changes yet.

### broker

* Added SSL exposed ports, and removed non-SSL
```
    ports:
      - "29093:29093"
      - "9093:9093"
```

* Added SSL listeners, and removed non-SSL
```
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL_SSL:SSL,SSL:SSL
      KAFKA_ADVERTISED_LISTENERS: SSL://broker:9093,INTERNAL_SSL://broker:29093
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL_SSL
```

* Set up SSL, including required SSL for clients (filenames are relative to `/etc/kafka/secrets`)
```
      KAFKA_SSL_KEYSTORE_FILENAME: broker.keystore.p12
      KAFKA_SSL_KEYSTORE_CREDENTIALS: password.txt
      KAFKA_SSL_KEY_CREDENTIALS: password.txt
      KAFKA_SSL_TRUSTSTORE_FILENAME: broker.truststore.p12
      KAFKA_SSL_TRUSTSTORE_CREDENTIALS: password.txt
      KAFKA_SSL_CLIENT_AUTH: required
```

* Set up ACL for authorization, including super users to circumvent it
```
      KAFKA_AUTHORIZER_CLASS_NAME: kafka.security.authorizer.AclAuthorizer
      KAFKA_SUPER_USERS: User:CN=broker;User:CN=superuser
```

### schema-registry

No changes yet.

### connect

No changes. Not tested.

### openlap

Added this container from the extended
[Confluent cp-demo](https://github.com/confluentinc/cp-demo). The directory
will be populated from files in `./config/ldap/ldap_users`, which is a
trimmed-down version of the list from cp-demo.

### ksqldb-server, ksqldb-cli, ksql-datagen, rest-proxy

Thes containers were removed.

## Example commands

### Add ACL, and list ACLs
```
$ docker-compose exec broker bash
root@broker:/# cd /etc/kafka/secrets/
root@broker:/etc/kafka/secrets# kafka-acls --bootstrap-server broker:9093 --command-config superuser.properties --add --topic test --group test --allow-principal User:CN=client
root@broker:/etc/kafka/secrets# kafka-acls --bootstrap-server broker:9093 --command-config superuser.properties --list
```
