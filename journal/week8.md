# Week 8 — Serverless Image Processing

## Starting with AWS CDK
* Create a new folder called thumbing-serverless-cdk, enter the folder and the run:
```sh
npm install aws-cdk -g
```
* Inside the folder run:
```sh
cdk init app --language typescript
```
* Run:
```sh
npm i dotenv
```
* Update `thumbing-serverless-cdk-stack.ts`:
```ts
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';
import * as dotenv from 'dotenv';

dotenv.config();

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
    const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;

    const bucket = this.createBucket(bucketName);
    const lambda = this.createLambda(functionPath, bucketName, folderInput, folderOutput);

  }

  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'ThumbingBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });
    return bucket;
  }

  createLambda(functionPath: string, bucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(functionPath),
      environment: {
        DEST_BUCKET_NAME: bucketName,
        FOLDER_INPUT: folderInput,
        FOLDER_OUTPUT: folderOutput,
        PROCESS_WIDTH: '512',
        PROCESS_HEIGHT: '512'
      }
    });
    return lambdaFunction;
  } 

}
```
* On `gitpod.yaml` add the following:
```sh
  - name: cdk
    before: |
      npm install aws-cdk -g  
      cd thumbing-serverless-cdk
      npm i
```
## Adding Lambdas to our gitpod ambient
* Create a new folder called `process-images`` under aws/lambdas and create:
`index.js`
```js
const process = require('process');
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')

const bucketName = process.env.DEST_BUCKET_NAME
const folderInput = process.env.FOLDER_INPUT
const folderOutput = process.env.FOLDER_OUTPUT
const width = parseInt(process.env.PROCESS_WIDTH)
const height = parseInt(process.env.PROCESS_HEIGHT)

client = getClient();

exports.handler = async (event) => {
  console.log('event',event)

  const srcBucket = event.Records[0].s3.bucket.name;
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
  console.log('srcBucket',srcBucket)
  console.log('srcKey',srcKey)

  const dstBucket = bucketName;
  const dstKey = srcKey.replace(folderInput,folderOutput)
  console.log('dstBucket',dstBucket)
  console.log('dstKey',dstKey)

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(dstBucket,dstKey,processedImage)
};
```
`test.js`
```js
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')

async function main(){
  client = getClient()
  const srcBucket = 'cruddur-thumbs'
  const srcKey = 'avatar/original/data.jpg'
  const dstBucket = 'cruddur-thumbs'
  const dstKey = 'avatar/processed/data.png'
  const width = 256
  const height = 256

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  console.log(originalImage)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
}

main()
```
`s3-image-processing.js`
```js
const sharp = require('sharp');
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");

function getClient(){
  const client = new S3Client();
  return client;
}

async function getOriginalImage(client,srcBucket,srcKey){
  console.log('get==')
  const params = {
    Bucket: srcBucket,
    Key: srcKey
  };
  console.log('params',params)
  const command = new GetObjectCommand(params);
  const response = await client.send(command);

  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(chunk);
  }
  const buffer = Buffer.concat(chunks);
  return buffer;
}

async function processImage(image,width,height){
  const processedImage = await sharp(image)
    .resize(width, height)
    .jpeg()
    .toBuffer();
  return processedImage;
}

async function uploadProcessedImage(client,dstBucket,dstKey,image){
  console.log('upload==')
  const params = {
    Bucket: dstBucket,
    Key: dstKey,
    Body: image,
    ContentType: 'image/jpeg'
  };
  console.log('params',params)
  const command = new PutObjectCommand(params);
  const response = await client.send(command);
  console.log('repsonse',response);
  return response;
}

module.exports = {
  getClient: getClient,
  getOriginalImage: getOriginalImage,
  processImage: processImage,
  uploadProcessedImage: uploadProcessedImage
}
```
* After creation, on the console write the following, under the aws/lambdas/process images folder:
```sh
npm init -y
```
* Install sharp:
```sh
npm i sharp
```
* Install sdk:
```sh
npm i @aws-sdk/client-s3
```
* Boostrap cdk:
```sh
cdk bootstrap
```
* Run and deploy cdk:
```sh
cdk deploy
```
* Create a new folder under bin called `serverless` and create files (remember to chmod):
`build`
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $SERVERLESS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
SERVERLESS_PROJECT_PATH="$PROJECT_PATH/thumbing-serverless-cdk"

cd $SERVERLESS_PROJECT_PATH

npm install
rm -rf node_modules/sharp
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --arch=x64 --platform=linux --libc=glibc sharp
```
## Create S3 Event Notification to Lambda
* Add the following code on `thumbing-serverless-cdk-stack.ts`:
```sh
this.createS3NotifyToLambda(folderInput,laombda,bucket)

createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
  const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(s3.EventType.OBJECT_CREATED_PUT,
    destination,
    {prefix: prefix}
  )
}
```
* In order for CDK to not destroy de S3 bucket, a new bucket has to be created from AWS console.
* Run:
```sh
cdk destroy
```
* Create the new bucket called "assets.ramirotech.com"
* On gitpod type on the cli:
```sh
cdk deploy
```
* Create the following files under bin/serverless:
`upload`
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://assets.$DOMAIN_NAME/avatars/original/data.jpg"
```
`clear`
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/original/data.jpg"
aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/processed/data.jpg"
```
* Update `thumbing-serverless-cdk-stack.ts` in order to create/update lamba function, sns topic, s3 notifications, sns subscriptions, iam permission directly on CDK:
```ts
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sns from 'aws-cdk-lib/aws-sns';
import { Construct } from 'constructs';
import * as dotenv from 'dotenv';

dotenv.config();

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
    const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;
    const webhookUrl: string = process.env.THUMBING_WEBHOOK_URL as string;
    const topicName: string = process.env.THUMBING_TOPIC_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    console.log('bucketName',bucketName)
    console.log('folderInput',folderInput)
    console.log('folderOutput',folderOutput)
    console.log('webhookUrl',webhookUrl)
    console.log('topicName',topicName)
    console.log('functionPath',functionPath)

    //const bucket = this.createBucket(bucketName);
    const bucket = this.importBucket(bucketName);

    // create a lambda
    const lambda = this.createLambda(functionPath, bucketName, folderInput, folderOutput);

    // create topic and subscription
    const snsTopic = this.createSnsTopic(topicName)
    this.createSnsSubscription(snsTopic,webhookUrl)

    // add our s3 event notifications
    this.createS3NotifyToLambda(folderInput,lambda,bucket)
    this.createS3NotifyToSns(folderOutput,snsTopic,bucket)

    // create policies
    const s3ReadWritePolicy = this.createPolicyBucketAccess(bucket.bucketArn)
    //const snsPublishPolicy = this.createPolicySnSPublish(snsTopic.topicArn)

    // attach policies for permissions
    lambda.addToRolePolicy(s3ReadWritePolicy);
    //lambda.addToRolePolicy(snsPublishPolicy);
  }

  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'AssetsBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY
    });
    return bucket;
  }

  importBucket(bucketName: string): s3.IBucket {
    const bucket = s3.Bucket.fromBucketName(this,"AssetsBucket",bucketName);
    return bucket;
  }

  createLambda(functionPath: string, bucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(functionPath),
      environment: {
        DEST_BUCKET_NAME: bucketName,
        FOLDER_INPUT: folderInput,
        FOLDER_OUTPUT: folderOutput,
        PROCESS_WIDTH: '512',
        PROCESS_HEIGHT: '512'
      }
    });
    return lambdaFunction;
  } 

  createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
    const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT,
      destination,
      {prefix: prefix} // folder to contain the original images
    )
  }

  createPolicyBucketAccess(bucketArn: string){
    const s3ReadWritePolicy = new iam.PolicyStatement({
      actions: [
        's3:GetObject',
        's3:PutObject',
      ],
      resources: [
        `${bucketArn}/*`,
      ]
    });
    return s3ReadWritePolicy;
  }

  createSnsTopic(topicName: string): sns.ITopic{
    const logicalName = "ThumbingTopic";
    const snsTopic = new sns.Topic(this, logicalName, {
      topicName: topicName
    });
    return snsTopic;
  }

  createSnsSubscription(snsTopic: sns.ITopic, webhookUrl: string): sns.Subscription {
    const snsSubscription = snsTopic.addSubscription(
      new subscriptions.UrlSubscription(webhookUrl)
    )
    return snsSubscription;
  }

  createS3NotifyToSns(prefix: string, snsTopic: sns.ITopic, bucket: s3.IBucket): void {
    const destination = new s3n.SnsDestination(snsTopic)
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT, 
      destination,
      {prefix: prefix}
    );
  }

  /*
  createPolicySnSPublish(topicArn: string){
    const snsPublishPolicy = new iam.PolicyStatement({
      actions: [
        'sns:Publish',
      ],
      resources: [
        topicArn
      ]
    });
    return snsPublishPolicy;
  }
  */
}
```
* Run `cdk deploy` and check taht everything works correctly:
![image](https://user-images.githubusercontent.com/62669887/236084184-86023730-9c8b-4b0e-83c3-10a37f220dc8.png)
![image](https://user-images.githubusercontent.com/62669887/236084252-e9d99c77-972c-488b-b7ea-2183fd761059.png)
![image](https://user-images.githubusercontent.com/62669887/236084344-07a08817-e2af-4c13-ab9e-49a804b13b80.png)
![image](https://user-images.githubusercontent.com/62669887/236084484-8e0688ac-8b9f-481e-a0f3-fdcafa4d90c8.png)
![image](https://user-images.githubusercontent.com/62669887/236084531-7ba26901-6bba-4816-be44-a0ffcccb04a5.png)
![image](https://user-images.githubusercontent.com/62669887/236084563-fec9bdd1-05c6-4384-bd85-2e148d72c8f8.png)

## Amazon CloudFront (CDN)
* Go to AWS console, and go to CloudFront.
* Click create CloudFront Distribution:
![image](https://user-images.githubusercontent.com/62669887/236348205-784202f1-938f-49a5-a284-b92c7d89b474.png)
* Fill as follows and click create:
![image](https://user-images.githubusercontent.com/62669887/236348326-202f606b-5ef7-4b52-80af-799159de9e78.png)
* In order to get the origin access control, click create control setting, and fill as follows:
![image](https://user-images.githubusercontent.com/62669887/236348115-567397df-ba01-4d99-bc29-3ac72cf7a385.png)
![image](https://user-images.githubusercontent.com/62669887/236348894-535f3b7b-164e-4918-af6b-7f4998c01da0.png)
![image](https://user-images.githubusercontent.com/62669887/236349005-8341154e-5e44-4de9-931e-31f6449f4758.png)
![image](https://user-images.githubusercontent.com/62669887/236349058-bbcd3893-1223-485e-af19-344b5b46599e.png)
![image](https://user-images.githubusercontent.com/62669887/236349093-e7cecaa7-1480-49e1-8e55-69525b612ce9.png)
* On route 53, on the existing hosted zone, add a new record and fill as follows:
![image](https://user-images.githubusercontent.com/62669887/236349404-f29a0b2f-5750-4185-b74f-d7d8b2af1fa8.png)
* Add the following access policy to the S3 bucket:
```json
{
        "Version": "2008-10-17",
        "Id": "PolicyForCloudFrontPrivateContent",
        "Statement": [
            {
                "Sid": "AllowCloudFrontServicePrincipal",
                "Effect": "Allow",
                "Principal": {
                    "Service": "cloudfront.amazonaws.com"
                },
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::assets.ramirotech.com/*",
                "Condition": {
                    "StringEquals": {
                      "AWS:SourceArn": "arn:aws:cloudfront::487961190446:distribution/E3AQ8H91OQZUKY"
                    }
                }
            }
        ]
      }
```
* update `.env` file and add:
```sh
UPLOADS_BUCKET_NAME="uploads.ramirotech.com"
ASSETS_BUCKET_NAME="assets.ramirotech.com"
```
* Edit `thumbing-serverless-cdk-stack.ts`, `.env`, `clear` and `upload` files with the updates asked.
* Check that everything works fine and as expected (having different buckets for the uploads and the processed images):
![image](https://user-images.githubusercontent.com/62669887/236371131-b3d6fe84-667e-473f-9ec0-85ae676ce6f6.png)
![image](https://user-images.githubusercontent.com/62669887/236371225-122e5136-dd65-4a0a-898c-82d08a65b5ad.png)
![image](https://user-images.githubusercontent.com/62669887/236371263-47c82fe3-21be-4b25-9306-ee33bb4cf858.png)

* Create a new sript under bin called `bootstrap`:
```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="bootstrap"
printf "${CYAN}====== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_DIR=$(dirname $ABS_PATH)

source "$BIN_DIR/db/setup"
source "$BIN_DIR/ddb/schema-load"
source "$BIN_DIR/ddb/seed"
```
* Create a new file under backend-flask/db/sql/users called `show.sql`:
```sql
SELECT 
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.handle,
      users.display_name,
      (
       SELECT 
        count(true) 
       FROM public.activities
       WHERE
        activities.user_uuid = users.uuid
       ) as cruds_count
  ) object_row) as profile,
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    SELECT
      activities.uuid,
      users.display_name,
      users.handle,
      activities.message,
      activities.created_at,
      activities.expires_at
    FROM public.activities
    WHERE
      activities.user_uuid = users.uuid
    ORDER BY activities.created_at DESC 
    LIMIT 40
  ) array_row) as activities
FROM public.users
WHERE
  users.handle = %(handle)s
```
* Under frontend-react-js/src/components create the following files: 
`EditProfileButton.js`
```js
import './EditProfileButton.css';

export default function EditProfileButton(props) {
  const pop_profile_form = (event) => {
    event.preventDefault();
    props.setPopped(true);
    return false;
  }

  return (
    <button onClick={pop_profile_form} className='profile-edit-button' href="#">Edit Profile</button>
  );
}
```
`EditProfileButton.css`
```css
.profile-edit-button {
    border: solid 1px rgba(255,255,255,0.5);
    padding: 12px 20px;
    font-size: 18px;
    background: none;
    border-radius: 999px;
    color: rgba(255,255,255,0.8);
    cursor: pointer;
  }
  
  .profile-edit-button:hover {
    background: rgba(255,255,255,0.3)
  }
```
``ProfileHeading.js`
```js
import './ProfileHeading.css';
import EditProfileButton from '../components/EditProfileButton';

export default function ProfileHeading(props) {
  const backgroundImage = 'url("https://assets.ramirotech.com/banners/banner.jpg")';
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };
  return (
  <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    <div class="banner" style={styles} >
      <div className="avatar">
        <img src="https://assets.ramirotech.com/avatars/data.jpg"></img>
      </div>
    </div>
    <div class="info">
      <div class='id'>
        <div className="display_name">{props.profile.display_name}</div>
        <div className="handle">@{props.profile.handle}</div>
      </div>
      <EditProfileButton setPopped={props.setPopped} />
    </div>

  </div>
  );
}
```
`ProfileHeading.css`
```css
.profile_heading {
  padding-bottom: 0px;
}
.profile_heading .avatar {
  position: absolute;
  bottom:-74px;
  left: 16px;
}
.profile_heading .avatar img {
  width: 148px;
  height: 148px;
  border-radius: 999px;
  border: solid 8px var(--fg);
}

.profile_heading .banner {
  position: relative;
  height: 200px;
}

.profile_heading .info {
  display: flex;
  flex-direction: row;
  align-items: start;
  padding: 16px;
}

.profile_heading .info .id {
  padding-top: 70px;
  flex-grow: 1;
}

.profile_heading .info .id .display_name {
  font-size: 24px;
  font-weight: bold;
  color: rgb(255,255,255);
}
.profile_heading .info .id .handle {
  font-size: 16px;
  color: rgba(255,255,255,0.7);
}

.profile_heading .cruds_count {
  color: rgba(255,255,255,0.7);
}
```
* Update the following files, as per Andrew's instructions:
  * Dockerfile
  * user_activities.py
  * ActivityFeed.js
  * CrudButton.js
  * HomeFeedPage.js
  * NotificationsFeedPage.js
  * UserFeedPage.js
* Create a new file under bin folder called `prepare`:
```sh
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="bootstrap"
printf "${CYAN}====== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
BIN_PATH=$(dirname $ABS_PATH)
DB_PATH="$BIN_PATH/db"
DDB_PATH="$BIN_PATH/ddb"
echo "====$"
echo $DB_PATH
echo "====$"
```
* Create a new folder called generate under bin folder, and create a file called `migration`:
```sh
#!/usr/bin/env python3
import time
import os
import sys

if len(sys.argv) == 2:
  name = sys.argv[1]
else:
  print("pass a filename: eg. ./bin/generate/migration add_bio_column")
  exit(0)

timestamp = str(time.time()).replace(".","")

filename = f"{timestamp}_{name}.py"

# covert undername name to title case eg. add_bio_column -> AddBioColumn
klass = name.replace('_', ' ').title().replace(' ','')

file_content = f"""
from lib.db import db
class {klass}Migration:
  def migrate_sql():
    data = \"\"\"
    \"\"\"
    return data
  def rollback_sql():
    data = \"\"\"
    \"\"\"
    return data
  def migrate():
    db.query_commit({klass}Migration.migrate_sql(),{{
    }})
  def rollback():
    db.query_commit({klass}Migration.rollback_sql(),{{
    }})
migration = AddBioColumnMigration
"""
#remove leading and trailing new lines
file_content = file_content.lstrip('\n').rstrip('\n')

current_path = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations',filename))
print(file_path)

with open(file_path, 'w') as f:
  f.write(file_content
```
* Update `schema.sql` file with below and create a new file called `.keep` under backend-flask/db/migrations:
```sql
CREATE TABLE IF NOT EXISTS public.schema_information (
  id integer UNIQUE,
  last_successful_run text
);
INSERT INTO public.schema_information (id, last_successful_run)
VALUES(1, '0')
ON CONFLICT (id) DO NOTHING;
```
* Create a new file called `update.sql` under backend-flask/db:
```sql
UPDATE public.users 
SET 
  bio = %(bio)s,
  display_name= %(display_name)s
WHERE 
  users.cognito_user_id = %(cognito_user_id)s
RETURNING handle;
```
* Update `show.sql` as per Andrew's guidance.
* Create a new file called `update_profile.py` under backend-flask/services:
```py
from lib.db import db

class UpdateProfile:
  def run(cognito_user_id,bio,display_name):
    model = {
      'errors': None,
      'data': None
    }

    if display_name == None or len(display_name) < 1:
      model['errors'] = ['display_name_blank']

    if model['errors']:
      model['data'] = {
        'bio': bio,
        'display_name': display_name
      }
    else:
      handle = UpdateProfile.update_profile(bio,display_name,cognito_user_id)
      data = UpdateProfile.query_users_short(handle)
      model['data'] = data
    return model

  def update_profile(bio,display_name,cognito_user_id):
    if bio == None:    
      bio = ''

    sql = db.template('users','update')
    handle = db.query_commit(sql,{
      'cognito_user_id': cognito_user_id,
      'bio': bio,
      'display_name': display_name
    })
  def query_users_short(handle):
    sql = db.template('users','short')
    data = db.query_object_json(sql,{
      'handle': handle
    })
    return data
 ```
 * Create a new files under bin/db:
`migrate`
 ```sh
 #!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value},verbose=False)
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


for migration_file in migration_files:
  filename = os.path.basename(migration_file)
  module_name = os.path.splitext(filename)[0]
  match = re.match(r'^\d+', filename)
  if match:
    file_time = int(match.group())
    if last_successful_run <= file_time:
      mod = importlib.import_module(module_name)
      print('=== running migration: ',module_name)
      mod.migration.migrate()
      timestamp = str(time.time()).replace(".","")
      last_successful_run = set_last_successful_run(timestamp)
```
`rollback`
 ```sh
 #!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      print("==<><>")
      print(last_successful_run, file_time)
      print(last_successful_run > file_time)
      if last_successful_run > file_time:
        last_migration_file = module_name
        mod = importlib.import_module(module_name)
        print('=== rolling back: ',module_name)
        mod.migration.rollback()
        set_last_successful_run(file_time)
```
* Create following files under frontend-react-js/src/components folder:
`Popup.css`
```css
.popup_form_wrap {
    z-index: 100;
    position: fixed;
    height: 100%;
    width: 100%;
    top: 0;
    left: 0;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: center;
    padding-top: 48px;
    background: rgba(255,255,255,0.1)
  }

  .popup_form {
    background: #000;
    box-shadow: 0px 0px 6px rgba(190, 9, 190, 0.6);
    border-radius: 16px;
    width: 600px;
  }

  .popup_form .popup_heading {
    display: flex;
    flex-direction: row;
    border-bottom: solid 1px rgba(255,255,255,0.4);
    padding: 16px;
  }

  .popup_form .popup_heading .popup_title{
    flex-grow: 1;
    color: rgb(255,255,255);
    font-size: 18px;

  }
```
`ProfileForm.css`
```css
form.profile_form input[type='text'],
form.profile_form textarea {
  font-family: Arial, Helvetica, sans-serif;
  font-size: 16px;
  border-radius: 4px;
  border: none;
  outline: none;
  display: block;
  outline: none;
  resize: none;
  width: 100%;
  padding: 16px;
  border: solid 1px var(--field-border);
  background: var(--field-bg);
  color: #fff;
}

.profile_popup .popup_content {
  padding: 16px;
}

form.profile_form .field.display_name {
  margin-bottom: 24px;
}

form.profile_form label {
  color: rgba(255,255,255,0.8);
  padding-bottom: 4px;
  display: block;
}

form.profile_form textarea {
  height: 140px;
}

form.profile_form input[type='text']:hover,
form.profile_form textarea:focus {
  border: solid 1px var(--field-border-focus)
}

.profile_popup button[type='submit'] {
  font-weight: 800;
  outline: none;
  border: none;
  border-radius: 4px;
  padding: 10px 20px;
  font-size: 16px;
  background: rgba(149,0,255,1);
  color: #fff;
}
```
`ProfileForm.js`
```js
import './ProfileForm.css';
import React from "react";
import process from 'process';
import {getAccessToken} from 'lib/CheckAuth';

export default function ProfileForm(props) {
  const [bio, setBio] = React.useState(0);
  const [displayName, setDisplayName] = React.useState(0);

  React.useEffect(()=>{
    console.log('useEffects',props)
    setBio(props.profile.bio);
    setDisplayName(props.profile.display_name);
  }, [props.profile])

  const onsubmit = async (event) => {
    event.preventDefault();
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/profile/update`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          bio: bio,
          display_name: displayName
        }),
      });
      let data = await res.json();
      if (res.status === 200) {
        setBio(null)
        setDisplayName(null)
        props.setPopped(false)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }

  const bio_onchange = (event) => {
    setBio(event.target.value);
  }

  const display_name_onchange = (event) => {
    setDisplayName(event.target.value);
  }

  const close = (event)=> {
    if (event.target.classList.contains("profile_popup")) {
      props.setPopped(false)
    }
  }

  if (props.popped === true) {
    return (
      <div className="popup_form_wrap profile_popup" onClick={close}>
        <form 
          className='profile_form popup_form'
          onSubmit={onsubmit}
        >
          <div class="popup_heading">
            <div class="popup_title">Edit Profile</div>
            <div className='submit'>
              <button type='submit'>Save</button>
            </div>
          </div>
          <div className="popup_content">
            <div className="field display_name">
              <label>Display Name</label>
              <input
                type="text"
                placeholder="Display Name"
                value={displayName}
                onChange={display_name_onchange} 
              />
            </div>
            <div className="field bio">
              <label>Bio</label>
              <textarea
                placeholder="Bio"
                value={bio}
                onChange={bio_onchange} 
              />
            </div>
          </div>
        </form>
      </div>
    );
  }
}
```
* As per Andrew's guidance, update:
 - `backend-flask.env.erb`
 - `App.js`
 - `ProfileHeading.css`
 - `ProfileHeading.js`
 - `ReplyForm.css`
 - `UserFeedPage.js`

## Create Lambda function for API
* Follow the images (rest leave as default):
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/c4a4c00b-ec20-42f2-8fcb-67018af82463)
* Create a new folder called cruddur-upload-avatar under aws/lambdas and create a fille called `function.rb`:
```rb
```
* On the cli type the following under /aws/lambdas/cruddur-upload-avatar:
```sh
bundle init
```
```sh
bundle install
```
* Give permissions to S3 lambda:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/cf72caf1-1387-4c54-b49a-141823ef677a)
* Copy the json code to a new file named `s3-upload-avatar-presigned-url-policy`, under aws/policies:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::ramirotech-uploaded-avatars/*"
        }
    ]
}
```
* Change the below parameters:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/81302fdc-c4de-422e-8b94-ed942d924a20)
* Change the lambda file name and add the code:
```rb
require 'aws-sdk-s3'
require 'json'

def handler(event:, context:)
  puts event
  s3 = Aws::S3::Resource.new
  bucket_name = ENV["UPLOADS_BUCKET_NAME"]
  object_key = 'mock.jpg'

  obj = s3.bucket(bucket_name).object(object_key)
  url = obj.presigned_url(:put, expires_in: 60 * 5)
  url # this is the data that will be returned
  body = {url: url}.to_json
  { statusCode: 200, body: body }
end
```
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/af0e9b7a-26a8-450c-b234-7730892cf08f)
* Test taht everything works ok:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/98ceeaee-7cb7-44e6-99cc-5955dbc164ef)
* Create a new folder calles lambda-authorizer under aws/lambdas and create a file called `index.js`:
```js
"use strict";
const { CognitoJwtVerifier } = require("aws-jwt-verify");
//const { assertStringEquals } = require("aws-jwt-verify/assert");

const jwtVerifier = CognitoJwtVerifier.create({
  userPoolId: process.env.USER_POOL_ID,
  tokenUse: "access",
  clientId: process.env.CLIENT_ID//,
  //customJwtCheck: ({ payload }) => {
  //  assertStringEquals("e-mail", payload["email"], process.env.USER_EMAIL);
  //},
});

exports.handler = async (event) => {
  console.log("request:", JSON.stringify(event, undefined, 2));

  const jwt = event.headers.authorization;
  try {
    const payload = await jwtVerifier.verify(jwt);
    console.log("Access allowed. JWT payload:", payload);
  } catch (err) {
    console.error("Access forbidden:", err);
    return {
      isAuthorized: false,
    };
  }
  return {
    isAuthorized: true,
  };
};
```
* Run the following on cli under aws/lambdas/lambda-authorizer:
```sh
npm install aws-jwt-verify --save
```
* Download the four files and/or folders and zip them together on a file called `lambda-authorizer`:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/9d356cbe-a90e-4477-a2d3-a0c0c81eb17b)
* Create a new lambda function called CruddurApiGatewayLambdaAuthorizer`:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/ae624c36-1a63-4a37-8269-b8a5656f319a)
* Rest leave as default.
* Upload the zip file to the lambda function:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/2c5891a4-cd78-401b-95cf-6e46c779142e)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/5c98cb01-a83a-471a-b8ec-fff3b0a81334)
* Create an HTTP APIGateway:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/a2861f71-e5db-4da1-9806-2a02ca76a837)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/95765e5f-073e-4bb2-b23a-581f331a0cb1)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/50992223-21fa-4df7-99cb-57271407f2d3)
* Click on create and follow the images:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/cb37af04-e1bb-4863-8f94-80bf1cf1e583)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/cb7cad94-0e56-4793-a68a-bdc3a274329b)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/0ed2745c-8bcf-4265-8a40-b87a7f3916f3)
* Click on attach authorizer:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/33fc6d99-3a46-47d9-b401-77b6583db9a0)
* With that you can get the invoke URL:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/2a93869a-94cb-45fb-bebf-7b88223d2ead)





