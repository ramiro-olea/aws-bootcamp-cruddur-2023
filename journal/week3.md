# Week 3 — Decentralized Authentication

# AWS Cognito
AWS Cognito is a secure identity and access management for apps. To create a cognito user pool, AWS UI is used. Follow the following steps to create a user pool succesfully:
* Choose Cognito on the search services bar:
![image](https://user-images.githubusercontent.com/62669887/223292471-fcd06cfc-36d2-4f16-a6e1-92e5985265fe.png)
* Click on create user pool on the AWS console:
![image](https://user-images.githubusercontent.com/62669887/223292330-f3beb4cd-a664-45db-9650-03ec598f1f79.png)
* Leave cognito user pool selected (per default) and on Cognito user pool sing-in options, select user name and email, and click next:
![image](https://user-images.githubusercontent.com/62669887/223292757-4a190d29-7ac1-4296-a350-5ff8776bfbcb.png)
* On password policy select Cognito defaults. For Multi-factor authentication select Non-MFA. In user account recovery select Enable self-service account recovery and email only, and click next:
![image](https://user-images.githubusercontent.com/62669887/223293263-bb542cb2-0ec4-41a6-b30a-7c709f967a38.png)
* On the next step, enable Enable self-registration, then select Allow Cognito to automatically send messages to verify and confirm and Send email message, verify email address. Next select Keep original attribute value active when an update is pending and leave email selected (per default). On required attributes, add name attribute; custom attributes are left blank:
![image](https://user-images.githubusercontent.com/62669887/223294394-22e0df0b-9e07-4e5f-ab75-ceb7cebdd635.png)
* On the next step, select Sen email with cognito and leave everyting else as per default and click next:
![image](https://user-images.githubusercontent.com/62669887/223294850-32e46126-c086-4515-a573-2eab8948f8cb.png)
* On the next step name the user pool: cruddur-user-pool. Disable Use the Cognito Hosted UI. Select Public client and name the app: Cruddur and select Don't generate a client secret; rest leave as per default and click next:
![image](https://user-images.githubusercontent.com/62669887/223296240-ebc395a0-b65d-48ad-8ac8-b92f8a4c6942.png)
* Click revie and create and verify that the user-pool has been created:
![image](https://user-images.githubusercontent.com/62669887/223296439-6d76bb38-741b-4f7c-9326-91535b7b92a0.png)
