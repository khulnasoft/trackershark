@echo off

if not exist "build" (
    echo Build directory doesn't exist, run "scripts\cmake.bat" first
    exit /b 1
)

robocopy .\ wireshark CMakeListsCustom.txt /COPY:DAT
robocopy plugins\epan wireshark\plugins\epan common.h /COPY:DAT
robocopy plugins\epan wireshark\plugins\epan wsjson_extensions.c /COPY:DAT
robocopy "plugins\epan\tracker-event" "wireshark\plugins\epan\tracker-event" /MIR /COPY:DAT
robocopy "plugins\epan\tracker-network-capture" "wireshark\plugins\epan\tracker-network-capture" /MIR /COPY:DAT
robocopy "plugins\wiretap\tracker-json" "wireshark\plugins\wiretap\tracker-json" /MIR /COPY:DAT

pushd build
msbuild /m /p:Configuration=RelWithDebInfo Wireshark.sln
popd