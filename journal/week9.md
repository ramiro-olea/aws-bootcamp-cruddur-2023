# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy
* Go to CodePipeline in AWS console and click on Create Pipeline:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/cc5402ab-0861-4a89-8676-99bb44953c7b)
* Put the Pipiline name and rest leaveas default:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/e3b0fcae-a0f1-4991-aa07-0e87619acf42)
* Click on Connec to to GitHub:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/849f7120-5a9d-4a30-aa75-dcfd65fb948f)
* Create a connection name and click Connect to GitHub:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/cac1c3bc-9192-48bc-a7de-9c9dc48ed104)
* Click install a new app:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/dbafc249-9c40-4f27-9847-d1e92342aad8)
* Select repositorie and click install:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/2753bf53-365c-4abd-a9e4-5374465731d7)
* If the connection is succesfull, you will get some numbers on the app, and then click connect:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/3e3d8c7b-8fc4-44f4-8106-419b530d5d28)
* Create a new branch on GitHub called prod:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/9f81ef36-9335-44d8-a941-e8df88f22c3e)
* Get the info as in the image and click next:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/af05c603-c8e3-4b46-8962-1396ce901f9d)
* Follow the steps on the image and click next (skip CodeBuild for now):
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/580fe800-15c8-4486-8eb0-36179f2123d9)
* Review verything is ok, and click create pipeline.
* Create a new CodeBuild project and click build CodeBuild:
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/60541640-5c0b-410d-bbdb-ec64549a2a39)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/33392fa1-3937-40a3-be94-8b706fc27776)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/7588a32f-0c04-4dad-96b0-b7676e611b4e)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/3ff843c9-878f-4902-b017-bde29a04fb73)
![image](https://github.com/ramiro-olea/aws-bootcamp-cruddur-2023/assets/62669887/74394a67-8257-4f94-84b8-9b4cddf07664)

** Troubleshooting:
 - Remove VPC from CodeBuild
 - Remove env vars from buildspec.yml
