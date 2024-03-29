# Week 6 — Deploying Containers

## Test RDS Instance
* Create a new file called ```test```under bin/db folder (remember to do executable the file):
```py
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```
![image](https://user-images.githubusercontent.com/62669887/229263653-7b5b5392-9ac3-449f-bf51-6c2aff742275.png)
* On ```app.py```add the following for flask app health-check:
```py
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```
* Under bin folder create a new folder called flask, and a file called ```health-check``` (remember tp dp it executable):
```py
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```

## Create CloudWatch Log Group
* On the cli create the log group and retention period (1 day):
```sh
aws logs create-log-group --log-group-name /cruddur
aws logs put-retention-policy --log-group-name /cruddur --retention-in-days 1
```
## Create ECS Cluster
```sh
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```
## Create ECR repo and push image
### For Base-image python
```sh
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```
### Login to ECR
```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
### Set URL
```sh
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```
### Pull Image
```sh
docker pull python:3.10-slim-buster
```
### Tag Image
```sh
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```
### Push Image
```sh
docker push $ECR_PYTHON_URL:3.10-slim-buster
```
* Update ```Dockerfile``` with the ECR image URI.
### Create Repo for Flask
```sh
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```
### Set URL
```sh
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```
### Build Image (make sure to be on the directory)
```sh
docker build -t backend-flask .
```
### Tag Image
```sh
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```
### Push Image
```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```
### Assign Parameters:
```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```
* Create new files under aws/policies folder:
```service-execution-policy```
```sh
{
    "Version":"2012-10-17",
    "Statement":[{
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/*"
    }]
  }
```
```service-assume-role-execution-policy```
```sh
{
    "Version":"2012-10-17",
    "Statement":[{
        "Action":["sts:AssumeRole"],
        "Effect":"Allow",
        "Principal":{
          "Service":["ecs-tasks.amazonaws.com"]
      }}]
  }
```
* Go to console and create mannualy both policy and role:
### Policy - Name: CruddurServiceExecutionPolicy
![image](https://user-images.githubusercontent.com/62669887/229267065-b7643a25-0eb1-4c28-b3f4-e1dffa29eb4a.png)
![image](https://user-images.githubusercontent.com/62669887/229267136-a869a936-98f9-4a52-b5a7-38c6378c027e.png)
![image](https://user-images.githubusercontent.com/62669887/229267105-bb71c828-f68c-4bc9-85b6-6b0f02825cb6.png)
### Role - Name: CruddurServiceExecutionRole
![image](https://user-images.githubusercontent.com/62669887/229267264-d2526ccb-fa21-4e30-8ded-535611c4e168.png)
![image](https://user-images.githubusercontent.com/62669887/229267280-0da5ade0-6f2b-42c1-8a8a-7633b9674cd6.png)
### Create Task Role/Policy
* On CLI put this command:
```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"

aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"
```
* Attach to some other services:
```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```
* Under aws folder, create a new folder called task-definitions and create a file called ```backend-flask.json```:
```json
{
    "family": "backend-flask",
    "executionRoleArn": "arn:aws:iam::487961190446:role/CruddurServiceExecutionRole",
    "taskRoleArn": "arn:aws:iam::487961190446:role/CruddurTaskRole",
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": [ 
      "FARGATE" 
    ],
    "containerDefinitions": [
      {
        "name": "backend-flask",
        "image": "487961190446.dkr.ecr.us-east-1.amazonaws.com/backend-flask",
        "essential": true,
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "python /backend-flask/bin/flask/health-check"
          ],
          "interval": 30,
          "timeout": 5,
          "retries": 3,
          "startPeriod": 60
        },
        "portMappings": [
          {
            "name": "backend-flask",
            "containerPort": 4567,
            "protocol": "tcp", 
            "appProtocol": "http"
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "cruddur",
              "awslogs-region": "us-east-1",
              "awslogs-stream-prefix": "backend-flask"
          }
        },
        "environment": [
          {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
          {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
          {"name": "AWS_COGNITO_USER_POOL_ID", "value": "us-east-1_aEdWI8NTd"},
          {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": "3l23shkdgssljeg4de33ij3cph"},
          {"name": "FRONTEND_URL", "value": "*"},
          {"name": "BACKEND_URL", "value": "*"},
          {"name": "AWS_DEFAULT_REGION", "value": "us-east-1"}
        ],
        "secrets": [
          {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
          {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
          {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/CONNECTION_URL" },
          {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
          {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:us-east-1:487961190446:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        ]
      }
    ]
  }
```
* Put the following command on CLI:
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
### Defaults
```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
### Create Security Group
```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```
* Open port 80 on the SG:
```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
  ```
### Create a Service on ECS
![image](https://user-images.githubusercontent.com/62669887/229665407-47edf22f-f636-403a-bb67-776db8ebc48a.png)
![image](https://user-images.githubusercontent.com/62669887/229665458-3edeab8a-a773-445b-ad4f-9d88ffd17ce1.png)
![image](https://user-images.githubusercontent.com/62669887/229665548-1bdf5460-485c-4716-b6e7-e15edf18d49a.png)
![image](https://user-images.githubusercontent.com/62669887/229665576-5d0f32a0-5a3f-4521-92f3-b1deb0bf5e0d.png)

### Create a Service on ECS via CLI
* Create a new file under aws/json called ```service-backend-flask.json```:
```json
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "loadBalancers": [
      {
          "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:487961190446:targetgroup/cruddur-backend-flask-tg/813e4ccf1c0c59da",
          "containerName": "backend-flask",
          "containerPort": 4567
      }
    ],
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-05dc5fc86135a0c39"
        ],
        "subnets": [
          "subnet-0de50186cc6503076",
          "subnet-0056c77b816ad20c8",
          "subnet-054142b2b297f90c2"             
        ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  }
} 
```
* On CLI run:
```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```
* In order to access the container, run this commnad on CLI:
```sh
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task 4a4bfbb086d84b56a867785caa571f13 \
--container backend-flask \
--command "/bin/bash" \
--interactive
```


![image](https://user-images.githubusercontent.com/62669887/231029369-2aaf9b79-a549-4d6c-aa98-dcacd82a947e.png)

### Create Application Load Balancer
* Create a new security group:
![image](https://user-images.githubusercontent.com/62669887/231031027-09a715ef-3a1e-464a-826c-1d58aa11554f.png)
* Creata target group for backend-flask:
![image](https://user-images.githubusercontent.com/62669887/231031473-91f1ee1b-5be3-4d51-9d3c-197c9d0d44b4.png)
![image](https://user-images.githubusercontent.com/62669887/231031525-b5d55b61-7c2e-4b6b-8f08-799b69b3c4da.png)
![image](https://user-images.githubusercontent.com/62669887/231031555-87bcc715-f9f2-4195-b2db-b1f5ab6582e4.png)
* CLick next, and rest leave as default, and click create. 
* Create target group for frontend:
![image](https://user-images.githubusercontent.com/62669887/231031901-20b8d125-75c6-4964-b691-412eb49101ce.png)
* Create the load balancer:
![image](https://user-images.githubusercontent.com/62669887/231032018-36b2ff24-6504-4747-9da5-2daf94aa3e95.png)
![image](https://user-images.githubusercontent.com/62669887/231032070-f342798a-e94b-4491-95f1-ff17c65f98f4.png)
![image](https://user-images.githubusercontent.com/62669887/231032103-9af60e55-83a0-43a3-884a-52c88fcdd68c.png)
![image](https://user-images.githubusercontent.com/62669887/231032129-21ea3cbb-f930-46a8-87f3-7b7ebc9b436e.png)
![image](https://user-images.githubusercontent.com/62669887/231032163-076a0d1e-553a-4d2e-9bdf-77624b0af4d5.png)
* Create service with ```service-backend-flask.json```, and after creation check that health check works correctly:
```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```
![image](https://user-images.githubusercontent.com/62669887/231604871-8f1432b3-f542-428c-a67c-12676a92e2fc.png)

### Creating Front-End Container
* Create a new file under frontend-react-js folder called ```Dockerfile.prod```:
```sh
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```
* Create a new file under frontend-react-js folder called ```nginx.conf```:
```sh
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```
* Under aws/task-definitions folder create a new file called ```frontend-react-js.json``` and add:
```json
{
  "family": "frontend-react-js",
  "executionRoleArn": "arn:aws:iam::487961190446:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::487961190446:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "requiresCompatibilities": [ 
    "FARGATE" 
  ],
  "containerDefinitions": [
    {
      "name": "frontend-react-js",
      "image": "487961190446.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js",
      "essential": true,
      "portMappings": [
        {
          "name": "frontend-react-js",
          "containerPort": 3000,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "frontend-react-js"
        }
      }
    }
  ]
}
```
* Build the image:
```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="http://cruddur-alb-224430687.us-east-1.elb.amazonaws.com":4567 \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-1_aEdWI8NTd" \
--build-arg REACT_APP_CLIENT_ID="3l23shkdgssljeg4de33ij3cph" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
* Create repo:
```sh
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```
* Tag Image:
```sh
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
```
* Push image:
```sh
docker push $ECR_FRONTEND_REACT_URL:latest
```
* Register Task Definition (run on main folder):
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```
* Open port 3000 on Security Group for the service.
* Create service:
```sh
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```
![image](https://user-images.githubusercontent.com/62669887/231617339-9020309c-7c63-4d4c-b654-5ba60ba46bb7.png)

## Create a hosted zone on Route53
* Follow the image and click create hosted zone:
![image](https://user-images.githubusercontent.com/62669887/231620795-bb7e6da8-2a28-44fc-8199-b544b00c4c3d.png)
* Update AWS DNS domain names on your provider.
* Create a new SSL certificate: 
* Follow the steps in the image and click request:
![image](https://user-images.githubusercontent.com/62669887/231621013-27a43694-32b5-48a8-9365-b7db613bbf56.png)
* Click create records in Route 53, and the click again create records. You will have to wait some time in order to be successfull.
* Once successfull you will see that the certificate has been requested:
![image](https://user-images.githubusercontent.com/62669887/231621222-2cf17dd6-5804-4a37-ac89-08dd7105c2fe.png)
* In load Balancer, add a new listener as per the image:
![image](https://user-images.githubusercontent.com/62669887/231621950-5c8aa99a-a08a-451d-ae64-fece74401b80.png)
* Add a second listener:
![image](https://user-images.githubusercontent.com/62669887/231622373-b6331bef-8c1c-40fd-9ab3-7e1180e25d14.png)
![image](https://user-images.githubusercontent.com/62669887/231622394-6c767e62-34a0-4eaa-8649-3b8c92489482.png)
* Create a new rule for the listener on 443 so that api.ramirotech.com can be forwarded to the cruddur-backend-flask-tg:
![image](https://user-images.githubusercontent.com/62669887/231623401-b14a3b04-27d5-40a8-a3ee-8a2ee24c119d.png)
* Create a new record on Route53 to point the ALB:
![image](https://user-images.githubusercontent.com/62669887/231623264-f5011063-1143-4c55-b035-4b179b64a9f3.png)
* Create a second record for api:
![image](https://user-images.githubusercontent.com/62669887/231623927-aaa93851-1f47-48de-94f8-3e7dd5fb7198.png)
* Update files with ramirotech.com and api.ramirotech.com.
* On ECS update both containers: backeend-flask and frontenn-react-js:
![image](https://user-images.githubusercontent.com/62669887/231628984-b0eb7323-d101-4d93-9e16-faefee193905.png)
![image](https://user-images.githubusercontent.com/62669887/231629176-16e08a7e-5617-492e-bdd9-22e3c3ec2efc.png)
* Check that domain is working and showing data:
![image](https://user-images.githubusercontent.com/62669887/231633655-45867c26-ef0b-463c-a597-65f1c3eb90ef.png)

## Container security
* Create a new folder called ecr under bin folder, and create a new file called ```login``` to login to ECS (remember to chmod the file):
```sh
#! /usr/bin/bash

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
¨Create a new file calle ```Dockerfile.prod```under backend-flas folder:
```sh
FROM 487961190446.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

# Inside Container
# make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period . /backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug", "--no-debugger", "--no-reload"]
```
* Build the container:
```sh
docker build -f Dockerfile.prod -t backend-flask-prod .
```
## Create a new register bash script for backend and frontend
* Under bin/backend folder create ```register``` (chmod the file):
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/backend-flask.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```
* Under bin/frontend folder create ```register```(chmod the file):
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/frontend-react-js.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition \
--cli-input-json "file://$TASK_DEF_PATH"
```


 
