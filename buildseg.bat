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

REM Pre-step: tools\prebuild.js checks the ROM and Extracted/ and extracts the assets if they are missing
REM or incomplete; it stops the build with the ROM path, SHA-1 and size if the ROM is missing. The npm
REM scripts run it first and set NHL_PREBUILD_DONE; tools/verify_all.sh does the same under wine.
set "prebuildTarget=retail"
if not defined NHL_PREBUILD_DONE (
    node "%WORKSPACE%tools\prebuild.js" %prebuildTarget% || exit /b 1
)

if not exist "%WORKSPACE%output" mkdir "%WORKSPACE%output"
if not defined checksum set "checksum=1"
set "CHECKSUM_FLAG=/e CHECKSUM=1"
if "%checksum%"=="0" set "CHECKSUM_FLAG=/e CHECKSUM=0"
set "REV_FLAG=/e REV=0"
set "LONGBRA_FLAG=/e LONGBRA=0"
set "SRAM_FLAG=/e SRAMTOGGLE=0"

echo Building: %ROM_NAME%

cd /d "%WORKSPACE%src"

"%WORKSPACE%assembler\Assembler.exe" ^
  /p /m /g ^
  /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ ^
  %CHECKSUM_FLAG% %REV_FLAG% %LONGBRA_FLAG% %SRAM_FLAG% ^
  "stubinc\%ROM_NAME%_stub.asm,%WORKSPACE%output\%ROM_NAME%.bin,%WORKSPACE%output\%ROM_NAME%,%WORKSPACE%output\%ROM_NAME%" ^
  > "%WORKSPACE%output\Build_%ROM_NAME%.log"

if errorlevel 1 (
    echo ASSEMBLY FAILED. See output\Build_%ROM_NAME%.log
) else (
    echo Build completed. Output: output\%ROM_NAME%.bin
)

cd /d "%WORKSPACE%"
endlocal
