@echo off
setlocal EnableDelayedExpansion

REM Usage: buildseg.bat hockey94
REM Assembles src\stubinc\<name>_stub.asm to output\<name>.bin

if "%~1"=="" (
    echo ERROR: No segment name provided
    echo Usage: %~nx0 ^<name^>
    exit /b 1
)

set "ROM_NAME=%~1"
set "WORKSPACE=%~dp0"

if not exist "%WORKSPACE%output" mkdir "%WORKSPACE%output"
if not defined checksum set "checksum=1"
set "CHECKSUM_FLAG=/e CHECKSUM=1"
if "%checksum%"=="0" set "CHECKSUM_FLAG=/e CHECKSUM=0"
set "REV_FLAG=/e REV=0"

echo Building: %ROM_NAME%

cd /d "%WORKSPACE%src" || exit /b 1

"%WORKSPACE%assembler\Assembler.exe" ^
  /p /m /g ^
  /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ ^
  %CHECKSUM_FLAG% %REV_FLAG% ^
  "stubinc\%ROM_NAME%_stub.asm,%WORKSPACE%output\%ROM_NAME%.bin,%WORKSPACE%output\%ROM_NAME%,%WORKSPACE%output\%ROM_NAME%" ^
  > "%WORKSPACE%output\Build_%ROM_NAME%.log"

if errorlevel 1 (
    echo ASSEMBLY FAILED. See output\Build_%ROM_NAME%.log
) else (
    echo Build completed. Output: output\%ROM_NAME%.bin
)

cd /d "%WORKSPACE%"
endlocal
