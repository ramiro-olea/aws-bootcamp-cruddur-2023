# Week 2 — Distributed Tracing

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
