@echo off

rmdir /S /Q wireshark\plugins\epan\tracker-event
rmdir /S /Q wireshark\plugins\epan\tracker-network-capture
rmdir /S /Q wireshark\plugins\wiretap\tracker-json
del /Q wireshark\plugins\epan\common.h
del /Q wireshark\plugins\epan\wsjson_extensions.c
del /Q wireshark\CMakeListsCustom.txt
rmdir /S /Q build