@echo off
setlocal

FOR /F "tokens=*" %%i in ('type .env') do SET %%i

rmdir /S /Q dist\workdir
mkdir dist\workdir

copy /Y dist\install.ps1 dist\workdir\install.ps1
copy /Y build\run\RelWithDebInfo\tracker-event.dll dist\workdir\tracker-event.dll
copy /Y build\run\RelWithDebInfo\tracker-network-capture.dll dist\workdir\tracker-network-capture.dll
copy /Y build\run\RelWithDebInfo\tracker-json.dll dist\workdir\tracker-json.dll
xcopy /Y /E /I profiles dist\workdir\profiles
xcopy /Y /E /I extcap dist\workdir\extcap
del /Q dist\workdir\extcap\tracker-capture.sh
powershell -Command "(gc dist\workdir\extcap\tracker-capture.py) -replace 'VERSION_PLACEHOLDER', '%TRACKERSHARK_VERSION%' | Out-File -encoding ASCII dist\workdir\extcap\tracker-capture.py"

for /f "tokens=2" %%a in ('build\run\RelWithDebInfo\wireshark.exe --version ^| find "Wireshark "') do (
    for /f "tokens=1,2,3 delims=." %%A in ("%%a") do (
        set "WS_VERSION=%%A.%%B.%%C"
    )
)
echo %WS_VERSION% > dist\workdir\ws_version.txt

powershell Compress-Archive -Update -Path dist\workdir\* -DestinationPath dist\trackershark-v%TRACKERSHARK_VERSION%-windows-x86_64-wireshark-%WS_VERSION%.zip

endlocal