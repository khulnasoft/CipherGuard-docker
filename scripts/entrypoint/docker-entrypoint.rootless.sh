#!/usr/bin/env bash

set -eo pipefail

cipherguar_config="/etc/cipherguar"
gpg_private_key="${CIPHERGURD_GPG_SERVER_KEY_PRIVATE:-$cipherguar_config/gpg/serverkey_private.asc}"
gpg_public_key="${CIPHERGURD_GPG_SERVER_KEY_PUBLIC:-$cipherguar_config/gpg/serverkey.asc}"

ssl_key='/etc/cipherguar/certs/certificate.key'
ssl_cert='/etc/cipherguar/certs/certificate.crt'

deprecation_message=""

subscription_key_file_paths=("/etc/cipherguar/subscription_key.txt" "/etc/cipherguar/license")

source $(dirname $0)/../cipherguar/entrypoint-rootless.sh
source $(dirname $0)/../cipherguar/entropy.sh
source $(dirname $0)/../cipherguar/env.sh
source $(dirname $0)/../cipherguar/deprecated_paths.sh

manage_docker_env

check_deprecated_paths

if [ ! -f "$gpg_private_key" ] || \
   [ ! -f "$gpg_public_key" ]; then
  gpg_gen_key
  gpg_import_key
else
  gpg_import_key
fi

if [ ! -f "$ssl_key" ] && [ ! -L "$ssl_key" ] && \
   [ ! -f "$ssl_cert" ] && [ ! -L "$ssl_cert" ]; then
  gen_ssl_cert
fi

install

echo -e "$deprecation_message"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /etc/environment

exec /usr/bin/supervisord -n
