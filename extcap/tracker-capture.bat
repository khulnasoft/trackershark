@echo off
SET extcap_path=%~dp0
python %extcap_path:~0,-1%\tracker-capture.py %*