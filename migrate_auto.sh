#!/bin/bash

# Get current date and time in format YYYYMMDD_HHMMSS
NOW=$(date +"%Y%m%d_%H%M%S")
# NOW=20251001

# --- Configuration ---
# Set the dump file name here; DB_NAME is derived from the first segment of the filename
# DUMP_FILE="lalouve_production_latest.pgdump"
DUMP_FILE="superquinquin_production_latest.pgdump"
# DUMP_FILE="lacoopsurmer_production_latest.pgdump"
# DUMP_FILE="otsokop_production_latest.pgdump"
# DUMP_FILE="tmt_production_latest.pgdump"
# DUMP_FILE="chaudron_production_latest.pgdump"

DB_NAME="${DUMP_FILE%%_*}"   # e.g. "lalouve" from "lalouve_production_latest.pgdump"

# check if ${DB_NAME}_prod_$NOW exist, if not create it
if [ ! -d ${DB_NAME}_prod_$NOW ]; then
    echo "${DB_NAME}_prod_$NOW does not exist"
    mkdir ${DB_NAME}_prod_$NOW
fi

# restore v12 db into docker db
pew in oow oow restoredb -d ${DB_NAME}_prod_$NOW --database-path $DUMP_FILE --database-format c --filestore-path ${DB_NAME}_prod_$NOW --filestore-format d

# migrate the database
pew in oow oow upgrade --first-step 2 --last-step 8 --database ${DB_NAME}_prod_$NOW

# dump the migrated db v18 into a file
pew in oow oow dumpdb -d ${DB_NAME}_prod_$NOW --database-path ${DB_NAME}_migrated_$NOW.dump --database-format c --filestore-path ${DB_NAME}_prod_migrated_$NOW --filestore-format d

pew in oow oow psql -c "SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${DB_NAME}_prod_$NOW'
  AND pid <> pg_backend_pid();
"
# clean up and drop database ${DB_NAME}_prod_$NOW
pew in oow oow dropdb -d ${DB_NAME}_prod_$NOW

# clean up and drop filestore ${DB_NAME}_prod_migrated_$NOW
rm -rf ${DB_NAME}_prod_migrated_$NOW

# clean up and drop filestore ${DB_NAME}_prod_$NOW
rm -rf ${DB_NAME}_prod_$NOW
