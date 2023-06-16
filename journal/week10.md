# Week 10 — CloudFormation Part 1
* Create a new folder called CFN under AWS.
* Create a new file called `template.yaml`


* Create a new folder called cfn under bin, and create a new file called `deploy` (chmod it):
```sh
#! /usr/bin/env bash
set -e # stop the execution of the script if it fails

CFN_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml"
echo $CFN_PATH

cfn-lint $CFN_PATH

aws cloudformation deploy \
  --stack-name "my-cluster" \
  --s3-bucket "cfn-artifacts" \
  --template-file "$CFN_PATH" \
  --no-execute-changeset \
  --capabilities CAPABILITY_NAMED_IAM
```
* Create a new file under aws/cfn called `task-definition.guard`:
```guard
aws_ecs_cluster_configuration {
  rules = [
    {
      rule = "task_definition_encryption"
      description = "Ensure task definitions are encrypted"
      level = "error"
      action {
        type = "disallow"
        message = "Task definitions in the Amazon ECS cluster must be encrypted"
      }
      match {
        type = "ecs_task_definition"
        expression = "encrypt == false"
      }
    },
    {
      rule = "network_mode"
      description = "Ensure Fargate tasks use awsvpc network mode"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must use awsvpc network mode"
      }
      match {
        type = "ecs_task_definition"
        expression = "network_mode != 'awsvpc'"
      }
    },
    {
      rule = "execution_role"
      description = "Ensure Fargate tasks have an execution role"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must have an execution role"
      }
      match {
        type = "ecs_task_definition"
        expression = "execution_role == null"
      }
    },
  ]
}
```
* Create a new file under aws/cfn called `ecs-cluster.guard`:
```guard
let aws_ecs_cluster_resources = Resources.*[ Type == 'AWS::ECS::Cluster' ]
rule aws_ecs_cluster when %aws_ecs_cluster_resources !empty {
  %aws_ecs_cluster_resources.Properties.CapacityProviders == ["FARGATE"]
  %aws_ecs_cluster_resources.Properties.ClusterName == "MyCluster"
}
```
* Create a new S3 bucket called : `cfn-artifact-ror` (it should be unique).
* Run deploy script and check taht everything works correctly:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/7e471828-9cd7-4454-881c-07e42abab78e)



