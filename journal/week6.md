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
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-05dc5fc86135a0c39"
        ],
        "subnets": [
          "subnet-02664f9ffcec88e72",
          "subnet-0de50186cc6503076",
          "subnet-070398e40d5f5b6eb",
          "subnet-0056c77b816ad20c8",
          "subnet-054142b2b297f90c2",
          "subnet-0bc9031035f356c0d"          
        ]
    }         
},
        "propagateTags": "SERVICE",
        "serviceName": "backend-flask",
        "taskDefinition": "backend-flask"
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
* Creata target group:
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
