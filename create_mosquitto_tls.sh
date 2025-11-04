#!/bin/bash

# Variables de répertoires
PKI_DIR=~/pki
MOSQUITTO_DIR=~/mosquitto
BROKER_IP="192.168.68.36"
BROKER_DNS="broker.example.com"

# Variables X509
COUNTRY="FR"
STATE="Bretagne"
LOCALITY="Vannes"
ORGANIZATION="WAGO"
ORG_UNIT="MPA"
COMMON_NAME_BROKER="Broker"
COMMON_NAME_CLIENT="Client"

# Fichier de configuration temporaire pour OpenSSL
OPENSSL_CONFIG=$(mktemp)
cat <<EOL > $OPENSSL_CONFIG
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
countryName = $COUNTRY
stateOrProvinceName = $STATE
localityName = $LOCALITY
organizationName = $ORGANIZATION
organizationalUnitName = $ORG_UNIT
commonName = $COMMON_NAME_BROKER

[v3_req]
subjectAltName = IP:$BROKER_IP,DNS:$BROKER_DNS
EOL

# Génération CA
mkdir -p $PKI_DIR/ca $PKI_DIR/broker $PKI_DIR/clients $MOSQUITTO_DIR/config/certs
openssl req -new -x509 -days 365 -keyout $PKI_DIR/ca/ca.key -out $PKI_DIR/ca/ca.crt \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME_BROKER"

# Clé privée serveur et signature
openssl genrsa -out $PKI_DIR/broker/broker.key 2048
openssl req -out $PKI_DIR/broker/broker.csr -key $PKI_DIR/broker/broker.key -new -config $OPENSSL_CONFIG \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME_BROKER"
openssl x509 -req -in $PKI_DIR/broker/broker.csr -CA $PKI_DIR/ca/ca.crt -CAkey $PKI_DIR/ca/ca.key -CAcreateserial -out $PKI_DIR/broker/broker.crt -days 365 -extfile $OPENSSL_CONFIG -extensions v3_req

# Clé privée client et signature
openssl genrsa -out $PKI_DIR/clients/client.key 2048
openssl req -out $PKI_DIR/clients/client.csr -key $PKI_DIR/clients/client.key -new \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME_CLIENT"
openssl x509 -req -in $PKI_DIR/clients/client.csr -CA $PKI_DIR/ca/ca.crt -CAkey $PKI_DIR/ca/ca.key -CAcreateserial -out $PKI_DIR/clients/client.crt -days 365

# Copie des certificats
cp $PKI_DIR/ca/ca.crt $PKI_DIR/broker/broker.key $PKI_DIR/broker/broker.crt $MOSQUITTO_DIR/config/certs

# Création du fichier mosquitto.conf
cat <<EOL > $MOSQUITTO_DIR/config/mosquitto.conf
listener 8883
cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/broker.crt
keyfile /mosquitto/config/certs/broker.key
require_certificate true
allow_anonymous true
EOL

# Nettoyage du fichier de configuration temporaire
rm -f $OPENSSL_CONFIG
