@echo off
setlocal

REM Assemble the transcribed Sega CD fragments and compare them to cdbin\.
REM Does not build or touch the cartridge ROM.
set "WORKSPACE=%~dp0"
if not exist "%WORKSPACE%output" mkdir "%WORKSPACE%output"
cd /d "%WORKSPACE%src"
if errorlevel 1 exit /b 1

"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ "segacd\maincd.asm,%WORKSPACE%output\maincd.bin,%WORKSPACE%output\maincd,%WORKSPACE%output\maincd" > "%WORKSPACE%output\Build_maincd.log"
if errorlevel 1 (
    echo maincd assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o ow+ /o op- /o os+ /o oz+ /o omq- /o oaq+ /o osq+ "segacd\subboot.asm,%WORKSPACE%output\subboot.bin,%WORKSPACE%output\subboot,%WORKSPACE%output\subboot" > "%WORKSPACE%output\Build_subboot.log"
if errorlevel 1 (
    echo subboot assembly failed
    exit /b 1
)

endlocal
