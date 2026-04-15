#!/usr/bin/env bash

if [ ! -z "$SSH_ORIGINAL_COMMAND" ]; then
  ARGS="$SSH_ORIGINAL_COMMAND"
else
  ARGS="$@"
fi

readonly P_NAME=$(basename $0)
readonly P_DIR=$(readlink -f $(dirname $0))
readonly P_ARGS="$ARGS"
readonly P_USER="$LOGNAME"
readonly P_HOME=$(bash -c "cd ~$(printf %q "$P_USER") && pwd")

usage() {
  cat <<- EOF
  usage: $P_NAME

  Script to manage MongoDB X.509 certificate

    renew <FQDN>
    revoke <CERTIFICATE.pem>
EOF
}

log() {
  local TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
  echo -e "$TIMESTAMP | $1"
}

eexit() {
  log "$2" 1>&2
  exit $1
}

cleanup() {
  if ! rm -fr $P_LOCK; then
    eexit "Failed to release lock directory '$P_LOCK'"
  fi
}

abort() {
  echo
  exit 1
}

readonly PKI=/opt/app/pki
readonly CA=/opt/app/pki/ca
readonly EXPR_RG=15

getCertificateLastId() {

  local readonly FQDN=$1
  local readonly ARCHIVE=$PKI/certs/${FQDN}/archive

  if [ ! -d "$ARCHIVE" ]; then
    eexit 1 "Le dossier $ARCHIVE n'existe pas"
  fi

  if [ ! "$(ls -A $ARCHIVE)" ]; then
    local id=0
  else
    local head=$(find $ARCHIVE -mindepth 1 -maxdepth 1 -type f -name "*.cert.pem" -exec basename {} \; | sort -nsk1,1 -t. -r | head -n 1)
    local id=$(echo $head | sed 's/\..*//')
  fi

  echo $id
}

getCrlLastId() {

  local readonly ARCHIVE=$PKI/crl/archive

  if [ ! -d "$ARCHIVE" ]; then
    eexit 1 "Le dossier $ARCHIVE n'existe pas"
  fi

  if [ ! "$(ls -A $ARCHIVE)" ]; then
    local id=0
  else
    local head=$(find $ARCHIVE -mindepth 1 -maxdepth 1 -type f -name "*.ca.crl" -exec basename {} \; | sort -nsk1,1 -t. -r | head -n 1)
    local id=$(echo $head | sed 's/\..*//')
  fi

  echo $id
}

renew() {

  if [ "$#" -ne 1 ]; then
    usage >&2
    exit 1
  fi

  local readonly FQDN=$1
  local readonly ARCHIVE=$PKI/certs/${FQDN}/archive
  local REVOKED=0

  umask 077

  if [ ! -f ${CA}/db/ca.db ]; then
    touch ${CA}/db/ca.db
  fi

  mkdir -p $ARCHIVE

  if [ -f $PKI/certs/${FQDN}/cert.pem ]; then

    log "Un certificat existe"

    #openssl verify -crl_check -CAfile $PKI/crl/chain.pem -CRLfile $PKI/crl/ca.crl $PKI/certs/${FQDN}/cert.pem &>/dev/null

    serial=$(openssl x509 -noout -serial -in $PKI/certs/${FQDN}/cert.pem | sed 's/serial=//')

    openssl crl -in $PKI/crl/ca.crl -noout -text | grep -qi $serial

    if [ $? -eq 1 ]; then

      log "Le certificat n'est pas révoqué"

      openssl x509 -noout -in $PKI/certs/${FQDN}/cert.pem -checkend $((EXPR_RG * 86400)) &>/dev/null

      if [ $? -eq 0 ]; then
        eexit 0 "Le certificat expire dans plus de $EXPR_RG jours"
      else
        log "Le certificat expire dans moins de $EXPR_RG jours"
      fi

    else
      log "Le certificat est révoqué"
      REVOKED=1
    fi

    log "Renouvellement du certificat"

  else

    log "Génération d'un premier certificat"

  fi

  local lastId=$(getCertificateLastId $FQDN)
  local id=$((lastId + 1))

  log "Last ID : $lastId"
  log "ID : $id"

  log "Génération d'un numéro de série pour le certificat X.509"

  echo "$(openssl rand -hex 16)" > $CA/db/ca.crt.srl

  log "Génération d'une clé privée pour le certificat X.509"

  openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out $ARCHIVE/$id.privkey.pem

  if [ $? -ne 0 ]; then
    eexit 1
  fi

  log "Génération de la demande de certificat X.509"

  openssl req -new -config $CA/openssl.mtls.cnf -key $ARCHIVE/$id.privkey.pem -outform PEM -out $ARCHIVE/$id.csr.pem

  if [ $? -ne 0 ]; then
    eexit 1
  fi

  log "Signature du certificat X.509 par l'autorité de certification intermédiaire"

  openssl ca -batch -config $CA/openssl.cnf -in $ARCHIVE/$id.csr.pem -extensions mtls_ext -out $ARCHIVE/$id.cert.crt

  if [ $? -ne 0 ]; then
    eexit 1
  fi

  openssl x509 -in $ARCHIVE/$id.cert.crt -outform PEM -out $ARCHIVE/$id.cert.pem

  rm $ARCHIVE/$id.cert.crt

  cat $CA/ca.pem $CA/root-ca.pem > $ARCHIVE/$id.chain.pem
  cat $ARCHIVE/$id.cert.pem $ARCHIVE/$id.chain.pem > $ARCHIVE/$id.fullchain.pem

  #openssl x509 -noout -text -in $ARCHIVE/$id.cert.pem

  ln -sf $ARCHIVE/$id.cert.pem $PKI/certs/${FQDN}/cert.pem 
  ln -sf $ARCHIVE/$id.privkey.pem $PKI/certs/${FQDN}/privkey.pem 
  ln -sf $ARCHIVE/$id.chain.pem $PKI/certs/${FQDN}/chain.pem 
  ln -sf $ARCHIVE/$id.fullchain.pem $PKI/certs/${FQDN}/fullchain.pem 
  rm $ARCHIVE/$id.csr.pem

  if [ ! -f $PKI/crl/ca.crl ]; then

    log "Création de la base CRL de certificats révoqués"

    echo "$(openssl rand -hex 16)" > $CA/db/ca.crl.srl
    
    openssl ca -config $CA/openssl.cnf -gencrl -out $PKI/crl/archive/1.ca.crl

    cat $CA/ca.pem $CA/root-ca.pem > $PKI/crl/archive/1.chain.pem
  
    ln -sf $PKI/crl/archive/1.ca.crl $PKI/crl/ca.crl 
    ln -sf $PKI/crl/archive/1.chain.pem $PKI/crl/chain.pem

  fi

  if [ $lastId -ne 0 ] && [ $REVOKED -eq 0 ]; then
    revoke "$ARCHIVE/$lastId.cert.pem" superseded
  fi

}

revoke() {

  if [ "$#" -ne 2 ]; then
    usage >&2
    exit 1
  fi

  local readonly CERT=$1
  local readonly REASON=$2
  local readonly ARCHIVE=$PKI/crl/archive

  if [ ! -f $CERT ]; then

    eexit 1 "Le certificat n'existe pas"

  fi

  #openssl verify -crl_check -CAfile $PKI/crl/chain.pem -CRLfile $PKI/crl/ca.crl $CERT &>/dev/null

  serial=$(openssl x509 -noout -serial -in $CERT | sed 's/serial=//')

  openssl crl -in $PKI/crl/ca.crl -noout -text | grep -qi $serial

  if [ $? -ne 1 ]; then

    eexit 0 "Le certificat est déjà révoqué"

  fi

  openssl ca -config $CA/openssl.cnf -revoke $CERT -crl_reason $REASON

  if [ $? -ne 0 ]; then
    eexit 1
  fi

  log "Mise à jour de la base CRL de certificats révoqués"

  echo "$(openssl rand -hex 16)" > $CA/db/ca.crl.srl

  local lastId=$(getCrlLastId)
  local id=$((lastId + 1))

  openssl ca -config $CA/openssl.cnf -gencrl -out $ARCHIVE/$id.ca.crl

  cat $CA/ca.pem $CA/root-ca.pem > $ARCHIVE/$id.chain.pem
  
  ln -sf $ARCHIVE/$id.ca.crl $PKI/crl/ca.crl 
  ln -sf $ARCHIVE/$id.chain.pem $PKI/crl/chain.pem

}

main() {

  if [ "$#" -lt 1 ]; then
    usage >&2
    exit 1
  fi

  readonly P_LOCK="/tmp/.$P_USER-ca-x509"

  if ! mkdir $P_LOCK 2>/dev/null; then
    eexit 1 "An instance of this script is already running..."
  fi

  trap "abort" INT QUIT
  trap "cleanup" EXIT

  case "$1" in
    "renew") shift; renew "$@";;
    "revoke") shift; revoke "$@";;
    "*") usage >&2; exit 1;;
  esac

}

main $P_ARGS
