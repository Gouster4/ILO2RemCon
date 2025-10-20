@echo off
setlocal enabledelayedexpansion

set CONFIG_FILE=config.properties
set ILO_SCRIPT=bin\ILO2RemCon.bat

:: Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo Config file not found. Creating new configuration...
    echo.
    
    set "input_ssh_hostname="
    set "input_ssh_login="
    
    :ask_ssh
    set /p "input_ssh_hostname=Enter SSH server: "
    
    :: Check if user entered user@server format
    echo !input_ssh_hostname! | find "@" >nul
    if !errorlevel! equ 0 (
        :: Split user@server format
        for /f "tokens=1,2 delims=@" %%a in ("!input_ssh_hostname!") do (
            set "input_ssh_login=%%a"
            set "input_ssh_hostname=%%b"
        )
    ) else (
        :: Ask for username separately
        set /p "input_ssh_login=Enter SSH username: "
    )
    
    set /p "input_sshpass=Enter SSH password: "
    
    set /p "input_ip=Enter iLO 2 IP address: "
    set /p "input_username=Enter iLO 2 username: "
    set /p "input_password=Enter iLO 2 password: "
    
    :: Merge SSH login and hostname with @ (if not already done)
    if not defined input_ssh_login (
        echo Error: SSH username not defined!
        goto ask_ssh
    )
    set "input_ssh=!input_ssh_login!@!input_ssh_hostname!"
    
    :: Create config file WITHOUT trailing spaces
    echo ip=!input_ip!> "%CONFIG_FILE%"
    echo username=!input_username!>> "%CONFIG_FILE%"
    echo password=!input_password!>> "%CONFIG_FILE%"
    echo hostname=localhost>> "%CONFIG_FILE%"
    echo ssh=!input_ssh!>> "%CONFIG_FILE%"
    echo sshpass=!input_sshpass!>> "%CONFIG_FILE%"
    
    echo.
    echo Configuration saved to %CONFIG_FILE%
) else (
    echo Reading configuration from %CONFIG_FILE%
)

:: Simple approach - source the config file directly
for /f "usebackq delims=" %%i in ("%CONFIG_FILE%") do (
    set "line=%%i"
    set "!line!"
)

:: Display configuration
echo.
echo Using configuration:
if defined ssh echo SSH: %ssh%
if defined ip echo IP: %ip%
if defined username echo Username: %username%
echo.

:: Validate required variables
if not defined ssh (
    echo Error: SSH configuration not found!
    pause
    exit /b 1
)

:: Remove any spaces from variables (just in case)
set "clean_ip=%ip: =%"
set "clean_ssh=%ssh: =%"
set "clean_sshpass=%sshpass: =%"

:: Start SSH tunnel in background
echo Starting SSH tunnel in background...
echo.

:: Use Plink with -no-antispoof to automatically start session
echo Using Plink for SSH tunnel with password authentication...
start "SSH Tunnel" /B plink -ssh -N -pw "%clean_sshpass%" -no-antispoof -L 443:%clean_ip%:443 -L 17990:%clean_ip%:17990 -L 17988:%clean_ip%:17988 -L 22:%clean_ip%:22 -L 23:%clean_ip%:23 %clean_ssh%

:: Wait a moment for tunnel to establish
echo Waiting for SSH tunnel to establish...
timeout /t 3 /nobreak >nul
echo Ports forwarded from %clean_ip% to localhost: 443, 17990, 17988, 22, 23

:: Check if ILO script exists and run it
if exist "%ILO_SCRIPT%" (
    echo Launching ILO Remote Console...
    call "%ILO_SCRIPT%"
) else (
    echo Warning: %ILO_SCRIPT% not found.
)

:: Kill the SSH tunnel when done
echo Closing SSH tunnel...
taskkill /im plink.exe /f >nul 2>&1
echo Done.
exit
