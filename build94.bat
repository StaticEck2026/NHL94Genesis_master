@echo off
setlocal

REM Get the directory of this batch file
set "workspaceFolder=%~dp0"

REM Set default values for rev and checksum if not provided
if not defined rev set rev=0
if not defined checksum set checksum=1

REM Pre-step: tools\prebuild.js checks the ROM and Extracted/ and extracts the assets if they are missing
REM or incomplete; it stops the build with the ROM path, SHA-1 and size if the ROM is missing. The npm
REM scripts run it first and set NHL_PREBUILD_DONE; tools/verify_all.sh does the same under wine.
set "prebuildTarget=retail"
if not defined NHL_PREBUILD_DONE (
    node "%workspaceFolder%tools\prebuild.js" %prebuildTarget% || exit /b 1
)

@REM echo Using rev=%rev% and checksum=%checksum%

REM Create the output directory
if not exist "%workspaceFolder%output" mkdir "%workspaceFolder%output"

REM Change to the workspace src directory
cd /d "%workspaceFolder%src"

REM Determine revision flag
if "%REV%"=="1" (
    set revFlag="/e REV=1"
    ECHO "its reva"
) else (
    set revFlag="/e REV=0"
    ECHO "its retail"
)

REM Determine checksum flag
if "%checksum%"=="0" (
    set checksumFlag="/e CHECKSUM=0"
) else (
    set checksumFlag="/e CHECKSUM=1"
)

REM Run the assembler with all flags. LONGBRA=0 keeps the short branch to Begin.
REM If that branch cannot reach, assemble again with a long jump. SRAMTOGGLE=0 keeps
REM retail save I/O; if the ROM overlaps backup RAM, assemble again with SRAMTOGGLE=1.
set "longFlag=/e LONGBRA=0"
set "sramFlag=/e SRAMTOGGLE=0"
:assemble
"%workspaceFolder%assembler\Assembler.exe" ^
  /p /m /g ^
  /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ ^
  %revFlag% %checksumFlag% %longFlag% %sramFlag% ^
  "%workspaceFolder%src\nhl94.asm,%workspaceFolder%output\nhl94.bin,%workspaceFolder%output\nhl94,%workspaceFolder%output\nhl94" ^
  > "%workspaceFolder%output\Build94.log"
findstr /C:"is out of range" "%workspaceFolder%output\Build94.log" >nul
if errorlevel 1 goto check_sram
echo %longFlag% | findstr /C:"LONGBRA=1" >nul
if not errorlevel 1 goto check_sram
echo Begin is out of range. Assembling again with a long jump.
set "longFlag=/e LONGBRA=1"
goto assemble
:check_sram
findstr /C:"ROM content overlaps backup RAM" "%workspaceFolder%output\Build94.log" >nul
if errorlevel 1 goto assembled
echo %sramFlag% | findstr /C:"SRAMTOGGLE=1" >nul
if not errorlevel 1 goto assembled
echo ROM overlaps backup RAM. Assembling again with save-chip map toggle.
set "sramFlag=/e SRAMTOGGLE=1"
goto assemble
:assembled
endlocal
findstr /C:" 0 error" "%workspaceFolder%output\Build94.log" >nul
if errorlevel 1 exit /b 1
exit /b 0
