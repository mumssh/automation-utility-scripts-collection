@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem ================================================================
rem Module Name: Advanced Windows Network Toolkit
rem File Name: advanced_network_toolkit_v1.1.cmd
rem Architect & Author: Lucilyn Tangian
rem Release Date: September 2026
rem Version: 1.1.0
rem
rem Description: A zero-dependency, native CMD diagnostic suite for
rem automated network triage, stateful logging, and secure TCP/IP
rem manipulation. Built with strict admin-elevation guardrails.
rem ================================================================

set "APP=Advanced Windows Network Toolkit v1.1"
title %APP%
color 0A

rem ------------------------------------------------
rem Configuration
rem ------------------------------------------------
set "LOGDIR=%USERPROFILE%\Documents\NetworkToolkitLogs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1
if not exist "%LOGDIR%" (
    echo ERROR: Unable to create log folder:
    echo %LOGDIR%
    pause
    exit /b 1
)

rem CMD-only timestamp. Date/time characters invalid in filenames are removed.
set "STAMP=%DATE%_%TIME%"
set "STAMP=%STAMP:/=-%"
set "STAMP=%STAMP:\=-%"
set "STAMP=%STAMP::=-%"
set "STAMP=%STAMP:.=-%"
set "STAMP=%STAMP:,=-%"
set "STAMP=%STAMP: =0%"
set "LOGFILE=%LOGDIR%\NetworkToolkit_%COMPUTERNAME%_%STAMP%_%RANDOM%.log"
set "TEMPLOG=%TEMP%\NetworkToolkit_%RANDOM%_%RANDOM%.tmp"
set "DROPARG=%~1"

rem ------------------------------------------------
rem Administrator check - no self-elevation
rem ------------------------------------------------
fltmc >nul 2>&1
if errorlevel 1 (
    color 0C
    cls
    echo ================================================================
    echo ADMINISTRATOR RIGHTS REQUIRED
    echo ================================================================
    echo.
    echo Right-click this file and select Run as administrator.
    echo If an approved privilege manager is installed, use the
    echo organization's approved elevation method.
    echo.
    echo The toolkit will now exit.
    pause
    exit /b 1
)

call :LogHeader

rem ------------------------------------------------
rem Drag-and-drop mode
rem ------------------------------------------------
if defined DROPARG (
    call :ResolveDrop "%DROPARG%"
    if defined TARGET (
        call :TargetTest "%TARGET%"
    ) else (
        echo No valid target could be identified.
        pause
    )
    goto CLEANEXIT
)

:MENU
cls
echo ================================================================
echo %APP%
echo ================================================================
echo Computer : %COMPUTERNAME%
echo Logs     : %LOGDIR%
echo.
echo READ-ONLY DIAGNOSTICS
echo ------------------------------------------------
echo [1]  Show full IP configuration
echo [2]  Ping a target
echo [3]  Continuous ping
echo [4]  DNS lookup
echo [5]  Trace route
echo [6]  Display routing table
echo [7]  Display ARP cache
echo [8]  Display active connections
echo [9]  Show Wi-Fi interface details
echo [10] Collect diagnostic bundle
echo.
echo WINDOWS TOOLS
echo ------------------------------------------------
echo [11] Open Network Connections
echo [12] Open Wi-Fi Settings
echo [13] Open Device Manager
echo [14] Open Windows Troubleshoot Settings
echo [15] Open log folder
echo.
echo CONNECTIVITY-CHANGING ACTIONS - APPROVAL REQUIRED
echo ------------------------------------------------
echo [16] Flush DNS cache
echo [17] Release DHCP leases
echo [18] Renew DHCP leases
echo [19] Reset Winsock
echo [20] Reset TCP/IP stack
echo [21] Run full network repair
echo.
echo [0] Exit
echo.
set "CHOICE="
set /p "CHOICE=Select option: "
if "%CHOICE%"=="1" goto IPCONFIG
if "%CHOICE%"=="2" goto PINGTARGET
if "%CHOICE%"=="3" goto CONTPING
if "%CHOICE%"=="4" goto DNSLOOKUP
if "%CHOICE%"=="5" goto TRACE
if "%CHOICE%"=="6" goto ROUTE
if "%CHOICE%"=="7" goto ARP
if "%CHOICE%"=="8" goto NETSTAT
if "%CHOICE%"=="9" goto WIFIINFO
if "%CHOICE%"=="10" goto COLLECT
if "%CHOICE%"=="11" goto NCPA
if "%CHOICE%"=="12" goto WIFISETTINGS
if "%CHOICE%"=="13" goto DEVICE
if "%CHOICE%"=="14" goto TROUBLESHOOT
if "%CHOICE%"=="15" goto OPENLOGS
if "%CHOICE%"=="16" goto FLUSHDNS
if "%CHOICE%"=="17" goto RELEASE
if "%CHOICE%"=="18" goto RENEW
if "%CHOICE%"=="19" goto WINSOCK
if "%CHOICE%"=="20" goto TCPRESET
if "%CHOICE%"=="21" goto FULLREPAIR
if "%CHOICE%"=="0" goto CLEANEXIT
echo Invalid selection.
timeout /t 2 >nul
goto MENU

:AskTarget
set "TARGET="
echo.
set /p "TARGET=Enter hostname, IP address, or URL: "
if not defined TARGET exit /b 1
call :SanitizeTarget "%TARGET%"
if not defined TARGET exit /b 1
exit /b 0

:IPCONFIG
cls
call :RunAndLog "IPCONFIG ALL" ipconfig /all
goto END

:PINGTARGET
cls
call :AskTarget
if errorlevel 1 goto MENU
call :RunAndLog "PING %TARGET%" ping "%TARGET%" -n 10
goto END

:CONTPING
cls
call :AskTarget
if errorlevel 1 goto MENU
call :Section "CONTINUOUS PING %TARGET%"
echo Press Ctrl+C to stop. Continuous output is not logged.
ping "%TARGET%" -t
goto END

:DNSLOOKUP
cls
call :AskTarget
if errorlevel 1 goto MENU
call :RunAndLog "NSLOOKUP %TARGET%" nslookup "%TARGET%"
goto END

:TRACE
cls
call :AskTarget
if errorlevel 1 goto MENU
echo Running trace route. This may take several minutes...
call :RunAndLog "TRACERT %TARGET%" tracert -d "%TARGET%"
goto END

:ROUTE
cls
call :RunAndLog "ROUTE PRINT" route print
goto END

:ARP
cls
call :RunAndLog "ARP CACHE" arp -a
goto END

:NETSTAT
cls
call :RunAndLog "NETSTAT ANO" netstat -ano
goto END

:WIFIINFO
cls
call :CheckWlan
if errorlevel 1 goto END
call :RunAndLog "WLAN INTERFACES" netsh wlan show interfaces
goto END

:COLLECT
cls
set "BUNDLE=%LOGDIR%\Diagnostics_%COMPUTERNAME%_%STAMP%_%RANDOM%"
mkdir "%BUNDLE%" >nul 2>&1
if not exist "%BUNDLE%" (
    echo ERROR: The diagnostic folder could not be created.
    goto END
)
echo Collecting read-only diagnostics...
echo [1/8] IP configuration...
ipconfig /all >"%BUNDLE%\ipconfig_all.txt" 2>&1
echo [2/8] Routing table...
route print >"%BUNDLE%\route_print.txt" 2>&1
echo [3/8] ARP cache...
arp -a >"%BUNDLE%\arp_cache.txt" 2>&1
echo [4/8] Active connections...
netstat -ano >"%BUNDLE%\netstat_ano.txt" 2>&1
echo [5/8] Wi-Fi information...
call :CollectWlan "%BUNDLE%\wlan_interfaces.txt"
echo [6/8] MAC information...
getmac /v /fo list >"%BUNDLE%\getmac.txt" 2>&1
echo [7/8] System information...
systeminfo >"%BUNDLE%\systeminfo.txt" 2>&1
echo [8/8] Recent System errors...
wevtutil qe System /q:"*[System[(Level=1 or Level=2 or Level=3)]]" /c:50 /rd:true /f:text >"%BUNDLE%\system_errors_recent.txt" 2>&1
copy /y "%LOGFILE%" "%BUNDLE%\toolkit_session.log" >nul 2>&1
echo Diagnostic bundle created: %BUNDLE%>>"%LOGFILE%"
echo.
echo Diagnostic collection completed:
echo %BUNDLE%
echo.
echo Review files for usernames, hostnames, IP addresses, MAC addresses,
echo routes, DNS information, connections, and event data before sharing.
start "" "%BUNDLE%"
goto END

:NCPA
call :Section "OPEN NETWORK CONNECTIONS"
start "" ncpa.cpl
goto MENU

:WIFISETTINGS
call :Section "OPEN WIFI SETTINGS"
start "" ms-settings:network-wifi
goto MENU

:DEVICE
call :Section "OPEN DEVICE MANAGER"
start "" devmgmt.msc
goto MENU

:TROUBLESHOOT
call :Section "OPEN WINDOWS TROUBLESHOOT SETTINGS"
start "" ms-settings:troubleshoot
goto MENU

:OPENLOGS
start "" "%LOGDIR%"
goto MENU

:FLUSHDNS
call :ConfirmChange "Flush the local DNS resolver cache" "Cached DNS responses are removed; later requests must query DNS again."
if errorlevel 1 goto MENU
cls
call :RunAndLog "FLUSH DNS" ipconfig /flushdns
goto END

:RELEASE
call :ConfirmOutage "Release all DHCP leases" "This can disconnect LAN, Wi-Fi, VPN, Zscaler, RDP, and remote-support sessions."
if errorlevel 1 goto MENU
cls
call :RunAndLog "IPCONFIG RELEASE" ipconfig /release
echo Run Renew DHCP locally to request new leases.
goto END

:RENEW
call :ConfirmChange "Renew all DHCP leases" "DHCP-enabled adapters may briefly lose connectivity."
if errorlevel 1 goto MENU
cls
call :RunAndLog "IPCONFIG RENEW" ipconfig /renew
goto END

:WINSOCK
call :ConfirmChange "Reset the Winsock catalog" "This changes the network stack and requires a restart. VPN, proxy, Zscaler, and endpoint-security providers may be affected until restart."
if errorlevel 1 goto MENU
cls
call :RunAndLog "WINSOCK RESET" netsh winsock reset
echo Restart required. The toolkit will not restart Windows.
goto END

:TCPRESET
call :ConfirmOutage "Reset the TCP/IP stack" "This may remove custom settings and requires a Windows restart."
if errorlevel 1 goto MENU
cls
set "NETBACKUP=%LOGDIR%\NetworkConfigBackup_%COMPUTERNAME%_%STAMP%.txt"
set "RESETLOG=%LOGDIR%\TCPIP_Reset_%COMPUTERNAME%_%STAMP%.log"
netsh -c interface dump >"%NETBACKUP%" 2>&1
call :RunAndLog "TCP IP RESET" netsh int ip reset "%RESETLOG%"
echo Backup: %NETBACKUP%
echo Reset log: %RESETLOG%
echo Restart required. The toolkit will not restart Windows.
goto END

:FULLREPAIR
call :ConfirmOutage "Run full repair: flush DNS, release and renew DHCP, reset Winsock, and reset TCP/IP" "HIGH IMPACT: disconnects the endpoint, changes network-stack configuration, and requires a restart. Do not run remotely."
if errorlevel 1 goto MENU
cls
set "NETBACKUP=%LOGDIR%\NetworkConfigBackup_%COMPUTERNAME%_%STAMP%.txt"
set "RESETLOG=%LOGDIR%\TCPIP_Reset_%COMPUTERNAME%_%STAMP%.log"
call :Section "FULL NETWORK REPAIR"
echo Running full network repair. Do not close this window.
echo [1/6] Backing up network configuration...
netsh -c interface dump >"%NETBACKUP%" 2>&1
echo [2/6] Flushing DNS cache...
call :RunAndLog "FULL REPAIR - FLUSH DNS" ipconfig /flushdns
echo [3/6] Releasing DHCP leases...
call :RunAndLog "FULL REPAIR - RELEASE DHCP" ipconfig /release
echo [4/6] Renewing DHCP leases...
call :RunAndLog "FULL REPAIR - RENEW DHCP" ipconfig /renew
echo [5/6] Resetting Winsock...
call :RunAndLog "FULL REPAIR - RESET WINSOCK" netsh winsock reset
echo [6/6] Resetting TCP/IP stack...
call :RunAndLog "FULL REPAIR - RESET TCP IP" netsh int ip reset "%RESETLOG%"
echo.
echo Full repair completed.
echo Backup: %NETBACKUP%
echo Reset log: %RESETLOG%
echo Restart required. The toolkit will not restart Windows.
goto END

:ConfirmChange
cls
echo ================================================================
echo APPROVAL-REQUIRED NETWORK CHANGE
echo ================================================================
echo Action: %~1
echo Risk:   %~2
echo.
echo Confirm support authority, incident or procedure, saved work,
echo and a recorded baseline before continuing.
set "ANSWER="
set /p "ANSWER=Type YES to continue: "
if /i not "%ANSWER%"=="YES" exit /b 1
(
 echo [%DATE% %TIME%] CHANGE CONFIRMED BY %USERNAME%
 echo Action: %~1
 echo Risk: %~2
)>>"%LOGFILE%"
exit /b 0

:ConfirmOutage
cls
echo ================================================================
echo HIGH-IMPACT CONNECTIVITY CHANGE
echo ================================================================
echo Action: %~1
echo Risk:   %~2
echo.
echo Confirm local console access, saved work, baseline diagnostics,
echo required approval, and restart availability. Do not run remotely.
set "ANSWER="
set /p "ANSWER=Type DISCONNECT to continue: "
if /i not "%ANSWER%"=="DISCONNECT" exit /b 1
(
 echo [%DATE% %TIME%] HIGH-IMPACT CHANGE CONFIRMED BY %USERNAME%
 echo Action: %~1
 echo Risk: %~2
)>>"%LOGFILE%"
exit /b 0

:CheckWlan
sc query wlansvc >"%TEMPLOG%" 2>&1
findstr /c:"STATE" "%TEMPLOG%" >nul 2>&1
if errorlevel 1 (
    echo Wireless AutoConfig is not available. This may be a wired-only device.
    echo WLAN unavailable or service missing.>>"%LOGFILE%"
    exit /b 1
)
findstr /c:"RUNNING" "%TEMPLOG%" >nul 2>&1
if errorlevel 1 (
    echo Wireless AutoConfig is installed but not running.
    echo The toolkit will not start the service automatically.
    echo WLAN service present but not running.>>"%LOGFILE%"
    exit /b 1
)
exit /b 0

:CollectWlan
call :CheckWlan
if errorlevel 1 (
    echo Wireless AutoConfig is unavailable or not running.>"%~1"
    exit /b
)
netsh wlan show interfaces >"%~1" 2>&1
exit /b

:ResolveDrop
set "TARGET="
set "TARGETFROMFILE="
if exist "%~1" (
    for /f "usebackq tokens=* delims=" %%A in ("%~1") do if not defined TARGETFROMFILE set "TARGETFROMFILE=%%A"
    if defined TARGETFROMFILE set "TARGET=%TARGETFROMFILE%"
) else (
    set "TARGET=%~1"
)
if defined TARGET call :SanitizeTarget "%TARGET%"
exit /b

:SanitizeTarget
set "TARGET=%~1"
set "TARGET=%TARGET:http://=%"
set "TARGET=%TARGET:https://=%"
for /f "tokens=1 delims=/" %%A in ("%TARGET%") do set "TARGET=%%A"
rem Preserve raw IPv6 addresses. Strip :port only for targets containing a dot.
echo(%TARGET%| findstr /c:"." >nul 2>&1
if not errorlevel 1 for /f "tokens=1 delims=:" %%A in ("%TARGET%") do set "TARGET=%%A"
rem Remove brackets from bracketed IPv6 URL hosts.
set "TARGET=%TARGET:[=%"
set "TARGET=%TARGET:]=%"
set "TARGET=%TARGET:"=%"
exit /b

:TargetTest
cls
call :Section "DRAG DROP TARGET TEST %~1"
(
 echo ================================================================
 echo PING
 echo ================================================================
 ping "%~1" -n 4
 echo.
 echo ================================================================
 echo DNS LOOKUP
 echo ================================================================
 nslookup "%~1"
 echo.
 echo ================================================================
 echo TRACE ROUTE
 echo ================================================================
 tracert -d "%~1"
)>"%TEMPLOG%" 2>&1
type "%TEMPLOG%"
type "%TEMPLOG%">>"%LOGFILE%"
echo.
echo Results logged to: %LOGFILE%
pause
exit /b

:RunAndLog
call :Section "%~1"
shift
%* >"%TEMPLOG%" 2>&1
set "RC=%ERRORLEVEL%"
type "%TEMPLOG%"
type "%TEMPLOG%">>"%LOGFILE%"
echo Exit code: %RC%>>"%LOGFILE%"
exit /b %RC%

:LogHeader
(
 echo ================================================================
 echo %APP%
 echo Computer: %COMPUTERNAME%
 echo User: %USERNAME%
 echo Started: %DATE% %TIME%
 echo Script: %~f0
 echo Log: %LOGFILE%
 echo ================================================================
)>"%LOGFILE%"
exit /b

:Section
(
 echo.
 echo ================================================================
 echo [%DATE% %TIME%] %~1
 echo ================================================================
)>>"%LOGFILE%"
exit /b

:END
if exist "%TEMPLOG%" del "%TEMPLOG%" >nul 2>&1
echo.
echo Operation completed.
echo Session log: %LOGFILE%
pause
goto MENU

:CLEANEXIT
if exist "%TEMPLOG%" del "%TEMPLOG%" >nul 2>&1
if exist "%LOGFILE%" echo Session log: %LOGFILE%
endlocal
rem ================================================================
rem Engineered by Lucilyn Tangian. 
rem EOF - End of Advanced Windows Network Toolkit
rem ================================================================
exit /b
