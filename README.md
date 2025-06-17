# identity_portal
Analysis of Symantec Identity Portal business logic using Windows Powershell json filtering

# How to use
You may use MS Windows Powershell ISE to run and monitor.
- These were developed on MS Win 2019 Powershell 5.1
![image](https://github.com/user-attachments/assets/e63de256-ec69-4459-a9d0-4d4b75f21768)


# PRETTY JSON
Use the pretty json script to convert the one-liner-compressed json to human readable format for any export.
This 1st script will allow you to convert either a full or subset export to pretty json.   
This script allows the file to be re-imported if wished.   
We found this useful for the plugins export during migrations.
![image](https://github.com/user-attachments/assets/0276263d-3f9a-4a5d-977d-18aa037983b5)

BEFORE:  (one-liner-compressed json)
![image](https://github.com/user-attachments/assets/7213dfd1-5516-4582-a248-ee29c37dd6ab)

AFTER:  (pretty json - human readable/searchable) - Noticed the file is now over 5000 lines.
![image](https://github.com/user-attachments/assets/e2a2efd6-f287-4a75-bfda-3c179e6a9ecf)


# DELTAS - WINMERGE - FULL / FORMS / PLUGINS

We find our 2nd script with WinMerge useful as a high-level review of any deltas to compare between environments.  
This 2nd script will require two (2) full exports of the environment.
As the plugins configurations will likely have different hostnames and credentials.
These files are for search/research usage, they can not be re-imported.   
Updates will be/should be made within the Identity Portal Admin Mgmt UI.

![image](https://github.com/user-attachments/assets/cb9722d9-9c7a-444b-a06d-17de14d1a20e)

![image](https://github.com/user-attachments/assets/2eec6951-464e-4d25-b2a7-093206e6aa08)

![image](https://github.com/user-attachments/assets/2631c181-f3d8-44fc-ab73-8c0014f8e058)



# FORMS / LAYOUT / JAVASCRIPT

Finally, for the complex 'layout' property that may contains 1000's of lines of javascript within the Identity Portal Forms, we would recommend that single forms be exported to be reviewed.
This 3rd script will use Notepad++ to host all the exported logic from a single Identity Portal Form in a sorted format.
The individual notepad++ files can then be compared with WinMerge between environments or time-stamp deltas.
These files are for search/research usage, they can not be re-imported.
Updates will be/should be made within the Identity Portal Admin Mgmt UI.

![image](https://github.com/user-attachments/assets/37f18706-b315-4615-af1e-ad0bb1ec8e75)
