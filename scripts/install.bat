@echo off
setlocal

FOR /F "tokens=*" %%i in ('type .env') do SET %%i

mkdir "%APPDATA%\Wireshark\profiles"
xcopy /Y /E /I profiles "%APPDATA%\Wireshark\profiles"

mkdir "%APPDATA%\Wireshark\extcap"
copy /Y extcap\tracker-capture.py "%APPDATA%\Wireshark\extcap\tracker-capture.py"
powershell -Command "(gc '%APPDATA%\Wireshark\extcap\tracker-capture.py') -replace 'VERSION_PLACEHOLDER', '%TRACKERSHARK_VERSION%' | Out-File -encoding ASCII '%APPDATA%\Wireshark\extcap\tracker-capture.py'"
copy /Y extcap\tracker-capture.bat "%APPDATA%\Wireshark\extcap\tracker-capture.bat"
xcopy /Y /E /I extcap\tracker-capture "%APPDATA%\Wireshark\extcap\tracker-capture"

for /f "tokens=2" %%a in ('build\run\RelWithDebInfo\wireshark.exe --version ^| find "Wireshark "') do (
    for /f "tokens=1,2 delims=." %%A in ("%%a") do (
        set "WS_VERSION=%%A.%%B"
    )
)

mkdir "%APPDATA%\Wireshark\plugins\%WS_VERSION%\epan"
mkdir "%APPDATA%\Wireshark\plugins\%WS_VERSION%\wiretap"

copy /Y build\run\RelWithDebInfo\tracker-event.dll "%APPDATA%\Wireshark\plugins\%WS_VERSION%\epan\tracker-event.dll"
copy /Y build\run\RelWithDebInfo\tracker-network-capture.dll "%APPDATA%\Wireshark\plugins\%WS_VERSION%\epan\tracker-network-capture.dll"
copy /Y build\run\RelWithDebInfo\tracker-json.dll "%APPDATA%\Wireshark\plugins\%WS_VERSION%\wiretap\tracker-json.dll"

endlocal