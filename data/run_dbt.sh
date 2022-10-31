#!/bin/bash

# handle environment variables
# requires having .env file defined
env_file=.env
if [ ! -f $env_file ]; then
  echo "No .env file found"
  exit 1
fi

echo "Loading environment variables from .env file"
source $env_file
export PG_HOST="$PG_HOST"
export PG_USER="$PG_USER"
export PG_PASSWORD="$PG_PASSWORD"
export PG_SCHEMA="$PG_SCHEMA"
export PG_PORT="$PG_PORT"
export PG_DATABASE="$PG_DATABASE"
export DBT_THREADS="$DBT_THREADS"

echo "Running dbt"
dbt run --project-dir data/dbt_project/ --profiles-dir data/dbt_profiles/

echo "Adding functions of src_code to database"
dbt compile --project-dir data/dbt_project/ --profiles-dir data/dbt_profiles/
files=$(find data/dbt_geoselec/target/compiled/dbt_geoselec/src_code/ -type f -name '*.sql')
for file in $files
do
    echo "Adding $file"
    PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -d $PG_DATABASE -p $PG_PORT -U $PG_USER -f $file
done

echo "Generating dbt documentation"
dbt docs generate --project-dir data/dbt_project/ --profiles-dir data/dbt_profiles/
