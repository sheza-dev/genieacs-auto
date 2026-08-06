#!/usr/bin/env bash
set -Eeuo pipefail

mongosh --quiet --authenticationDatabase admin \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" <<EOS
use $GENIEACS_DB_NAME
db.createUser({
  user: "$MONGO_APP_USERNAME",
  pwd: "$MONGO_APP_PASSWORD",
  roles: [{ role: "readWrite", db: "$GENIEACS_DB_NAME" }]
})
EOS
