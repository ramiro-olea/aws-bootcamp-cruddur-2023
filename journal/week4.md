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
 
 ## See what connections are using
 * Under bin folder, create a new file called ```db-sessions``` and add the following code:
 ```sql
 #! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```
* Make the new file executable using:
```sh
chmod u+x /bin/db-sessions
```
* In terminal run:
```sh
./bin/db-sessions
```
![image](https://user-images.githubusercontent.com/62669887/227377431-4493f339-00fc-441e-ab78-7a93f5d6f3cc.png)

* Under bin folder, create a new file called ```db-setup```and add the following code:
```sql
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```
* Make the new file executable using:
```sh
chmod u+x /bin/db-setup
```
* In terminal run:
```sh
./bin/db-setup
```
![image](https://user-images.githubusercontent.com/62669887/227378592-23a0094d-4815-4019-880c-eafd70dda6c3.png)
* In order to install postgres agent, we need to add on ```requirements.txt```the following:
```sh
psycopg[binary]
psycopg[pool]
```
* Run the next command on terminal:
```sh
pip install -r requirements.txt
```
* Under folder lib, create a file called ```db.py``` and add the following code:
```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```
* Update ```docker-compose.yml```file with
```yml
CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"
```
* Update ```home_activities.py```:
```py
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import pool, query_wrap_array

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())

    sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-1----")
    print(json[0])
    return json[0]
    return results
```
* Update ```app.py```
![image](https://user-images.githubusercontent.com/62669887/227389117-e9eec645-dd4c-4beb-8deb-ebdfadb6ca39.png)

## Connect to RDS
* Based on the information used on the instance, export the variable environment so you can connect to the RDS instance:
```sh
export PROD_CONNECTION_URL="postgresql://cruddurroot:xxxxxxx@cruddur-db-instance.c0ussrsbrd1a.us-east-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:xxxxxxx@cruddur-db-instance.c0ussrsbrd1a.us-east-1.rds.amazonaws.com:5432/cruddur"
```
* Test connection:
```sh
psql $PROD_CONNECTION_URL
``` 
![image](https://user-images.githubusercontent.com/62669887/227396396-70061939-4106-4d20-99d8-0fbafa3403d2.png)

* Create a new file under bin folder called ```rds-update-sg-rule```and add the following:
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
* Make the file executable.
* Update ```db-connect```file:
```sh
#! /usr/bin/bash

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```
* Add the following to the ```gitpod-yml```file:
```yml
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```
* Test if everything works correctly.
![image](https://user-images.githubusercontent.com/62669887/227399997-53207445-531d-43e0-b58b-a24f0a8e24ab.png)
