# Confluent Community Edition with SSL and ACL

Based on the docker-compose file in Confluent's [cp-all-in-one-community demo](https://github.com/confluentinc/cp-all-in-one/tree/5.5.1-post/cp-all-in-one-community)

Partly followed reciepes in

* [Demo: Securing Communication Between Clients and Brokers Using SSL](https://jaceklaskowski.gitbooks.io/apache-kafka/content/kafka-demo-securing-communication-between-clients-and-brokers.html)
* [Demo: Secure Inter-Broker Communication](https://jaceklaskowski.gitbooks.io/apache-kafka/content/kafka-demo-secure-inter-broker-communication.html)
* [Demo: SSL Authentication](https://jaceklaskowski.gitbooks.io/apache-kafka/content/kafka-demo-ssl-authentication.html)
* [Demo: ACL Authorization](https://jaceklaskowski.gitbooks.io/apache-kafka/content/kafka-demo-acl-authorization.html)

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

No changes.

### broker



### schema-registry

No changes. Not tested.

### connect

No changes. Not tested.

### ksqldb-server

No changes. Not tested.

### ksqldb-cli

No changes. Not tested.

### ksql-datagen

No changes. Not tested.

### rest-proxy

No changes. Not tested.

