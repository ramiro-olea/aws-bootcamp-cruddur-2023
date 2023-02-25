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

cd frontend-react-js

npm i

* Once you install what is required, you will have to make public the port so you can see the website running:
![image](https://user-images.githubusercontent.com/62669887/221332228-ee96da2f-6190-488b-915e-6b6486690826.png)
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


