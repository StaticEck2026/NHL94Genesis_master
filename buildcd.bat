@echo off
setlocal

REM Assemble the transcribed Sega CD fragments and compare them to cdbin\.
REM Does not build or touch the cartridge ROM.
REM /o oz- keeps a zero displacement as a 16-bit extension. The cartridge
REM build uses oz+, which would not match these disc bytes.
set "WORKSPACE=%~dp0"
if not exist "%WORKSPACE%output" mkdir "%WORKSPACE%output"
cd /d "%WORKSPACE%src"
if errorlevel 1 exit /b 1

"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\maincd.asm,%WORKSPACE%output\maincd.bin,%WORKSPACE%output\maincd,%WORKSPACE%output\maincd" > "%WORKSPACE%output\Build_maincd.log"
if errorlevel 1 (
    echo maincd assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\maindma.asm,%WORKSPACE%output\maindma.bin,%WORKSPACE%output\maindma,%WORKSPACE%output\maindma" > "%WORKSPACE%output\Build_maindma.log"
if errorlevel 1 (
    echo maindma assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\maincont.asm,%WORKSPACE%output\maincont.bin,%WORKSPACE%output\maincont,%WORKSPACE%output\maincont" > "%WORKSPACE%output\Build_maincont.log"
if errorlevel 1 (
    echo maincont assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\mainblit.asm,%WORKSPACE%output\mainblit.bin,%WORKSPACE%output\mainblit,%WORKSPACE%output\mainblit" > "%WORKSPACE%output\Build_mainblit.log"
if errorlevel 1 (
    echo mainblit assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\mainvdp.asm,%WORKSPACE%output\mainvdp.bin,%WORKSPACE%output\mainvdp,%WORKSPACE%output\mainvdp" > "%WORKSPACE%output\Build_mainvdp.log"
if errorlevel 1 (
    echo mainvdp assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\mainpad.asm,%WORKSPACE%output\mainpad.bin,%WORKSPACE%output\mainpad,%WORKSPACE%output\mainpad" > "%WORKSPACE%output\Build_mainpad.log"
if errorlevel 1 (
    echo mainpad assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\maindisp.asm,%WORKSPACE%output\maindisp.bin,%WORKSPACE%output\maindisp,%WORKSPACE%output\maindisp" > "%WORKSPACE%output\Build_maindisp.log"
if errorlevel 1 (
    echo maindisp assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\mainfont.asm,%WORKSPACE%output\mainfont.bin,%WORKSPACE%output\mainfont,%WORKSPACE%output\mainfont" > "%WORKSPACE%output\Build_mainfont.log"
if errorlevel 1 (
    echo mainfont assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\maintext.asm,%WORKSPACE%output\maintext.bin,%WORKSPACE%output\maintext,%WORKSPACE%output\maintext" > "%WORKSPACE%output\Build_maintext.log"
if errorlevel 1 (
    echo maintext assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\subboot.asm,%WORKSPACE%output\subboot.bin,%WORKSPACE%output\subboot,%WORKSPACE%output\subboot" > "%WORKSPACE%output\Build_subboot.log"
if errorlevel 1 (
    echo subboot assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\subheap.asm,%WORKSPACE%output\subheap.bin,%WORKSPACE%output\subheap,%WORKSPACE%output\subheap" > "%WORKSPACE%output\Build_subheap.log"
if errorlevel 1 (
    echo subheap assembly failed
    exit /b 1
)

endlocal
