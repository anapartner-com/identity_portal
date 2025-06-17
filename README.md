# identity_portal
Analysis of Symantec Identity Portal business logic using Windows Powershell json filtering


You may use MS Windows Powershell ISE to run and monitor.
- These were developed on MS Win 2019 Powershell 5.1
![image](https://github.com/user-attachments/assets/e63de256-ec69-4459-a9d0-4d4b75f21768)


Use the pretty json script to convert the one-liner-compressed json to human readable format for any export.

![image](https://github.com/user-attachments/assets/0276263d-3f9a-4a5d-977d-18aa037983b5)

We find this useful to review the plugins export.  To compare between environments.  
As the plugins configurations will likely have different hostnames and credentials.

![image](https://github.com/user-attachments/assets/1cfdffc0-2943-439c-b386-a80488ea76c0)

Finally, for the complex 'layout' property that may contains 1000's of lines of javascript within the Identity Portal Forms, we would recommend that single forms be exported to be reviewed.

![image](https://github.com/user-attachments/assets/37f18706-b315-4615-af1e-ad0bb1ec8e75)
