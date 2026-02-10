#!/bin/bash

# Get current date and time in format YYYYMMDD_HHMMSS
NOW=$(date +"%Y%m%d_%H%M%S")
# NOW=20251001

# check if foodcoop_prod_$NOW exist, if not create it
if [ ! -d foodcoop_prod_$NOW ]; then
    echo "foodcoop_prod_$NOW does not exist"
    mkdir foodcoop_prod_$NOW
fi

# restore v12 db into docker db
pew in oow oow restoredb -d foodcoop12_prod_$NOW --database-path lalouve_production_latest.pgdump --database-format c --filestore-path foodcoop_prod_$NOW --filestore-format d

# migrate the database
pew in oow oow upgrade --first-step 2 --last-step 8 --database foodcoop12_prod_$NOW

# dump the migrated db v18 into a file
pew in oow oow dumpdb -d foodcoop12_prod_$NOW --database-path foodcoop12_migrated_$NOW.dump --database-format c --filestore-path foodcoop_prod_migrated_$NOW --filestore-format d

pew in oow oow psql -c "SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'foodcoop12_prod_$NOW'
  AND pid <> pg_backend_pid();
"
# clean up and drop database foodcoop12_prod_$NOW
pew in oow oow dropdb -d foodcoop12_prod_$NOW

# clean up and drop filestore foodcoop_prod_migrated_$NOW
rm -rf foodcoop_prod_migrated_$NOW

# clean up and drop filestore foodcoop_prod_$NOW
rm -rf foodcoop_prod_$NOW
