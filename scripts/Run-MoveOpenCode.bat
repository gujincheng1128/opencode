@echo off
title Move OpenCode C to G
REM Run the migration script with policy bypass.
REM Right-click this file and choose "Run as administrator".
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Move-OpenCode.ps1"
pause