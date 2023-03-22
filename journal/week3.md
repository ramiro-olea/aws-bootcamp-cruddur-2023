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
* On the next step, select Send email with cognito and leave everyting else as per default and click next:
![image](https://user-images.githubusercontent.com/62669887/223294850-32e46126-c086-4515-a573-2eab8948f8cb.png)
* On the next step name the user pool: cruddur-user-pool. Disable Use the Cognito Hosted UI. Select Public client and name the app: Cruddur and select Don't generate a client secret; rest leave as per default and click next:
![image](https://user-images.githubusercontent.com/62669887/223296240-ebc395a0-b65d-48ad-8ac8-b92f8a4c6942.png)
* Click revie and create and verify that the user-pool has been created:
![image](https://user-images.githubusercontent.com/62669887/223296439-6d76bb38-741b-4f7c-9326-91535b7b92a0.png)

## AWS Amplify
* Install AWS Amplify on Gitpod workspace:
```sh
cd frontend-react-js
npm i aws-amplify --save
```
![image](https://user-images.githubusercontent.com/62669887/223298404-af696963-5ab8-44bd-a3fb-834c5f4a32e2.png)
* Add the following code in app.js:
```sh
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```
![image](https://user-images.githubusercontent.com/62669887/223299898-b284d614-44f4-48cd-8d3d-f7dd277be6d9.png)
* Update docker compose file with the following information below the frontend-react-js - environment:
```sh
      REACT_AWS_PROJECT_REGION: ""
      REACT_APP_AWS_COGNITO_REGION: ""
      REACT_APP_AWS_USER_POOLS_ID: ""
      REACT_APP_CLIENT_ID: ""
```
![image](https://user-images.githubusercontent.com/62669887/223302402-a22d84c3-b978-4778-8401-ade0c11b7e51.png)

* On HomeFeedPage.js add the next code:
```sh
import { Auth } from 'aws-amplify';

const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

// check when the page loads if we are authenicated
React.useEffect(()=>{
  loadData();
  checkAuth();
}, [])
```
* On ProfileInfo.js add the following code:
```sh
import { Auth } from 'aws-amplify';

const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```
* Add the following on GitPod CLI in order to have the user registered on Cruddur:
```sh
aws cognito-idp admin-set-user-password --username xxxxxxxx --password xxxxxxxxx --user-pool-id xxxxxxx --permanent
```
* Update AWS Cognito in order to show name and user name:
![image](https://user-images.githubusercontent.com/62669887/224848802-b7ac2227-1274-417e-a0ad-0b0bad9d7e1f.png)
![image](https://user-images.githubusercontent.com/62669887/224848889-c13548c5-1a64-44f5-975b-b6c6e6e25208.png)

* Create Signup Page
* Delete Coginito user
* Add following command in SignupPage.js:
```js
import { Auth } from 'aws-amplify';

const [cognitoErrors, setCognitoErrors] = React.useState('');

const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
  } catch (error) {
      console.log(error);
      setErrors(error.message)
  }
  return false
}

let errors;
if (cognitoErrors){
  errors = <div className='errors'>{cognitoErrors}</div>;
}

//before submit component
{errors}
```
* Add following code to ConfirmationPage.js:
```js
import { Auth } from 'aws-amplify';

const resend_code = async (event) => {
  setCognitoErrors('')
  try {
    await Auth.resendSignUp(email);
    console.log('code resent successfully');
    setCodeSent(true)
  } catch (err) {
    // does not return a code
    // does cognito always return english
    // for this to be an okay match?
    console.log(err)
    if (err.message == 'Username cannot be empty'){
      setCognitoErrors("You need to provide an email in order to send Resend Activiation Code")   
    } else if (err.message == "Username/client id combination not found."){
      setCognitoErrors("Email is invalid or cannot be found.")   
    }
  }
}

const onsubmit = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  try {
    await Auth.confirmSignUp(email, code);
    window.location.href = "/"
  } catch (error) {
    setCognitoErrors(error.message)
  }
  return false
}
* Create a new user pol using only email as sign in.
* User has to be created.
* Recover password:
* Add the following code in RecoverPage.js:
```js
import { Auth } from 'aws-amplify';

const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setCognitoErrors(err.message) );
  return false
}

const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setCognitoErrors(err.message) );
  } else {
    setCognitoErrors('Passwords do not match')
  }
  return false
}
```
![image](https://user-images.githubusercontent.com/62669887/224862070-93017018-8267-4531-a32b-d263f2943b13.png)
![image](https://user-images.githubusercontent.com/62669887/224862142-f9c1efe2-6556-4a87-8808-230ebaf31687.png)
![image](https://user-images.githubusercontent.com/62669887/224862235-4f4b4d87-12fc-49ab-921b-b2cf47b3b69b.png)

* In `HomeFeedPage.js` add header to pass along the access token:
```js
  headers: {
    Authorization: `Bearer ${localStorage.getItem("access_token")}`
  }
```
* In `app.py` add the following code:
```py
cors = CORS(
  app, 
  resources={r"/api/*": {"origins": origins}},
  headers=['Content-Type', 'Authorization'], 
  expose_headers='Authorization',
  methods="OPTIONS,GET,HEAD,POST"
)
```
* Add in `requirements.txt` the following:
```sh
Flask-AWSCognito
```
* If you want, you can change some coloring of the UI, playing with different colors using Chrome inspect tool (I did).
![image](https://user-images.githubusercontent.com/62669887/226773932-2bf3272b-d8e4-4a71-a79c-87688f20aab2.png)

