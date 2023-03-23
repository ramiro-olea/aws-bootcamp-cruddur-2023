# Week 4 — Postgres and RDS

## Provision RDS instance
* On the CLI paste the following command:
```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password xxxxxxx \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
  ```
  * When RDS is created, stop it from the AWS console (will be stopped for 7 days only-temporarily)
  
  * Connect to Postgres client using the following comand on the psql terminal:
  ```sh
  psql -Upostgres --host localhost
  ```
  * While connceted to the postgres client, let's create our database:
  ```sql
  CREATE database cruddur;
  ```
  * On Gitpod, create a folder under Backend called db, and create a file called ```schema.sql``` with the following code:
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  ```
  * Exit postgres client:
  ```sql
  \q
 ```
 * Change to backend-flask directory and add the following command on terminal:
 ```sh
 psql cruddur < db/schema.sql -h localhost -U postgres
 ```
 ![image](https://user-images.githubusercontent.com/62669887/227072487-9cae7ab7-e065-440e-b54e-e03f189c56e5.png)
* In order to avoid setting the password every time we want to connect to the psql, we will create a connection URL string, which gives all the details that needs to connect to the server:
```sh
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
```
* Check if the connection and variable works:
```sh
psql $CONNECTION_URL
```
* Create variable on GitPod:
```sh
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
```
* Do the same steps for production evironment. We have to put the information of RDS instance:
```sh
export PROD_CONNECTION_URL="postgresql://cruddurroot:PasswordDB12@cruddur-db-instance.c0ussrsbrd1a.us-east-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:PasswordDB12@cruddur-db-instance.c0ussrsbrd1a.us-east-1.rds.amazonaws.com:5432/cruddur"
```
* Under backend-flask create a new folder called bin and three files: ```db-create```, ```db-drop```, ```db-schema-load``` and ```db-connect```.
* In order to make executable these new files, run the following commands:
```sh
chmod u+x bin/db-create
chmod u+x bin/db-drop
chmod u+x bin/db-schema-load
chmod u+x bin/db-connect
```
* Update the new files with the following code:
```db-create```
```sql
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```
```db-drop```
```sql
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```
```db-schema-load```
```sql
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```
```db-connect```
```sql
#! /usr/bin/bash

psql $CONNECTION_URL
```
* Run the following command in terminal to see that everything works well:
```sh
./bin/db-create
./bin/db-drop
./bin/db-schema-load
./bin/db-connect
```
## Create our tables
* On ```schema.sql```file add the following:
```sql
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
* Under bin create a new file called ```db-seed``` and add the following:
```sql
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```
* Under db create a new file called ```seed.sql```and add the following:
```sql
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
  ```
  * Run the following code for making executable ```db-seed```
  ```sh
  chmod u+x ./bin/db-seed
  ```
  * Run the following to see that everything works correctly:
  ```sh
  ./bin/db-schema-load
  ./bin/db-seed
  ```
  ![image](https://user-images.githubusercontent.com/62669887/227087773-a5a9c468-91cb-4cde-8868-26ace44a6324.png)
