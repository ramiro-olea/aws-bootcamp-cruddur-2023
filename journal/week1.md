# Week 1 — App Containerization

***These steps were followed from https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-1/journal/week1.md ***

## GitPod 
Gitpod Workspaces can be used for an easier integration and testing of your code/repo. Gitpod extension can be installed from Chrome extension site. 

![image](https://user-images.githubusercontent.com/62669887/221330327-7b500ae3-1481-45bd-98db-ae14cd5957a7.png)

Once the workspace is loaded, you can edit and add different extensions to run on your workspace every time you start that worspace. This can be modified on the Gitpod.yml file; in this case we are adding some extensions:

![image](https://user-images.githubusercontent.com/62669887/221330591-51867bf9-ad72-475d-9d7a-0912cb676097.png)

## Test your App

In order to test your application, one thing you can do is to test it locally first to see if everything is working correctly.

Run the next commands to see if the backend works as required:

- cd backend-flask
- export FRONTEND_URL="*"
- export BACKEND_URL="*"
- pip3 install -r requirements.txt
- python3 -m flask run --host=0.0.0.0 --port=4567

* When you first run the flask application, the port will be not public, clic on the padlock to make it public and the clic on the URL next to it:
![image](https://user-images.githubusercontent.com/62669887/221331454-e78a7a05-3479-447c-840a-d1fd8fc0e076.png)
* After loading the URL, it will send an error saying that the page was not found; this is good as it represents that the backend is wokring but there is nothing to show yet. 
* In the URL add /api/activities/home and you will get a json output, this means that the backend is working correctly.
![image](https://user-images.githubusercontent.com/62669887/221331562-4eea7e47-2fbf-48ae-9437-c829ffdb17eb.png)

## Containerize Frontend and Backend

In order to contenirize your application, you have to create a Dockerfile, build it and then run it to test.
![image](https://user-images.githubusercontent.com/62669887/221332005-6d3c931c-4dac-48a3-b7ef-1a4781c967e9.png)

* docker build -t  backend-flask ./backend-flask
* docker build -t frontend-react-js ./frontend-react-js
* docker run --rm -p 4567:4567 -it backend-flask
* docker run -p 3000:3000 -d frontend-react-js

**It's really important to note that to run the frontend, some coding is required before running the application:
```
cd frontend-react-js
npm i

* Once you install what is required, you will have to make public the port so you can see the website running:
![image](https://user-images.githubusercontent.com/62669887/221335502-d35cc84a-591e-41a7-8d18-4a9355df50a6.png)
![image](https://user-images.githubusercontent.com/62669887/221332249-2c1d56e9-ae51-492a-bf16-447d8c60051d.png)

You can run the containers together instead of running them independently using docker compose. A file has to be created and then you will be able to run the containers you want at the same time:
![image](https://user-images.githubusercontent.com/62669887/221332446-778bfb59-b0c0-4b09-aed2-03ccbf21ee46.png)
If you want, you can run the docker compose from the GUI or you can use the terminal.

## Examing and editing Backend and Frontend code

Add notifications module to the API:
* openapi-3.0.yml file has to be edited so notifications module is added:
![image](https://user-images.githubusercontent.com/62669887/221332737-a58ba12d-53c6-4322-aa82-27990e50e7d6.png)
* Add notifications.py code to the backend folder, and then update app.py code so notifications module can be reached:
![image](https://user-images.githubusercontent.com/62669887/221332681-ac478743-06e9-43eb-b80e-8c1969bd1aaa.png)

* From frontend perspective, notificationsfeedpage.js has to be added in order to see this module on the website and app.js has to be updated in order to call new notifications site:
![image](https://user-images.githubusercontent.com/62669887/221335050-f814f323-8de5-44c7-9994-dad9b394d277.png)
![image](https://user-images.githubusercontent.com/62669887/221335062-34c6f6bf-30af-46f7-a5c6-99669b69ea3c.png)

* After this, frontend will be ready with the new notifications module:
![image](https://user-images.githubusercontent.com/62669887/221335089-aaf2f117-da3d-4651-a9fc-899686b20e7f.png)

## Local DynamoDB and Postgres

Just to be ready for the upcoming weeks, DynamoDB and Postgres are installed locally to test them, and the make the integration to the cloud service (in upcoming weeks). In order to do this, docker compose file has to be updated and some code lines ahd to be added:

Postgres
```yaml
services:
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data
volumes:
  db:
    driver: local
To install the postgres client into Gitpod
```yaml
  - name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
DynamoDB Local
```yaml
services:
  dynamodb-local:
    https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal

Volumes are also updated in the docker compose file:
  
directory volume mapping

volumes: 
- "./docker/dynamodb:/home/dynamodblocal/data"
named volume mapping

volumes: 
  - db:/var/lib/postgresql/data

volumes:
  db:
    driver: local

### Full docker compose file has to be something like this:
``` yaml
version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js
  dynamodb-local:
    https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data    
 #the name flag is a hack to change the default prepend folder
 #name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur

volumes:
  db:
    driver: local




