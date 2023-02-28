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

opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests

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
![image](https://user-images.githubusercontent.com/62669887/221956472-f5a71140-902d-462c-bf11-7afebfa62ac9.png)
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



