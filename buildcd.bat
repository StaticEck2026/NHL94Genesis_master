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
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\pcmclear.asm,%WORKSPACE%output\pcmclear.bin,%WORKSPACE%output\pcmclear,%WORKSPACE%output\pcmclear" > "%WORKSPACE%output\Build_pcmclear.log"
if errorlevel 1 (
    echo pcmclear assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdcwait.asm,%WORKSPACE%output\cdcwait.bin,%WORKSPACE%output\cdcwait,%WORKSPACE%output\cdcwait" > "%WORKSPACE%output\Build_cdcwait.log"
if errorlevel 1 (
    echo cdcwait assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\pcmchip.asm,%WORKSPACE%output\pcmchip.bin,%WORKSPACE%output\pcmchip,%WORKSPACE%output\pcmchip" > "%WORKSPACE%output\Build_pcmchip.log"
if errorlevel 1 (
    echo pcmchip assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\audiostream.asm,%WORKSPACE%output\audiostream.bin,%WORKSPACE%output\audiostream,%WORKSPACE%output\audiostream" > "%WORKSPACE%output\Build_audiostream.log"
if errorlevel 1 (
    echo audiostream assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdfade.asm,%WORKSPACE%output\cdfade.bin,%WORKSPACE%output\cdfade,%WORKSPACE%output\cdfade" > "%WORKSPACE%output\Build_cdfade.log"
if errorlevel 1 (
    echo cdfade assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdrequest.asm,%WORKSPACE%output\cdrequest.bin,%WORKSPACE%output\cdrequest,%WORKSPACE%output\cdrequest" > "%WORKSPACE%output\Build_cdrequest.log"
if errorlevel 1 (
    echo cdrequest assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdtrack.asm,%WORKSPACE%output\cdtrack.bin,%WORKSPACE%output\cdtrack,%WORKSPACE%output\cdtrack" > "%WORKSPACE%output\Build_cdtrack.log"
if errorlevel 1 (
    echo cdtrack assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdcrowd.asm,%WORKSPACE%output\cdcrowd.bin,%WORKSPACE%output\cdcrowd,%WORKSPACE%output\cdcrowd" > "%WORKSPACE%output\Build_cdcrowd.log"
if errorlevel 1 (
    echo cdcrowd assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq+ /o osq+ "segacd\cdstart.asm,%WORKSPACE%output\cdstart.bin,%WORKSPACE%output\cdstart,%WORKSPACE%output\cdstart" > "%WORKSPACE%output\Build_cdstart.log"
if errorlevel 1 (
    echo cdstart assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\scoutopen.asm,%WORKSPACE%output\scoutopen.bin,%WORKSPACE%output\scoutopen,%WORKSPACE%output\scoutopen" > "%WORKSPACE%output\Build_scoutopen.log"
if errorlevel 1 (
    echo scoutopen assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\scouttext.asm,%WORKSPACE%output\scouttext.bin,%WORKSPACE%output\scouttext,%WORKSPACE%output\scouttext" > "%WORKSPACE%output\Build_scouttext.log"
if errorlevel 1 (
    echo scouttext assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\scouttok.asm,%WORKSPACE%output\scouttok.bin,%WORKSPACE%output\scouttok,%WORKSPACE%output\scouttok" > "%WORKSPACE%output\Build_scouttok.log"
if errorlevel 1 (
    echo scouttok assembly failed
    exit /b 1
)

"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\playerpic.asm,%WORKSPACE%output\playerpic.bin,%WORKSPACE%output\playerpic,%WORKSPACE%output\playerpic" > "%WORKSPACE%output\Build_playerpic.log"
if errorlevel 1 (
    echo playerpic assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\playercareer.asm,%WORKSPACE%output\playercareer.bin,%WORKSPACE%output\playercareer,%WORKSPACE%output\playercareer" > "%WORKSPACE%output\Build_playercareer.log"
if errorlevel 1 (
    echo playercareer assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\playerpage.asm,%WORKSPACE%output\playerpage.bin,%WORKSPACE%output\playerpage,%WORKSPACE%output\playerpage" > "%WORKSPACE%output\Build_playerpage.log"
if errorlevel 1 (
    echo playerpage assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\crowdanim.asm,%WORKSPACE%output\crowdanim.bin,%WORKSPACE%output\crowdanim,%WORKSPACE%output\crowdanim" > "%WORKSPACE%output\Build_crowdanim.log"
if errorlevel 1 (
    echo crowdanim assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\crowdtable.asm,%WORKSPACE%output\crowdtable.bin,%WORKSPACE%output\crowdtable,%WORKSPACE%output\crowdtable" > "%WORKSPACE%output\Build_crowdtable.log"
if errorlevel 1 (
    echo crowdtable assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\filmopen.asm,%WORKSPACE%output\filmopen.bin,%WORKSPACE%output\filmopen,%WORKSPACE%output\filmopen" > "%WORKSPACE%output\Build_filmopen.log"
if errorlevel 1 (
    echo filmopen assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\filmsm.asm,%WORKSPACE%output\filmsm.bin,%WORKSPACE%output\filmsm,%WORKSPACE%output\filmsm" > "%WORKSPACE%output\Build_filmsm.log"
if errorlevel 1 (
    echo filmsm assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\filmtask.asm,%WORKSPACE%output\filmtask.bin,%WORKSPACE%output\filmtask,%WORKSPACE%output\filmtask" > "%WORKSPACE%output\Build_filmtask.log"
if errorlevel 1 (
    echo filmtask assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\filmclose.asm,%WORKSPACE%output\filmclose.bin,%WORKSPACE%output\filmclose,%WORKSPACE%output\filmclose" > "%WORKSPACE%output\Build_filmclose.log"
if errorlevel 1 (
    echo filmclose assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\z80load.asm,%WORKSPACE%output\z80load.bin,%WORKSPACE%output\z80load,%WORKSPACE%output\z80load" > "%WORKSPACE%output\Build_z80load.log"
if errorlevel 1 (
    echo z80load assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\hwread.asm,%WORKSPACE%output\hwread.bin,%WORKSPACE%output\hwread,%WORKSPACE%output\hwread" > "%WORKSPACE%output\Build_hwread.log"
if errorlevel 1 (
    echo hwread assembly failed
    exit /b 1
)
"%WORKSPACE%assembler\Assembler.exe" /p /m /g /o d- /o s- /o r+ /o l+ /o l. /o ow+ /o op- /o os+ /o oz- /o omq- /o oaq- /o osq- "segacd\scoutload.asm,%WORKSPACE%output\scoutload.bin,%WORKSPACE%output\scoutload,%WORKSPACE%output\scoutload" > "%WORKSPACE%output\Build_scoutload.log"
if errorlevel 1 (
    echo scoutload assembly failed
    exit /b 1
)
endlocal
