@echo off
REM Usage: buildseg.bat <name>   (the same as npm run seg -- <name>)
REM Builds src\stubinc\<name>_stub.asm at its org in tools\segments.json and verifies it against
REM lst\nhl94.bin. Extra arguments (for example --verbose) are passed on.
if "%~1"=="" (
    echo Usage: %~nx0 ^<name^>
    exit /b 1
)
node "%~dp0tools\build.js" --seg %*
exit /b %errorlevel%
