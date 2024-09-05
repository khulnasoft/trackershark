@echo off
setlocal

FOR /F "tokens=*" %%i in ('type .env') do SET %%i

call scripts\clean.bat
robocopy .\ wireshark CMakeListsCustom.txt /COPY:DAT
robocopy plugins\epan wireshark\plugins\epan common.h /COPY:DAT
robocopy plugins\epan wireshark\plugins\epan wsjson_extensions.c /COPY:DAT
robocopy "plugins\epan\tracker-event" "wireshark\plugins\epan\tracker-event" /MIR /COPY:DAT
robocopy "plugins\epan\tracker-network-capture" "wireshark\plugins\epan\tracker-network-capture" /MIR /COPY:DAT
robocopy "plugins\wiretap\tracker-json" "wireshark\plugins\wiretap\tracker-json" /MIR /COPY:DAT
mkdir build
pushd build

rem Wireshark changed DISABLE_WERROR to ENABLE_WERROR at some point. Use both for compatibility (even though it causes a cmake warning to be thrown)
if "%WERROR%"=="y" (
    cmake -G "Visual Studio 17 2022" -A x64 -DENABLE_MINIZIPNG=Off -DTRACKERSHARK_VERSION=%TRACKERSHARK_VERSION% -DENABLE_CCACHE=Yes -DENABLE_WERROR=ON -DDISABLE_WERROR=OFF ..\wireshark
) else (
    cmake -G "Visual Studio 17 2022" -A x64 -DENABLE_MINIZIPNG=Off -DTRACKERSHARK_VERSION=%TRACKERSHARK_VERSION% -DENABLE_CCACHE=Yes -DENABLE_WERROR=OFF -DDISABLE_WERROR=OFF ..\wireshark
)

popd

endlocal