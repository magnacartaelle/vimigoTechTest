# Vimigo Technical Test
*Submission by Yeoh Hui Jia*


## Brief
This is my submission for the technical test provided. You may find the code all committed to this Git repository.
In addition, I have included a PDF document elaborating a little more with regards to my take on the given brief and problem statement.

## The POC Application
The application is written in **Dart for Flutter**. However, testing is done mostly on iOS due to my lack of an Android device.
It essentially consist of:
**1. A task list**
- From the task list screen, the application wlil attempt to pull the latest via API. Else, it will opt to take the task list via local storage
- The 'reload' button forces a call to get the latest data via API (similar to a pull to refresh behaviour) without clearing the local copy
- The 'reset all' button will clear the local copies before pulling the latest data via API.

**2. Task details**
- Simple page showing the task title, details, status and the ability to update the status at the push of a button. 
- Status change will move according to: Not started -> In progress -> Resolved -> Closed. 

**3. Periodic data pull**
- As long as the app remains in the foreground, the app will attempt to sync and pull the latest changes via API
- The pulling will occur every 1 minute (can be adjusted).

**Background data fetching**
- If the app is pushed to the background, the app will attempt to sync and pull the latest changes via API
- The fetching occur 15 minutes (limitation on Android platform).

**Pending Update List**
- If the app loses internet connectivity when user attempts to update a task, it is placed into a pending list
- Once the app regains internet connectivity, the pending list is iterated through and updates are pushed to the server one by one. 


## API
There is also a mock API that I used to more closely mimic a server-mobile interaction for a mobile application.
Done using *MockAPI*, you may access the API calls via *Postman* client [here](https://www.getpostman.com/collections/70ff7febe66bdc025eb3)
or refer to the appendix in the mentioned PDF document.

## Dependencies
This POC has some dependencies: 
1. http: For API calls
2. sqflite: For local storage
3. path: Works with sqflite for storage path purposes
4. background_fetch: For background data fetch handling
5. shared_preferences: For accessing Shared Preferences / NSUserDefaults

## PDF Submission Document
More details related to the submission can be found in my submission PDF named [YHJ-VimigoTechTestSubmission.pdf](YeohHuiJia-FinalSubmission.pdf)
