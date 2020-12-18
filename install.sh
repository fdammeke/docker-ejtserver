#!/bin/bash

EJTSERVER_VERSION=${EJTSERVER_VERSION:-1.13.1}
EJTSERVER_DOWNLOAD_BASEURL=${EJTSERVER_DOWNLOAD_BASEURL:-https://jan.dammekens.be/files}
EJTSERVER_PATH="/opt/ejtserver"
EJTSERVER_TARBALL="ejtserver_unix_${EJTSERVER_VERSION//./_}.tar.gz"
EJTSERVER_DOWNLOAD_URL="${EJTSERVER_DOWNLOAD_BASEURL}/${EJTSERVER_TARBALL}"

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# Download ejtserver tarball
file_env 'EJT_ACCOUNT_USERNAME'
file_env 'EJT_ACCOUNT_PASSWORD'
if [ -f "/data/${EJTSERVER_TARBALL}" ]; then
  echo "ejtserver already downloaded in /data/${EJTSERVER_TARBALL}. Skipping download..."
else
  echo "Downloading ejtserver ${EJTSERVER_VERSION} from ${EJTSERVER_DOWNLOAD_URL}..."
  if [ ! -z "${EJT_ACCOUNT_USERNAME}" ]; then
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" --user "${EJT_ACCOUNT_USERNAME}:${EJT_ACCOUNT_PASSWORD}" "${EJTSERVER_DOWNLOAD_URL}" 2>&1)
  else
    dlErrorMsg=$(curl --location --fail --silent --show-error --output "/data/${EJTSERVER_TARBALL}" "${EJTSERVER_DOWNLOAD_URL}" 2>&1)
  fi
  if [ ! -z "${dlErrorMsg}" ]; then
    echo "FATAL: ${dlErrorMsg}"
    exit 1
  fi
fi
unset EJT_ACCOUNT_USERNAME
unset EJT_ACCOUNT_PASSWORD

# Install
echo "Installing ejtserver ${EJTSERVER_VERSION}..."
rm -rf ${EJTSERVER_PATH}/*
tar -xzf "/data/${EJTSERVER_TARBALL}" --strip 1 -C ${EJTSERVER_PATH}
chmod a+x ${EJTSERVER_PATH}/bin/admin ${EJTSERVER_PATH}/bin/ejtserver*
rm -f ${EJTSERVER_PATH}/*.txt "/data/${EJTSERVER_TARBALL}"
