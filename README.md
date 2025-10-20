# ILO2RemCon
iLO 2 Standalone remote console over SSH

Runs on Java version.


Creates SSH tunnel to gateway to access needed iLO 2 ports directly from localhost and runs remote console.

SSH connection is supposed to be to firewall, router or other remote machine that sits on same network as iLO 2.

Then iLO 2 ip is specified and remote cosole connects to iLO 2 ip troght SSH connection.

SSH tunnel is being created using plink.exe (PuTTY) https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

# Warning
Passwords are stored in plain text!

# Source
Based on: https://github.com/scrapes/ILO2-Standalone-Remote-Console
