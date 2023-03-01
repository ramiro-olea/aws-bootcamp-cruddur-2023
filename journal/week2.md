# Week 2 — Distributed Tracing

* Add the following code to gitpod.yml file, so ports can be automatically opened:
```sh
ports:
  - name: frontend
    port: 3000
    onOpen: open-browser
    visibility: public
  - name: backend
    port: 4567
    visibility: public
  - name: xray-daemon
    port: 2000
    visibility: public
```
![image](https://user-images.githubusercontent.com/62669887/221718304-feda45e9-fd68-4798-b280-7b4feea01377.png)


## HoneyComb

* Create a new environment for the cruddr app on your HoneyComb account:
![image](https://user-images.githubusercontent.com/62669887/221710523-7f713673-0173-49ea-9176-a265e9f7139a.png)

* On you Gitpod workspace, save environment variable for your HoneyComb API key retrieved from the HoneyComb environment:
```sh
gp env HONEYCOMB_API_KEY=""
```
* On the Docker compose file, add the open telemetry variables for HoneyComb:
```sh
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
OTEL_SERVICE_NAME: "backend-flask"
```
* On requirements.txt add the following and save:
```sh
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
* Install the dependencies on the gitpod workspace:
```sh
cd backend-flask/
pip install -r requirements.txt
```
* Add the following code on the app.py file:
```sh
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
```
![image](https://user-images.githubusercontent.com/62669887/221714158-4b660bbf-c283-475d-8fd0-dc1a69b5a4eb.png)

* In order to initialize tracing, add the following code to the app.py file:
```sh
# Honeycomb -------
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```
![image](https://user-images.githubusercontent.com/62669887/221714588-1c481980-2e59-4bd2-8c89-3462c4f08963.png)

* To initialize automatic instrumentation with Flask, add the following code to app.py (below app = Flask(__name__) code):
```sh
# Honeycomb -------
# Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
![image](https://user-images.githubusercontent.com/62669887/221714828-41f78d8a-37a0-42c3-b50d-7d23a1462969.png)

* In order to add an span you can go, for example, to home_activities.py and add some coding, so HoneyComb can get that data. Full code should be something like this:
```yaml
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run():
    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()
      span.set_attribute("app.now", now.isoformat())
      results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'Andrew Brown',
      'message': 'Cloud is fun!',
      'created_at': (now - timedelta(days=2)).isoformat(),
      'expires_at': (now + timedelta(days=5)).isoformat(),
      'likes_count': 5,
      'replies_count': 1,
      'reposts_count': 0,
      'replies': [{
        'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
        'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Worf',
        'message': 'This post has no honor!',
        'likes_count': 0,
        'replies_count': 0,
        'reposts_count': 0,
        'created_at': (now - timedelta(days=2)).isoformat()
      }],
    },
    {
      'uuid': '66e12864-8c26-4c3a-9658-95a10f8fea67',
      'handle':  'Worf',
      'message': 'I am out of prune juice',
      'created_at': (now - timedelta(days=7)).isoformat(),
      'expires_at': (now + timedelta(days=9)).isoformat(),
      'likes': 0,
      'replies': []
    },
    {
      'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
      'handle':  'Garek',
      'message': 'My dear doctor, I am just simple tailor',
      'created_at': (now - timedelta(hours=1)).isoformat(),
      'expires_at': (now + timedelta(hours=12)).isoformat(),
      'likes': 0,
      'replies': []
    }
    ]
    span.set_attribute("app.result_length", len(results))
    return results
 ```
 ![image](https://user-images.githubusercontent.com/62669887/221728628-bdd36ec3-05ed-4fa8-9811-837c5af9fc96.png)

** It is really important to get the API_KEY environment set, if not, data will not be sent to HoneyComb**
* You can go to HoneyComb site and check all the spans and traces that were added, and check all the data it shows:
![image](https://user-images.githubusercontent.com/62669887/221729308-f21fd729-5949-4ba8-a365-e92ec6516b64.png)
![image](https://user-images.githubusercontent.com/62669887/221729523-0a30c4b6-1233-4b76-a983-2594bab02d9b.png)
![image](https://user-images.githubusercontent.com/62669887/221729379-6c729730-9b94-477f-a5b2-8396dd27bcf2.png)
![image](https://user-images.githubusercontent.com/62669887/221729465-761f0636-3cd4-4ec8-9153-c0a7e3b2ed2b.png)


# AWS X-Ray
* If you didn't set the AWS region enviornment, do it now:
```sh
export AWS_REGION="us-east-1"
gp env AWS_REGION="us-east-1"
```
* Add the following code to the requirements.txt file on backend-flask folder:
```sh
aws-xray-sdk
```
* On the same folder, add the following code in app.py file:
```sh
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)
```
![image](https://user-images.githubusercontent.com/62669887/222004169-2cca8ff3-d905-4d91-bc3f-656c978a44d2.png)
* In AWS/JSON folder, create a new file called xray.json and add the following code:
```json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```
* On the terminal create a new group for xray:
```sh
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
* You can review if the group is created on the AWS-X-ray GUI.
![image](https://user-images.githubusercontent.com/62669887/221958575-2f3e2d3b-c942-4b06-a361-d5372a0c83d0.png)
* Create a sampling rule on GitPod terminal:
```sh
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
![image](https://user-images.githubusercontent.com/62669887/221958511-8acd445a-3ffb-48d8-a513-78238480c4e5.png)

# Add Deamon Service as a container with Docker Compose
* Add following code to the Docker compose file:
```yaml
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```
* Add the following environment variables to the same Docker Compose file:
```yaml
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
```
![image](https://user-images.githubusercontent.com/62669887/222003118-835e151f-26c5-4150-a175-5aa10cc81aa1.png)

* Run Docker compose file and check if everything is working correctly. You can check X-ray traces in AWS GUI to confirm this:
![image](https://user-images.githubusercontent.com/62669887/222005287-1397c6e1-ff38-4331-83d1-0e4fb005b4b0.png)

# CloudWatch Logs
In order the app send logs to cloudWatch, following steps have to be followed:
* Add the following to requirements.txt:
```sh
watchtower
```
* Go to backend-flask folder and update:
```sh
pip install -r requirements.txt 
```
* Add the following code to app.py file:
```sh
import watchtower
import logging
from time import strftime

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("some message")

@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```
![image](https://user-images.githubusercontent.com/62669887/222016213-dba2013d-d516-4b7a-bcc1-fed93e1f8bee.png)
* Check in CloudWatch UI if group and logs have been created:
![image](https://user-images.githubusercontent.com/62669887/222015978-297c7f18-9928-4b45-95f9-30ef50e9e065.png)
![image](https://user-images.githubusercontent.com/62669887/222015901-10a9469c-45da-42e9-a7f2-8550365ed5e4.png)
![image](https://user-images.githubusercontent.com/62669887/222016101-e2469dce-a109-45c5-ac8a-e5e60c476c34.png)

# Rollbar
* Add the following in requirements.txt from backend-flask folder:
```sh
blinker
rollbar
```
* Install:
```sh
pip install -r requirements.txt
```
* Set the token variable on the workspace:
```sh
export ROLLBAR_ACCESS_TOKEN=" "
gp env ROLLBAR_ACCESS_TOKEN=" "
```
* In app.yml add the following code:
```yaml
import os
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception

rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```
* In order to test rollbar, we add an endpoint:
```yaml
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```
![image](https://user-images.githubusercontent.com/62669887/222018973-0de1f893-9816-4a47-93ef-630a7c084fc5.png)
* Test everything works correctly:
![image](https://user-images.githubusercontent.com/62669887/222019059-c22924d5-4c9d-40f2-84b1-3a5b1f2adb64.png)
![image](https://user-images.githubusercontent.com/62669887/222019695-eff6fa70-9b69-4679-a26b-e4dc6cdb5295.png)
![image](https://user-images.githubusercontent.com/62669887/222019861-3ed5601a-be65-42c0-a552-4ac4d5168ba0.png)


