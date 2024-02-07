```
       ____                  __          ____          .-.
      / __ \____  _____ ____/ /_  ____  / / /_    .--./ /      _.---.,
     / /_/ / __ `/ ___/ ___/ __ \/ __ \/ / __/     '-,  (__..-`       \
    / ____/ /_/ (__  |__  ) /_/ / /_/ / / /_          \                |
   /_/    \__,_/____/____/_,___/\____/_/\__/           `,.__.   ^___.-/
                                                         `-./ .'...--`
  The open source password manager for teams                `'
  (c) 2023 Cipherguard SA
  https://www.cipherguard.khulnasoft.com
```
[![Docker Pulls](https://img.shields.io/docker/pulls/khulnasoft/cipherguard.svg?style=flat-square)](https://hub.docker.com/r/khulnasoft/cipherguard/tags/)
[![GitHub release](https://img.shields.io/github/release/khulnasoft/cipherguard_docker.svg?style=flat-square)](https://github.com/khulnasoft/cipherguard_docker/releases)
[![license](https://img.shields.io/github/license/khulnasoft/cipherguard_docker.svg?style=flat-square)](https://github.com/khulnasoft/cipherguard_docker/LICENSE)
[![Twitter Follow](https://img.shields.io/twitter/follow/cipherguard.svg?style=social&label=Follow)](https://twitter.com/cipherguard)

# What is cipherguard?

Cipherguard is a free and open source password manager that allows team members to
store and share credentials securely.

# Requirements

* rng-tools or haveged might be required on host machine to speed up entropy generation on containers.
This way gpg key creation on cipherguard container will be faster.
* mariadb/mysql >= 5.0

# Usage

### docker-compose

Usage:

```
$ docker-compose -f docker-compose/docker-compose-ce.yaml up
```

Users are encouraged to use [official docker image from the docker hub](https://hub.docker.com/r/khulnasoft/cipherguard/).

## Start cipherguard instance

Cipherguard requires mysql to be running. The following example use mysql official
docker image with the default cipherguard credentials.

```bash
$ docker run -e MYSQL_ROOT_PASSWORD=<root_password> \
             -e MYSQL_DATABASE=<mariadb_database> \
             -e MYSQL_USER=<mariadb_user> \
             -e MYSQL_PASSWORD=<mariadb_password> \
             mariadb
```

Then you can start cipherguard just by providing the database container's IP address in the
`DATASOURCES_DEFAULT_HOST` environment variable.

```bash
$ docker run --name cipherguard \
             -p 80:80 \
             -p 443:443 \
             -e DATASOURCES_DEFAULT_HOST=<mariadb_container_host> \
             -e DATASOURCES_DEFAULT_PASSWORD=<mariadb_password> \
             -e DATASOURCES_DEFAULT_USERNAME=<mariadb_user> \
             -e DATASOURCES_DEFAULT_DATABASE=<mariadb_database> \
             -e APP_FULL_BASE_URL=https://example.com \
             khulnasoft/cipherguard:develop-debian
```

Once the container is running create your first admin user:

```bash
$ docker exec cipherguard su -m -c "bin/cake cipherguard register_user -u your@email.com -f yourname -l surname -r admin" -s /bin/sh www-data
```

This registration command will return a single use url required to continue the
web browser setup and finish the registration. Your cipherguard instance should be
available browsing `https://example.com`

# Configure cipherguard

## Environment variables reference

Cipherguard docker image provides several environment variables to configure different aspects:

| Variable name                       | Description                                                               | Default value
| ----------------------------------- | --------------------------------                                          | -------------------
| APP_BASE                            | In case you want to run Cipherguard in a subdirectory (e.g. `https://example.com/cipherguard`), set this to the path to the subdirectory (e.g. `/cipherguard`). Make sure this does **not** end in a trailing slash! | null
| APP_FULL_BASE_URL                   | The hostname where your server is reachable, including `https://` (or `http://`). Make sure this does **not** end in a trailing slash! And in case you are running Cipherguard from a subdirectory (e.g. `https://example.com/cipherguard`), please include the subdirectory in this variable, too. | false
| DATASOURCES_DEFAULT_HOST            | Database hostname                                                         | localhost
| DATASOURCES_DEFAULT_PORT            | Database port                                                             | 3306
| DATASOURCES_DEFAULT_USERNAME        | Database username                                                         | ''
| DATASOURCES_DEFAULT_PASSWORD        | Database password                                                         | ''
| DATASOURCES_DEFAULT_DATABASE        | Database name                                                             | ''
| DATASOURCES_DEFAULT_SSL_KEY         | Database SSL Key                                                          | ''
| DATASOURCES_DEFAULT_SSL_CERT        | Database SSL Cert                                                         | ''
| DATASOURCES_DEFAULT_SSL_CA          | Database SSL CA                                                           | ''
| EMAIL_TRANSPORT_DEFAULT_CLASS_NAME  | Email classname                                                           | Smtp
| EMAIL_DEFAULT_FROM                  | From email address                                                        | you@localhost
| EMAIL_DEFAULT_TRANSPORT             | Sets transport method                                                     | default
| EMAIL_TRANSPORT_DEFAULT_HOST        | Server hostname                                                           | localhost
| EMAIL_TRANSPORT_DEFAULT_PORT        | Server port                                                               | 25
| EMAIL_TRANSPORT_DEFAULT_TIMEOUT     | Timeout                                                                   | 30
| EMAIL_TRANSPORT_DEFAULT_USERNAME    | Username for email server auth                                            | null
| EMAIL_TRANSPORT_DEFAULT_PASSWORD    | Password for email server auth                                            | null
| EMAIL_TRANSPORT_DEFAULT_CLIENT      | Client                                                                    | null
| EMAIL_TRANSPORT_DEFAULT_TLS         | Set tls                                                                   | null
| EMAIL_TRANSPORT_DEFAULT_URL         | Set url                                                                   | null
| GNUPGHOME                           | path to gnupghome directory                                               | /var/lib/cipherguard/.gnupg
| CIPHERGUARD_KEY_LENGTH                 | Gpg desired key length                                                    | 3072
| CIPHERGUARD_SUBKEY_LENGTH              | Gpg desired subkey length                                                 | 3072
| CIPHERGUARD_KEY_NAME                   | Key owner name                                                            | Cipherguard default user
| CIPHERGUARD_KEY_EMAIL                  | Key owner email address                                                   | cipherguard@yourdomain.com
| CIPHERGUARD_KEY_EXPIRATION             | Key expiration date                                                       | 0, never expires
| CIPHERGUARD_GPG_SERVER_KEY_FINGERPRINT | GnuPG fingerprint                                                         | null
| CIPHERGUARD_GPG_SERVER_KEY_FINGERPRINT_FORCE | Force calculation of GnuPG fingerprint for server key               | null
| CIPHERGUARD_GPG_SERVER_KEY_PUBLIC      | Path to GnuPG public server key                                           | /etc/cipherguard/gpg/serverkey.asc
| CIPHERGUARD_GPG_SERVER_KEY_PRIVATE     | Path to GnuPG private server key                                          | /etc/cipherguard/gpg/serverkey_private.asc
| CIPHERGUARD_PLUGINS_EXPORT_ENABLED     | Enable export plugin                                                      | true
| CIPHERGUARD_PLUGINS_IMPORT_ENABLED     | Enable import plugin                                                      | true
| CIPHERGUARD_REGISTRATION_PUBLIC        | Defines if users can register                                             | false
| CIPHERGUARD_SSL_FORCE                  | Redirects http to https                                                   | true
| CIPHERGUARD_SECURITY_SET_HEADERS       | Send CSP Headers                                                          | true
| SECURITY_SALT                       | CakePHP security salt                                                     | __SALT__

For more env variables supported please check [default.php](https://github.com/khulnasoft/cipherguard_api/blob/master/config/default.php)
and [app.default.php](https://github.com/khulnasoft/cipherguard_api/blob/master/config/app.default.php)

### Configuration files

What if you already have a set of gpg keys and custom configuration files for cipherguard?
It it possible to mount the desired configuration files as volumes.

* /etc/cipherguard/app.php
* /etc/khulnasoft/cipherguard.php
* /etc/cipherguard/gpg/serverkey.asc
* /etc/cipherguard/gpg/serverkey_private.asc
* /usr/share/php/cipherguard/webroot/img/public/images

### SSL certificate files

It is also possible to mount a ssl certificate on the following paths:

For **image: khulnasoft/cipherguard:latest-ce-non-root**
* /etc/cipherguard/certs/certificate.crt
* /etc/cipherguard/certs/certificate.key

For **image: khulnasoft/cipherguard:latest-ce**
* /etc/ssl/certs/certificate.crt
* /etc/ssl/certs/certificate.key

### Database SSL certificate files

If Database SSL certs provided, you must mount mysql/mariadb specific conf on the following paths:
* /etc/mysql/conf.d # if using mysql
* /etc/mysql/mariadb.conf.d/ #if using mariadb

Example:
```
[client]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
```


### CLI healthcheck

In order to run the healthcheck from the CLI on the container:

On a root docker image:

```
$ su -s /bin/bash www-data
$ export CIPHERGUARD_GPG_SERVER_KEY_FINGERPRINT="$(su -c "gpg --homedir $GNUPGHOME --list-keys --with-colons ${CIPHERGUARD_KEY_EMAIL:-cipherguard@yourdomain.com} |grep fpr |head -1| cut -f10 -d:" -ls /bin/bash www-data)"
$ bin/cake cipherguard healthcheck
```

Non root image:

```
$ export CIPHERGUARD_GPG_SERVER_KEY_FINGERPRINT="$(su -c "gpg --homedir $GNUPGHOME --list-keys --with-colons ${CIPHERGUARD_KEY_EMAIL:-cipherguard@yourdomain.com} |grep fpr |head -1| cut -f10 -d:" -ls /bin/bash www-data)"
$ bin/cake cipherguard healthcheck
```

## Docker secrets support

As an alternative to passing sensitive information via environment variables, _FILE may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in /run/secrets/<secret_name> files. For example:

```
$ docker run --name passsbolt -e DATASOURCES_DEFAULT_PASSWORD_FILE=/run/secrets/db-password -d khulnasoft/cipherguard
```

Currently, this is only supported for DATASOURCES_DEFAULT_PASSWORD, DATASOURCES_DEFAULT_HOST, DATASOURCES_DEFAULT_USERNAME, DATASOURCES_DEFAULT_DATABASE

Following the behaviour we use to mount docker secrets as environment variables, it is also posible to mount docker secrets as a file inside the cipherguard container. So, for some secret files the user can store them using docker secrets and then inject them into the container with a env variable and the entrypoint script will create a symlink to the proper path.

```
$ docker run --name passsbolt -e CIPHERGUARD_SSL_SERVER_CERT_FILE=/run/secrets/ssl-cert -d khulnasoft/cipherguard
```

This feature is only supported for:

- CIPHERGUARD_SSL_SERVER_CERT_FILE that points to /etc/ssl/certs/certificate.crt
- CIPHERGUARD_SSL_SERVER_KEY_FILE that points to /etc/ssl/certs/certificate.key
- CIPHERGUARD_GPG_SERVER_KEY_PRIVATE_FILE that points to /etc/cipherguard/gpg/serverkey_private.asc
- CIPHERGUARD_GPG_SERVER_KEY_PUBLIC_FILE that points to /etc/cipherguard/gpg/serverkey.asc

## Develop on Cipherguard

This repository also provides a way to quickly setup Cipherguard for development purposes. This way should never be used in production, as this would be unsafe.
You can use the docker-compose files under [docker-compose/](./docker-compose/) to spin up Cipherguard for production using docker compose.
If you would like to setup Cipherguard for development purposes, please follow the steps described [here](./dev/README.md).

## Run cipherguard docker tests

```bash
CIPHERGUARD_FLAVOUR=ce CIPHERGUARD_COMPONENT=stable ROOTLESS=false bundle exec rake spec
```

