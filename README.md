# identity_portal
Analysis of Symantec Identity Portal business logic using Windows Powershell json filtering

# How to use
You may use MS Windows Powershell ISE to run and monitor.
- These were developed on MS Win 2019 Powershell 5.1
![image](https://github.com/user-attachments/assets/e63de256-ec69-4459-a9d0-4d4b75f21768)


# Pretty JSON
Use the pretty json script to convert the one-liner-compressed json to human readable format for any export.

![image](https://github.com/user-attachments/assets/0276263d-3f9a-4a5d-977d-18aa037983b5)

BEFORE:  (one-liner-compressed json)
![image](https://github.com/user-attachments/assets/7213dfd1-5516-4582-a248-ee29c37dd6ab)

AFTER:  (pretty json - human readable/searchable) - Noticed the file is now over 5000 lines.
![image](https://github.com/user-attachments/assets/e2a2efd6-f287-4a75-bfda-3c179e6a9ecf)


# PLUGINS

We find this useful to review the plugins export.  To compare between environments.  
As the plugins configurations will likely have different hostnames and credentials.

![image](https://github.com/user-attachments/assets/1cfdffc0-2943-439c-b386-a80488ea76c0)

Finally, for the complex 'layout' property that may contains 1000's of lines of javascript within the Identity Portal Forms, we would recommend that single forms be exported to be reviewed.

![image](https://github.com/user-attachments/assets/37f18706-b315-4615-af1e-ad0bb1ec8e75)
