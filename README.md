# PaullyGPT
A flavor of ChatGPT powered by PowerShell.

## Features
* Fast and Easy to Use ChatGPT in a Powershell console.
* Autosaves Conversation Transscripts to local text logs
* Enter your OpenAI API Key and begin right away
* Useful Text-To-Speech Audio

## Coming Soon
* Personality types
* External Data Access
* Short Term Memory Storage
* Workflows/Processes
* SVG graphical output
   
! Note:
Requires an openAi API subscription key, that will be saved when first loaded into a PaullyGPT.config.json file.

## Instructions

1. Unpack Zip file into a writable folder on a Windows compatible machine
2. If required, right-click on the paullygpt.bat and check the UNBLOCK checkbox on the bottom right of the dialog window to bypass the signed-executable checking. This bat file simply calls powershells and launches the ps1 script.
3. The first time it is run, you will be required to enter a valid OPENAI API KEY.
4. While using PaullyGPT, it will create a subfolder to contain transcript logs of the session as well as a config file containing the APIKEY to access OPENAI for future user.

## More Information
https://github.com/paullyvenne/paullygpt

#### EXE Binary Version (Win-PS2EXE)
https://www.dropbox.com/scl/fi/jkb85ndxqxirz0mejmlrc/paullygpt.v1.0.2.rar?rlkey=uzx3xvpl1b48vao46qu8733n0&dl=0

! Note:
EXEs created with WIN-PS2EXE maybe generate false malware positives. If this is a problem please adjust your Windows Defender exclusions or use the Powershell script version. 
