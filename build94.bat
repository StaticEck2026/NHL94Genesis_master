@echo off
setlocal

REM Get the directory of this batch file
set "workspaceFolder=%~dp0"

REM Set default values for rev and checksum if not provided
if not defined rev set rev=0
if not defined checksum set checksum=1

REM The build is tools\build.js: prebuild, assemble, fixopcodes, fixrom, verify, one line each.
REM rev=1 builds REV A; checksum=0 is a dev build (no boot check, not verified). Extra arguments
REM (for example --verbose) are passed on.
set "mode=retail"
if "%checksum%"=="0" set "mode=dev"
node "%workspaceFolder%tools\build.js" %mode% %*
exit /b %errorlevel%
