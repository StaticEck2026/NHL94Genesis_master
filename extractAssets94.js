const fs = require('fs').promises;
const path = require('path');
const crc32 = require('crc-32'); // Requires 'crc-32' package: npm install crc-32

// Asset definitions from the .lst file
const assets = [
    // { name: 'EALogo.bin', folder: 'NHL94/Graphics', start: 0x00000306, end: 0x00001164 },
    // NHL 94 team palettes, src/teamdata94.asm .pad of each team block (block + $C): home then visitor, 32 bytes each, in ROM order.
    // The 93 file name (extractAssets93-1.1.js) where the bytes equal 93's, 94 added where they differ; Dallas keeps the 93 Minnesota palettes.
    { name: 'ASEh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000038A, end: 0x000003AA }, // ASE home
    { name: 'ASEv.pal', folder: 'NHL94/Graphics/Pals', start: 0x000003AA, end: 0x000003CA }, // ASE visitor
    { name: 'ASWh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000680, end: 0x000006A0 }, // ASW home
    { name: 'ASWv.pal', folder: 'NHL94/Graphics/Pals', start: 0x000006A0, end: 0x000006C0 }, // ASW visitor
    { name: 'BOSh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000972, end: 0x00000992 }, // BOS home
    { name: 'BOSv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000992, end: 0x000009B2 }, // BOS visitor
    { name: 'BUFh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000C58, end: 0x00000C78 }, // BUF home
    { name: 'BUFv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000C78, end: 0x00000C98 }, // BUF visitor
    { name: 'CGYh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000F46, end: 0x00000F66 }, // CGY home
    { name: 'CGYv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00000F66, end: 0x00000F86 }, // CGY visitor
    { name: 'CHIh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001240, end: 0x00001260 }, // CHI home
    { name: 'CHIv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001260, end: 0x00001280 }, // CHI visitor
    { name: 'DETh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000153A, end: 0x0000155A }, // DET home
    { name: 'DETv.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000155A, end: 0x0000157A }, // DET visitor
    { name: 'EDMh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001854, end: 0x00001874 }, // EDM home
    { name: 'EDMv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001874, end: 0x00001894 }, // EDM visitor
    { name: 'HFDh94.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001B50, end: 0x00001B70 }, // HFD home
    { name: 'HFDv94.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001B70, end: 0x00001B90 }, // HFD visitor
    { name: 'LAh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001E5E, end: 0x00001E7E }, // LA home
    { name: 'LAv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00001E7E, end: 0x00001E9E }, // LA visitor
    { name: 'DALh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000215A, end: 0x0000217A }, // DAL home
    { name: 'DALv.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000217A, end: 0x0000219A }, // DAL visitor
    { name: 'MTLh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000244A, end: 0x0000246A }, // MTL home
    { name: 'MTLv.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000246A, end: 0x0000248A }, // MTL visitor
    { name: 'NJh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000274C, end: 0x0000276C }, // NJ home
    { name: 'NJv.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000276C, end: 0x0000278C }, // NJ visitor
    { name: 'NYIh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00002A64, end: 0x00002A84 }, // NYI home
    { name: 'NYIv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00002A84, end: 0x00002AA4 }, // NYI visitor
    { name: 'NYRh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00002D68, end: 0x00002D88 }, // NYR home
    { name: 'NYRv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00002D88, end: 0x00002DA8 }, // NYR visitor
    { name: 'OTWh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003060, end: 0x00003080 }, // OTW home
    { name: 'OTWv94.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003080, end: 0x000030A0 }, // OTW visitor
    { name: 'PHIh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003354, end: 0x00003374 }, // PHI home
    { name: 'PHIv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003374, end: 0x00003394 }, // PHI visitor
    { name: 'PITh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003652, end: 0x00003672 }, // PIT home
    { name: 'PITv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003672, end: 0x00003692 }, // PIT visitor
    { name: 'QUEh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003948, end: 0x00003968 }, // QUE home
    { name: 'QUEv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003968, end: 0x00003988 }, // QUE visitor
    { name: 'SJh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003C4E, end: 0x00003C6E }, // SJ home
    { name: 'SJv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003C6E, end: 0x00003C8E }, // SJ visitor
    { name: 'STLh94.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003F3C, end: 0x00003F5C }, // STL home
    { name: 'STLv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00003F5C, end: 0x00003F7C }, // STL visitor
    { name: 'TBh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004222, end: 0x00004242 }, // TB home
    { name: 'TBv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004242, end: 0x00004262 }, // TB visitor
    { name: 'TORh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004524, end: 0x00004544 }, // TOR home
    { name: 'TORv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004544, end: 0x00004564 }, // TOR visitor
    { name: 'VANh94.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004828, end: 0x00004848 }, // VAN home
    { name: 'VANv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004848, end: 0x00004868 }, // VAN visitor
    { name: 'WPGh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004B16, end: 0x00004B36 }, // WPG home
    { name: 'WPGv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004B36, end: 0x00004B56 }, // WPG visitor
    { name: 'WSHh.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004E08, end: 0x00004E28 }, // WSH home
    { name: 'WSHv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00004E28, end: 0x00004E48 }, // WSH visitor
    { name: 'FLAh.pal', folder: 'NHL94/Graphics/Pals', start: 0x000050F2, end: 0x00005112 }, // FLA home
    { name: 'FLAv.pal', folder: 'NHL94/Graphics/Pals', start: 0x00005112, end: 0x00005132 }, // FLA visitor
    { name: 'ANHh.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000533C, end: 0x0000535C }, // ANH home
    { name: 'ANHv.pal', folder: 'NHL94/Graphics/Pals', start: 0x0000535C, end: 0x0000537C }, // ANH visitor
    // { name: 'Hockey.snd', folder: 'NHL94/Sound', start: 0x0000F4C8, end: 0x00024214 },
    // NHL 94 $1AD90-$F66ED, the incbins of src/sound94.asm ($1AD90-$4B5BF) and src/graphics94.asm: one slice per (the 92 / 93 file name where the asset
    // lines up, else the label), contiguous, end exclusive. Labels from constants or from data read as code are not slice
    // boundaries (see graphics94.asm). Replaces the 94 draft entries $4B7A0-$C0D12 (unknown6, unknown7, unknown9 broken; logos overlapping).
    // NHL 94 sound data ($1AD90-$4B5BF, src/sound94.asm): split as 93 sound93. The Z80 driver, PCM samples and FM patches are byte-identical to 93
    // and keep the 93 file names; sounds 0-$2F are the 93 streams; the songs ($30-$7A) are 94. Pad bytes and the pointer tables are in the source.
    { name: 'z80_snd_drv93.bin', folder: 'NHL94/Sound', start: 0x0001AD91, end: 0x0001B008 }, // Z80 driver after its first byte ($1AD90 is Z80_Program_Code dc.b $18), up to the ld bc of the FM patch bank address (93 file, same bytes)
    { name: 'z80_snd_drv93_end.bin', folder: 'NHL94/Sound', start: 0x0001B00D, end: 0x0001B01B }, // rest of the Z80 driver (93 file, same bytes)
    { name: 'sfx_shotbh_pcm.bin', folder: 'NHL94/Sound', start: 0x0001B094, end: 0x0001B288 }, // sample 2: shotbh (93 file, same bytes)
    { name: 'sfx_pass_pcm.bin', folder: 'NHL94/Sound', start: 0x0001B288, end: 0x0001BFB5 }, // sample 1: pass (93 file, same bytes)
    { name: 'sfx_oooh_pcm.bin', folder: 'NHL94/Sound', start: 0x0001BFB6, end: 0x0001F1FA }, // sample 12: oooh, sfx_id_0D, sfx_id_0E (93 file, same bytes)
    { name: 'sfx_crowdboo_pcm.bin', folder: 'NHL94/Sound', start: 0x0001F1FA, end: 0x00021747 }, // sample 11: crowdboo (93 file, same bytes)
    { name: 'sfx_check_pcm.bin', folder: 'NHL94/Sound', start: 0x00021748, end: 0x0002369A }, // sample 5: check1, check3 (93 file, same bytes)
    { name: 'sfx_crowdcheer_pcm.bin', folder: 'NHL94/Sound', start: 0x0002369A, end: 0x0002657A }, // sample 13: crowdcheer, homewin (93 file, same bytes)
    { name: 'sfx_id_0E_pcm.bin', folder: 'NHL94/Sound', start: 0x0002657A, end: 0x00029FF9 }, // sample 14: sfx_id_0E (93 file, same bytes)
    { name: 'sfx_playerwall_pcm.bin', folder: 'NHL94/Sound', start: 0x00029FFA, end: 0x0002A4AA }, // sample 6: playerwall, sfx_id_21-23 (93 file, same bytes)
    { name: 'sfx_check2_pcm.bin', folder: 'NHL94/Sound', start: 0x0002A4AA, end: 0x0002AED9 }, // sample 4: check2, check4 (93 file, same bytes)
    { name: 'sfx_hithigh_pcm.bin', folder: 'NHL94/Sound', start: 0x0002AEDA, end: 0x0002B430 }, // samples 7 and 10: hithigh, hitlow, check1-4, songs $32 and $35-$37 (93 file, same bytes)
    { name: 'sfx_shotfh_pcm.bin', folder: 'NHL94/Sound', start: 0x0002B430, end: 0x0002BFE8 }, // sample 3: shotfh (93 file, same bytes)
    { name: 'sfx_puckget_pcm.bin', folder: 'NHL94/Sound', start: 0x0002BFE8, end: 0x0002C248 }, // sample 0: puckget (93 file, same bytes)
    { name: 'fm_instrument_patches.bin', folder: 'NHL94/Sound', start: 0x0002C248, end: 0x0002C648 }, // 32 FM patches x 32 bytes (93 file, same bytes)
    { name: 'sfx_beep1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C834, end: 0x0002C840 }, // sound $1 (SFXbeep1)
    { name: 'sfx_id_26_27_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C840, end: 0x0002C844 }, // sound $26, sound $27
    { name: 'sfx_beep2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C844, end: 0x0002C854 }, // sound $2 (SFXbeep2)
    { name: 'sfx_horn_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C854, end: 0x0002C8D0 }, // sound $4 (92 SFXhorn)
    { name: 'sfx_stdef_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C8D0, end: 0x0002C8EC }, // sound $6 (92 SFXstdef)
    { name: 'sfx_puckget_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C8EC, end: 0x0002C908 }, // sound $7 (92 SFXpuckget)
    { name: 'sfx_puckice1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C908, end: 0x0002C918 }, // sound $2C (92 SFXpuckice)
    { name: 'sfx_puckice2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C918, end: 0x0002C928 }, // sound $2D
    { name: 'sfx_puckice3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C928, end: 0x0002C938 }, // sound $2E
    { name: 'sfx_puckice4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C938, end: 0x0002C948 }, // sound $2F
    { name: 'sfx_puckbody_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C948, end: 0x0002C964 }, // sound $24 (92 SFXpuckbody)
    { name: 'sfx_oooh_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C964, end: 0x0002C980 }, // sound $8 (92 SFXoooh)
    { name: 'sfx_puckpost_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C980, end: 0x0002C990 }, // sound $25 (92 SFXpuckpost)
    { name: 'sfx_playerwall_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C990, end: 0x0002C9AC }, // sound $20 (92 SFXplayerwall)
    { name: 'sfx_id_21_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C9AC, end: 0x0002C9C8 }, // sound $21
    { name: 'sfx_id_22_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C9C8, end: 0x0002C9E4 }, // sound $22
    { name: 'sfx_id_23_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002C9E4, end: 0x0002CA00 }, // sound $23
    { name: 'sfx_puckwall1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CA00, end: 0x0002CA10 }, // sound $28
    { name: 'sfx_puckwall2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CA10, end: 0x0002CA20 }, // sound $29
    { name: 'sfx_puckwall3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CA20, end: 0x0002CA30 }, // sound $2A
    { name: 'sfx_puckwall4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CA30, end: 0x0002CA40 }, // sound $2B
    { name: 'sfx_whistle_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CA40, end: 0x0002CADC }, // sound $3 (92 SFXwhistle)
    { name: 'sfx_shotwiff_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CADE, end: 0x0002CAEE }, // sound $5 (92 SFXshotwiff)
    { name: 'sfx_check1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CAEE, end: 0x0002CB0A }, // sound $1C (92 SFXcheck)
    { name: 'sfx_check2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB0A, end: 0x0002CB26 }, // sound $1D
    { name: 'sfx_check3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB26, end: 0x0002CB42 }, // sound $1E
    { name: 'sfx_check4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB42, end: 0x0002CB66 }, // sound $1F
    { name: 'sfx_pass1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB66, end: 0x0002CB76 }, // sound $10 (92 SFXpass)
    { name: 'sfx_pass2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB76, end: 0x0002CB86 }, // sound $11
    { name: 'sfx_pass3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB86, end: 0x0002CB96 }, // sound $12
    { name: 'sfx_pass4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CB96, end: 0x0002CBA6 }, // sound $13
    { name: 'sfx_shotbh1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBA6, end: 0x0002CBB6 }, // sound $14 (92 SFXshotbh)
    { name: 'sfx_shotbh2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBB6, end: 0x0002CBC6 }, // sound $15
    { name: 'sfx_shotbh3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBC6, end: 0x0002CBD6 }, // sound $16
    { name: 'sfx_shotbh4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBD6, end: 0x0002CBE6 }, // sound $17
    { name: 'sfx_shotfh1_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBE6, end: 0x0002CBF6 }, // sound $18 (92 SFXshotfh)
    { name: 'sfx_shotfh2_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CBF6, end: 0x0002CC06 }, // sound $19
    { name: 'sfx_shotfh3_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC06, end: 0x0002CC16 }, // sound $1A
    { name: 'sfx_shotfh4_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC16, end: 0x0002CC26 }, // sound $1B
    { name: 'sfx_hithigh_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC26, end: 0x0002CC36 }, // sound $9 (SFXhithigh)
    { name: 'sfx_hitlow_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC36, end: 0x0002CC46 }, // sound $A (SFXhitlow)
    { name: 'sfx_homewin_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC46, end: 0x0002CC7E }, // sound $F
    { name: 'sfx_crowdcheer_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC7E, end: 0x0002CC8E }, // sound $B (SFXcrowdcheer)
    { name: 'sfx_crowdboo_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC8E, end: 0x0002CC9E }, // sound $C (SFXcrowdboo)
    { name: 'sfx_id_0E_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CC9E, end: 0x0002CCBA }, // sound $E
    { name: 'sfx_id_0D_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CCBA, end: 0x0002CCCA }, // sound $D
    { name: 'sfx_siren_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CCCA, end: 0x0002CEF2 }, // sound $0 (92 SFXsiren)
    { name: 'fmtune_id_30_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002CEF2, end: 0x0002D29E }, // song $30: ChooseSong, TeamSongs BOS
    { name: 'fmtune_id_31_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002D29E, end: 0x0002D6CA }, // song $31: ChooseSong, TeamSongs BOS
    { name: 'fmtune_id_32_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002D6CA, end: 0x0002D966 }, // song $32: ChooseSong, TeamSongs BOS
    { name: 'fmtune_id_33_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002D966, end: 0x0002DD36 }, // song $33: ChooseSong, TeamSongs BUF
    { name: 'fmtune_id_34_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002DD36, end: 0x0002E6FA }, // song $34: ChooseSong, TeamSongs BUF, RandomSongs
    { name: 'fmtune_id_35_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002E6FA, end: 0x0002EBBE }, // song $35: ChooseSong, TeamSongs CGY
    { name: 'fmtune_id_36_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002EBBE, end: 0x0002F222 }, // song $36: ChooseSong, TeamSongs CGY
    { name: 'fmtune_id_37_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002F222, end: 0x0002F73A }, // song $37: ChooseSong, TeamSongs CGY
    { name: 'fmtune_id_38_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002F73A, end: 0x0002FD6E }, // song $38: ChooseSong, TeamSongs CHI
    { name: 'fmtune_id_39_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0002FD6E, end: 0x000302BA }, // song $39: ChooseSong, TeamSongs CHI
    { name: 'fmtune_id_3A_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000302BA, end: 0x00030696 }, // song $3A: ChooseSong, TeamSongs CHI
    { name: 'fmtune_id_3B_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00030696, end: 0x00030C0A }, // song $3B: ChooseSong, TeamSongs DET
    { name: 'fmtune_id_3C_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00030C0A, end: 0x00031076 }, // song $3C: ChooseSong, TeamSongs DET
    { name: 'fmtune_id_3D_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00031076, end: 0x000313CA }, // song $3D: ChooseSong, TeamSongs DET
    { name: 'fmtune_id_3E_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000313CA, end: 0x0003184E }, // song $3E: ChooseSong, TeamSongs EDM
    { name: 'fmtune_id_3F_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003184E, end: 0x00031BAA }, // song $3F: ChooseSong, TeamSongs EDM
    { name: 'fmtune_id_40_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00031BAA, end: 0x000323AE }, // song $40: ChooseSong, TeamSongs HFD, RandomSongs
    { name: 'fmtune_id_41_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000323AE, end: 0x000329EA }, // song $41: ChooseSong, TeamSongs HFD
    { name: 'fmtune_id_42_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000329EA, end: 0x00033066 }, // song $42: ChooseSong, TeamSongs HFD, RandomSongs
    { name: 'fmtune_id_43_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00033066, end: 0x00033472 }, // song $43: ChooseSong, TeamSongs LA
    { name: 'fmtune_id_44_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00033472, end: 0x00033AC6 }, // song $44: ChooseSong, TeamSongs LA
    { name: 'fmtune_id_45_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00033AC6, end: 0x0003411A }, // song $45: ChooseSong, TeamSongs LA
    { name: 'fmtune_id_46_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003411A, end: 0x00034632 }, // song $46: ChooseSong, TeamSongs LA
    { name: 'fmtune_id_47_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00034632, end: 0x00034C92 }, // song $47: ChooseSong, TeamSongs NYI
    { name: 'fmtune_id_48_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00034C92, end: 0x00034E9E }, // song $48: ChooseSong, TeamSongs NYI
    { name: 'fmtune_id_49_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00034E9E, end: 0x0003554A }, // song $49: ChooseSong, TeamSongs NYI, RandomSongs
    { name: 'fmtune_id_4A_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003554A, end: 0x000358D6 }, // song $4A: ChooseSong, TeamSongs DAL
    { name: 'fmtune_id_4B_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000358D6, end: 0x00035B3A }, // song $4B: ChooseSong, TeamSongs DAL
    { name: 'fmtune_id_4C_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00035B3A, end: 0x000362BE }, // song $4C: ChooseSong, TeamSongs MTL
    { name: 'fmtune_id_4D_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000362BE, end: 0x000366D2 }, // song $4D: ChooseSong, TeamSongs MTL
    { name: 'fmtune_id_4E_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000366D2, end: 0x00036B4E }, // song $4E: ChooseSong, TeamSongs MTL
    { name: 'fmtune_id_4F_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00036B4E, end: 0x00036F12 }, // song $4F: ChooseSong, TeamSongs MTL
    { name: 'fmtune_id_50_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00036F12, end: 0x000374F2 }, // song $50: ChooseSong, TeamSongs NJ
    { name: 'fmtune_id_51_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000374F2, end: 0x00037A7E }, // song $51: ChooseSong, TeamSongs NJ
    { name: 'fmtune_id_52_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00037A7E, end: 0x00037FB2 }, // song $52: ChooseSong, TeamSongs NJ
    { name: 'fmtune_id_53_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00037FB2, end: 0x0003845A }, // song $53: ChooseSong, TeamSongs NYR / ASE / ASW
    { name: 'fmtune_id_54_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003845A, end: 0x00038876 }, // song $54: ChooseSong, TeamSongs NYR / ASE / ASW
    { name: 'fmtune_id_55_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00038876, end: 0x00038B3A }, // song $55: ChooseSong, TeamSongs NYR / ASE / ASW
    { name: 'fmtune_id_56_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00038B3A, end: 0x0003901E }, // song $56: ChooseSong, TeamSongs PHI
    { name: 'fmtune_id_57_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003901E, end: 0x00039562 }, // song $57: ChooseSong, TeamSongs PHI
    { name: 'fmtune_id_58_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00039562, end: 0x00039FCE }, // song $58: ChooseSong, TeamSongs PHI, RandomSongs
    { name: 'fmtune_id_59_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00039FCE, end: 0x0003A572 }, // song $59: ChooseSong, TeamSongs PIT
    { name: 'fmtune_id_5A_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003A572, end: 0x0003A81E }, // song $5A: ChooseSong, TeamSongs (25 teams: all but CGY, PHI and SJ)
    { name: 'fmtune_id_5B_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003A81E, end: 0x0003AE5A }, // song $5B: ChooseSong, TeamSongs PIT
    { name: 'fmtune_id_5C_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003AE5A, end: 0x0003B5CE }, // song $5C: ChooseSong, TeamSongs PIT, RandomSongs
    { name: 'fmtune_id_5D_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003B5CE, end: 0x0003BE12 }, // song $5D: ChooseSong, TeamSongs QUE
    { name: 'fmtune_id_5E_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003BE12, end: 0x0003C60E }, // song $5E: ChooseSong, TeamSongs QUE
    { name: 'fmtune_id_5F_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003C60E, end: 0x0003CC32 }, // song $5F: ChooseSong, TeamSongs SJ
    { name: 'fmtune_id_60_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003CC32, end: 0x0003D396 }, // song $60: ChooseSong, TeamSongs SJ
    { name: 'fmtune_id_61_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003D396, end: 0x0003DA2E }, // song $61: ChooseSong, TeamSongs SJ
    { name: 'fmtune_id_62_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003DA2E, end: 0x0003E1A6 }, // song $62: ChooseSong, not in TeamSongs or RandomSongs
    { name: 'fmtune_id_63_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003E1A6, end: 0x0003E84E }, // song $63: ChooseSong, TeamSongs SJ
    { name: 'fmtune_id_64_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003E84E, end: 0x0003EDE2 }, // song $64: ChooseSong, TeamSongs SJ
    { name: 'fmtune_id_65_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003EDE2, end: 0x0003F616 }, // song $65: ChooseSong, TeamSongs CHI / SJ, RandomSongs
    { name: 'fmtune_id_66_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003F616, end: 0x0003FF2A }, // song $66: ChooseSong, RandomSongs
    { name: 'fmtune_id_67_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0003FF2A, end: 0x000403CE }, // song $67: ChooseSong, TeamSongs STL
    { name: 'fmtune_id_68_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000403CE, end: 0x000408DA }, // song $68: ChooseSong, TeamSongs STL
    { name: 'fmtune_id_69_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000408DA, end: 0x00040EA6 }, // song $69: ChooseSong, TeamSongs STL
    { name: 'fmtune_id_6A_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00040EA6, end: 0x000412D6 }, // song $6A: ChooseSong, TeamSongs TB
    { name: 'fmtune_id_6B_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000412D6, end: 0x000414B2 }, // song $6B: ChooseSong, TeamSongs TB
    { name: 'fmtune_id_6C_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000414B2, end: 0x0004196E }, // song $6C: ChooseSong, TeamSongs TOR
    { name: 'fmtune_id_6D_cmdstream.bin', folder: 'NHL94/Sound', start: 0x0004196E, end: 0x00041E52 }, // song $6D: ChooseSong, TeamSongs TOR
    { name: 'fmtune_id_6E_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00041E52, end: 0x000423EE }, // song $6E: ChooseSong, TeamSongs VAN
    { name: 'fmtune_id_6F_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000423EE, end: 0x000426B6 }, // song $6F: ChooseSong, TeamSongs VAN
    { name: 'fmtune_id_70_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000426B6, end: 0x00042852 }, // song $70: ChooseSong, TeamSongs VAN
    { name: 'fmtune_id_71_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00042852, end: 0x00042CDE }, // song $71: ChooseSong, TeamSongs WSH
    { name: 'fmtune_id_72_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00042CDE, end: 0x000431E6 }, // song $72: ChooseSong, not in TeamSongs or RandomSongs
    { name: 'fmtune_id_73_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000431E6, end: 0x000437B6 }, // song $73: ChooseSong, TeamSongs WSH
    { name: 'fmtune_id_74_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000437B6, end: 0x00043F32 }, // song $74: ChooseSong, TeamSongs WSH
    { name: 'fmtune_id_75_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00043F32, end: 0x000442BE }, // song $75: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
    { name: 'fmtune_id_76_cmdstream.bin', folder: 'NHL94/Sound', start: 0x000442BE, end: 0x00044B12 }, // song $76: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
    { name: 'fmtune_id_77_cmdstream.bin', folder: 'NHL94/Sound', start: 0x00044B12, end: 0x0004507A }, // song $77: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
    { name: 'fmtune_title_cmdstream94.bin', folder: 'NHL94/Sound', start: 0x0004507A, end: 0x00046D88 }, // song $78 (93 $35): ExitToOpening, newTitleScreen. 94: one stream that loops to its start (93: intro, loop body)
    { name: 'fmtune_eog_cmdstream94.bin', folder: 'NHL94/Sound', start: 0x00046D8C, end: 0x000490DE }, // song $79 (93 $36): IntermissionStart, StartHL2 (penalty94) (differs from 93)
    { name: 'fmtune_scouting_cmdstream94.bin', folder: 'NHL94/Sound', start: 0x000490E2, end: 0x0004B5BC }, // song $7A (93 $37): ScoutingReport (scout94) (differs from 93)
    { name: 'ScoutTextScript.bin', folder: 'NHL94/Text', start: 0x0004B5C0, end: 0x0004B7A0 }, // unk_4B5C0
    { name: 'GameSetUp94-1.map.jim', folder: 'NHL94/Graphics', start: 0x0004B7A0, end: 0x0004DEEE }, // unk_4B7A0
    { name: 'GameSetUp94-2.map.jim', folder: 'NHL94/Graphics', start: 0x0004DEEE, end: 0x0004E45C }, // unk_4DEEE
    { name: 'Title94-1.map.jim', folder: 'NHL94/Graphics', start: 0x0004E45C, end: 0x00052DAA }, // TitleScreenImg
    { name: 'Title94-2.map.jim', folder: 'NHL94/Graphics', start: 0x00052DAA, end: 0x0005338C }, // NHLShieldImg
    { name: 'Title94-3.map.jim', folder: 'NHL94/Graphics', start: 0x0005338C, end: 0x0005394E }, // PAlogoImg
    { name: 'Title94-4.map.jim', folder: 'NHL94/Graphics', start: 0x0005394E, end: 0x00054E24 }, // TitleImg
    { name: 'Scouting94.map.jim', folder: 'NHL94/Graphics', start: 0x00054E24, end: 0x00055B7E }, // unk_54E24
    { name: 'Framer.map.jim', folder: 'NHL94/Graphics', start: 0x00055B7E, end: 0x00055BF6 }, // framermap
    { name: 'FaceOff.map.jim', folder: 'NHL94/Graphics', start: 0x00055BF6, end: 0x0005605A }, // FaceOffMap
    { name: 'IceRink94.map.jim', folder: 'NHL94/Graphics', start: 0x0005605A, end: 0x0005C408 }, // Rinktilelist
    { name: 'Refs.map.jim', folder: 'NHL94/Graphics', start: 0x0005C408, end: 0x0005CF64 }, // RefsMap
    { name: 'Refs2.map.jim', folder: 'NHL94/Graphics', start: 0x0005CF64, end: 0x0005DE7A }, // unk_5CF64
    { name: 'Sprites.bin', folder: 'NHL94/Graphics', start: 0x0005DE7A, end: 0x0005DE84 }, // off_5DE7A
    { name: 'Spritetiles.bin', folder: 'NHL94/Graphics', start: 0x0005DE84, end: 0x0009E724 }, // Spritetiles
    { name: 'frameSprData.bin', folder: 'NHL94/Graphics', start: 0x0009E724, end: 0x000A44C8 }, // frameSprData
    { name: 'Hotlist.bin', folder: 'NHL94/Graphics', start: 0x000A44C8, end: 0x000A4B54 }, // Hotlist
    { name: 'Crowd.anim', folder: 'NHL94/Graphics', start: 0x000A4B54, end: 0x000A78AE }, // CrowdFrameList
    { name: 'FaceOff.anim', folder: 'NHL94/Graphics', start: 0x000A78AE, end: 0x000A8922 }, // unk_A78AE
    { name: 'Zam.anim', folder: 'NHL94/Graphics', start: 0x000A8922, end: 0x000A9A10 }, // ZamFrameList
    { name: 'BigFont94.map.jim', folder: 'NHL94/Graphics', start: 0x000A9A10, end: 0x000AAC52 }, // unk_A9A10
    { name: 'SmallFont.map.jim', folder: 'NHL94/Graphics', start: 0x000AAC52, end: 0x000AB920 }, // unk_AAC52
    { name: 'EnergyBar.map.jim', folder: 'NHL94/Graphics', start: 0x000AB920, end: 0x000ABA14 }, // unk_AB920
    { name: 'TeamBlocks.map.jim', folder: 'NHL94/Graphics', start: 0x000ABA14, end: 0x000AFE12 }, // unk_ABA14
    { name: 'TeamBlocks94.map.jim', folder: 'NHL94/Graphics', start: 0x000AFE12, end: 0x000B3530 }, // unk_AFE12
    { name: 'EASN.map.jim', folder: 'NHL94/Graphics', start: 0x000B3530, end: 0x000B3640 }, // unk_B3530
    { name: 'Arrows.map.jim', folder: 'NHL94/Graphics', start: 0x000B3640, end: 0x000B389C }, // unk_B3640
    { name: 'RonBarr.map.jim', folder: 'NHL94/Graphics', start: 0x000B389C, end: 0x000B3E74 }, // unk_B389C
    { name: 'Scores.map.jim', folder: 'NHL94/Graphics', start: 0x000B3E74, end: 0x000B425A }, // unk_B3E74
    { name: 'EASportsMap.bin', folder: 'NHL94/Graphics', start: 0x000B425A, end: 0x000B5180 }, // unk_B425A
    { name: 'IceRink94Reverse.map.jim', folder: 'NHL94/Graphics', start: 0x000B5180, end: 0x000BB4EE }, // RevRinkTilelist
    { name: 'ReplayOptions.map.jim', folder: 'NHL94/Graphics', start: 0x000BB4EE, end: 0x000BC05C }, // unk_BB4EE
    { name: 'PauseScreen.map.jim', folder: 'NHL94/Graphics', start: 0x000BC05C, end: 0x000BE26A }, // unk_BC05C
    { name: 'SmallFont94.map.jim', folder: 'NHL94/Graphics', start: 0x000BE26A, end: 0x000BEFB8 }, // unk_BE26A
    { name: 'GameSetupBkgd1.map.jim', folder: 'NHL94/Graphics', start: 0x000BEFB8, end: 0x000BF542 }, // unk_BEFB8
    { name: 'GameSetupBkgd2.map.jim', folder: 'NHL94/Graphics', start: 0x000BF542, end: 0x000BF702 }, // unk_BF542
    { name: 'GameSetupLogoBorder.map.jim', folder: 'NHL94/Graphics', start: 0x000BF702, end: 0x000BF8D0 }, // unk_BF702
    { name: 'logoANA.map.jim', folder: 'NHL94/Graphics', start: 0x000BF8D0, end: 0x000BFD66 }, // logoANH
    { name: 'logoBOS.map.jim', folder: 'NHL94/Graphics', start: 0x000BFD66, end: 0x000C00BC }, // logoBOS
    { name: 'logoBUF.map.jim', folder: 'NHL94/Graphics', start: 0x000C00BC, end: 0x000C0412 }, // logoBUF
    { name: 'logoCGY.map.jim', folder: 'NHL94/Graphics', start: 0x000C0412, end: 0x000C08A8 }, // logoCGY
    { name: 'logoCHI.map.jim', folder: 'NHL94/Graphics', start: 0x000C08A8, end: 0x000C0CDE }, // logoCHI
    { name: 'logoDET.map.jim', folder: 'NHL94/Graphics', start: 0x000C0CDE, end: 0x000C1034 }, // logoDET
    { name: 'logoEDM.map.jim', folder: 'NHL94/Graphics', start: 0x000C1034, end: 0x000C142A }, // logoEDM
    { name: 'logoFLA.map.jim', folder: 'NHL94/Graphics', start: 0x000C142A, end: 0x000C1900 }, // logoFLA
    { name: 'logoHFD.map.jim', folder: 'NHL94/Graphics', start: 0x000C1900, end: 0x000C1B96 }, // logoHFD
    { name: 'logoNYI.map.jim', folder: 'NHL94/Graphics', start: 0x000C1B96, end: 0x000C1FEC }, // logoNYI
    { name: 'logoLA.map.jim', folder: 'NHL94/Graphics', start: 0x000C1FEC, end: 0x000C2362 }, // logoLA
    { name: 'logoDAL.map.jim', folder: 'NHL94/Graphics', start: 0x000C2362, end: 0x000C2638 }, // logoDAL
    { name: 'logoMTL.map.jim', folder: 'NHL94/Graphics', start: 0x000C2638, end: 0x000C29AE }, // logoMTL
    { name: 'logoNJ.map.jim', folder: 'NHL94/Graphics', start: 0x000C29AE, end: 0x000C2E64 }, // logoNJ
    { name: 'logoNYR.map.jim', folder: 'NHL94/Graphics', start: 0x000C2E64, end: 0x000C333A }, // logoNYR
    { name: 'logoOTW.map.jim', folder: 'NHL94/Graphics', start: 0x000C333A, end: 0x000C3750 }, // logoOTW
    { name: 'logoPHI.map.jim', folder: 'NHL94/Graphics', start: 0x000C3750, end: 0x000C3B06 }, // logoPHI
    { name: 'logoPIT.map.jim', folder: 'NHL94/Graphics', start: 0x000C3B06, end: 0x000C3E7C }, // logoPIT
    { name: 'logoQUE.map.jim', folder: 'NHL94/Graphics', start: 0x000C3E7C, end: 0x000C41D2 }, // logoQUE
    { name: 'logoSJ.map.jim', folder: 'NHL94/Graphics', start: 0x000C41D2, end: 0x000C4608 }, // logoSJ
    { name: 'logoSTL.map.jim', folder: 'NHL94/Graphics', start: 0x000C4608, end: 0x000C49DE }, // logoSTL
    { name: 'logoTB.map.jim', folder: 'NHL94/Graphics', start: 0x000C49DE, end: 0x000C4DF4 }, // logoTB
    { name: 'logoTOR.map.jim', folder: 'NHL94/Graphics', start: 0x000C4DF4, end: 0x000C514A }, // logoTOR
    { name: 'logoVAN.map.jim', folder: 'NHL94/Graphics', start: 0x000C514A, end: 0x000C5560 }, // logoVAN
    { name: 'logoWSH.map.jim', folder: 'NHL94/Graphics', start: 0x000C5560, end: 0x000C57D6 }, // logoWSH
    { name: 'logoWPG.map.jim', folder: 'NHL94/Graphics', start: 0x000C57D6, end: 0x000C5C4C }, // logoWPG
    { name: 'logoASE.map.jim', folder: 'NHL94/Graphics', start: 0x000C5C4C, end: 0x000C6022 }, // logoASE
    { name: 'logoASW.map.jim', folder: 'NHL94/Graphics', start: 0x000C6022, end: 0x000C63F8 }, // logoASW
    { name: 'PicturePalette.bin', folder: 'NHL94/Graphics', start: 0x000C63F8, end: 0x000C682E }, // unk_C63F8
    { name: 'NoPicSkater1.bin', folder: 'NHL94/Graphics', start: 0x000C682E, end: 0x000C6B98 }, // unk_C682E
    { name: 'NoPicSkater2.bin', folder: 'NHL94/Graphics', start: 0x000C6B98, end: 0x000C6F02 }, // unk_C6B98
    { name: 'NoPicGoalie1.bin', folder: 'NHL94/Graphics', start: 0x000C6F02, end: 0x000C726C }, // unk_C6F02
    // The player cards ($C726C-$E9A7F): one file per card, named for the player (roster String in src/teamdata94.asm), then the Player Cards screen picture
    { name: 'NoPicGoalie2.bin', folder: 'NHL94/Graphics', start: 0x000C726C, end: 0x000C75D6 }, // NoPicGoalie2
    { name: 'CardAndyMoog.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C75D6, end: 0x000C7940 }, // CardAndyMoog
    { name: 'CardRayBourque.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C7940, end: 0x000C7CAA }, // CardRayBourque
    { name: 'CardAdamOates.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C7CAA, end: 0x000C8014 }, // CardAdamOates
    { name: 'CardDonSweeney.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C8014, end: 0x000C837E }, // CardDonSweeney
    { name: 'CardJoeJuneau.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C837E, end: 0x000C86E8 }, // CardJoeJuneau
    { name: 'CardCamNeely.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C86E8, end: 0x000C8A52 }, // CardCamNeely
    { name: 'CardAlexnderMogilny.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C8A52, end: 0x000C8DBC }, // CardAlexnderMogilny
    { name: 'CardPatLaFontaine.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C8DBC, end: 0x000C9126 }, // CardPatLaFontaine
    { name: 'CardDaleHawerchuk.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C9126, end: 0x000C9490 }, // CardDaleHawerchuk
    { name: 'CardDougBodger.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C9490, end: 0x000C97FA }, // CardDougBodger
    { name: 'CardGrantFuhr.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C97FA, end: 0x000C9B64 }, // CardGrantFuhr
    { name: 'CardPetrSvoboda.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C9B64, end: 0x000C9ECE }, // CardPetrSvoboda
    { name: 'CardMikeVernon.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000C9ECE, end: 0x000CA238 }, // CardMikeVernon
    { name: 'CardGaryRoberts.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CA238, end: 0x000CA5A2 }, // CardGaryRoberts
    { name: 'CardTheorenFleury.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CA5A2, end: 0x000CA90C }, // CardTheorenFleury
    { name: 'CardGarySuter.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CA90C, end: 0x000CAC76 }, // CardGarySuter
    { name: 'CardAlMacInnis.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CAC76, end: 0x000CAFE0 }, // CardAlMacInnis
    { name: 'CardJoeNieuwendyk.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CAFE0, end: 0x000CB34A }, // CardJoeNieuwendyk
    { name: 'CardEdBelfour.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CB34A, end: 0x000CB6B4 }, // CardEdBelfour
    { name: 'CardJeremyRoenick.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CB6B4, end: 0x000CBA1E }, // CardJeremyRoenick
    { name: 'CardSteveLarmer.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CBA1E, end: 0x000CBD88 }, // CardSteveLarmer
    { name: 'CardChrisChelios.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CBD88, end: 0x000CC0F2 }, // CardChrisChelios
    { name: 'CardSteveSmith.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CC0F2, end: 0x000CC45C }, // CardSteveSmith
    { name: 'CardMichelGoulet.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CC45C, end: 0x000CC7C6 }, // CardMichelGoulet
    { name: 'CardTimCheveldae.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CC7C6, end: 0x000CCB30 }, // CardTimCheveldae
    { name: 'CardSteveYzerman.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CCB30, end: 0x000CCE9A }, // CardSteveYzerman
    { name: 'CardSergeiFedorov.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CCE9A, end: 0x000CD204 }, // CardSergeiFedorov
    { name: 'CardPaulCoffey.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CD204, end: 0x000CD56E }, // CardPaulCoffey
    { name: 'CardSteveChiasson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CD56E, end: 0x000CD8D8 }, // CardSteveChiasson
    { name: 'CardDinoCiccarelli.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CD8D8, end: 0x000CDC42 }, // CardDinoCiccarelli
    { name: 'CardBillRanford.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CDC42, end: 0x000CDFAC }, // CardBillRanford
    { name: 'CardDaveManson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CDFAC, end: 0x000CE316 }, // CardDaveManson
    { name: 'CardIgorKravchuk.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CE316, end: 0x000CE680 }, // CardIgorKravchuk
    { name: 'CardShayneCorson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CE680, end: 0x000CE9EA }, // CardShayneCorson
    { name: 'CardDougWeight.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CE9EA, end: 0x000CEDF0 }, // CardDougWeight
    { name: 'CardPetrKlima.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CEDF0, end: 0x000CF15A }, // CardPetrKlima
    { name: 'CardSeanBurke.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CF15A, end: 0x000CF4C4 }, // CardSeanBurke
    { name: 'CardAndrewCassels.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CF4C4, end: 0x000CF82E }, // CardAndrewCassels
    { name: 'CardGeoffSanderson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CF82E, end: 0x000CFB98 }, // CardGeoffSanderson
    { name: 'CardPatVerbeek.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CFB98, end: 0x000CFF02 }, // CardPatVerbeek
    { name: 'CardZarleyZalapski.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000CFF02, end: 0x000D026C }, // CardZarleyZalapski
    { name: 'CardEricWeinrich.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D026C, end: 0x000D05D6 }, // CardEricWeinrich
    { name: 'CardBenoitHogue.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D05D6, end: 0x000D0940 }, // CardBenoitHogue
    { name: 'CardSteveThomas.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D0940, end: 0x000D0CAA }, // CardSteveThomas
    { name: 'CardPierreTurgeon.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D0CAA, end: 0x000D1014 }, // CardPierreTurgeon
    { name: 'CardGlennHealy.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D1014, end: 0x000D137E }, // CardGlennHealy
    { name: 'CardDariusKasparitis.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D137E, end: 0x000D16E8 }, // CardDariusKasparitis
    { name: 'CardVladimirMalakhov.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D16E8, end: 0x000D1AEE }, // CardVladimirMalakhov
    { name: 'CardKellyHrudey.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D1AEE, end: 0x000D1EDC }, // CardKellyHrudey
    { name: 'CardWayneGretzky.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D1EDC, end: 0x000D2246 }, // CardWayneGretzky
    { name: 'CardLucRobitaille.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D2246, end: 0x000D25B0 }, // CardLucRobitaille
    { name: 'CardTomasSandstrom.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D25B0, end: 0x000D291A }, // CardTomasSandstrom
    { name: 'CardRobBlake.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D291A, end: 0x000D2C84 }, // CardRobBlake
    { name: 'CardMartyMcSorley.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D2C84, end: 0x000D2FEE }, // CardMartyMcSorley
    { name: 'CardJonCasey.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D2FEE, end: 0x000D3358 }, // CardJonCasey
    { name: 'CardMikeModano.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D3358, end: 0x000D36C2 }, // CardMikeModano
    { name: 'CardMarkTinordi.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D36C2, end: 0x000D3A2C }, // CardMarkTinordi
    { name: 'CardTommySjodin.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D3A2C, end: 0x000D3D96 }, // CardTommySjodin
    { name: 'CardDaveGagner.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D3D96, end: 0x000D4100 }, // CardDaveGagner
    { name: 'CardRussCourtnall.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D4100, end: 0x000D446A }, // CardRussCourtnall
    { name: 'CardPatrickRoy.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D446A, end: 0x000D47D4 }, // CardPatrickRoy
    { name: 'CardEricDesjardins.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D47D4, end: 0x000D4B3E }, // CardEricDesjardins
    { name: 'CardMattSchneider.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D4B3E, end: 0x000D4F14 }, // CardMattSchneider
    { name: 'CardKirkMuller.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D4F14, end: 0x000D527E }, // CardKirkMuller
    { name: 'CardVincentDamphousse.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D527E, end: 0x000D55E8 }, // CardVincentDamphousse
    { name: 'CardBrianBellows.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D55E8, end: 0x000D5952 }, // CardBrianBellows
    { name: 'CardScottStevens.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D5952, end: 0x000D5CBC }, // CardScottStevens
    { name: 'CardChrisTerreri.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D5CBC, end: 0x000D6026 }, // CardChrisTerreri
    { name: 'CardVachslavFetisov.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D6026, end: 0x000D6390 }, // CardVachslavFetisov
    { name: 'CardStephaneRicher.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D6390, end: 0x000D66FA }, // CardStephaneRicher
    { name: 'CardAlexnderSemak.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D66FA, end: 0x000D6A64 }, // CardAlexnderSemak
    { name: 'CardClaudeLemieux.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D6A64, end: 0x000D6DCE }, // CardClaudeLemieux
    { name: 'CardJohnVanbiesbrk.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D6DCE, end: 0x000D71A4 }, // CardJohnVanbiesbrk
    { name: 'CardMarkMessier.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D71A4, end: 0x000D750E }, // CardMarkMessier
    { name: 'CardJamesPatrick.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D750E, end: 0x000D7878 }, // CardJamesPatrick
    { name: 'CardMikeGartner.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D7878, end: 0x000D7BE2 }, // CardMikeGartner
    { name: 'CardBrianLeetch.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D7BE2, end: 0x000D7F4C }, // CardBrianLeetch
    { name: 'CardEsaTikkanen.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D7F4C, end: 0x000D82B6 }, // CardEsaTikkanen
    { name: 'CardPeterSidorkwicz.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D82B6, end: 0x000D868C }, // CardPeterSidorkwicz
    { name: 'CardSylvainTurgeon.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D868C, end: 0x000D89F6 }, // CardSylvainTurgeon
    { name: 'CardNormMaciver.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D89F6, end: 0x000D8D60 }, // CardNormMaciver
    { name: 'CardBradShaw.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D8D60, end: 0x000D90CA }, // CardBradShaw
    { name: 'CardJamieBaker.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D90CA, end: 0x000D9434 }, // CardJamieBaker
    { name: 'CardBobKudelski.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D9434, end: 0x000D979E }, // CardBobKudelski
    { name: 'CardEricLindros.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D979E, end: 0x000D9B08 }, // CardEricLindros
    { name: 'CardRodBrindAmour.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D9B08, end: 0x000D9E72 }, // CardRodBrindAmour
    { name: 'CardGarryGalley.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000D9E72, end: 0x000DA1DC }, // CardGarryGalley
    { name: 'CardMarkRecchi.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DA1DC, end: 0x000DA546 }, // CardMarkRecchi
    { name: 'CardTommySoderstrom.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DA546, end: 0x000DA8B0 }, // CardTommySoderstrom
    { name: 'CardDimitriYushkevich.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DA8B0, end: 0x000DAC1A }, // CardDimitriYushkevich
    { name: 'CardTomBarrasso.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DAC1A, end: 0x000DAF84 }, // CardTomBarrasso
    { name: 'CardMarioLemieux.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DAF84, end: 0x000DB2EE }, // CardMarioLemieux
    { name: 'CardKevinStevens.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DB2EE, end: 0x000DB658 }, // CardKevinStevens
    { name: 'CardJaromirJagr.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DB658, end: 0x000DB9C2 }, // CardJaromirJagr
    { name: 'CardLarryMurphy.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DB9C2, end: 0x000DBD2C }, // CardLarryMurphy
    { name: 'CardUlfSamuelsson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DBD2C, end: 0x000DC096 }, // CardUlfSamuelsson
    { name: 'CardRonHextall.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DC096, end: 0x000DC46C }, // CardRonHextall
    { name: 'CardOwenNolan.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DC46C, end: 0x000DC7D6 }, // CardOwenNolan
    { name: 'CardSteveDuchesne.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DC7D6, end: 0x000DCB40 }, // CardSteveDuchesne
    { name: 'CardJoeSakic.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DCB40, end: 0x000DCEAA }, // CardJoeSakic
    { name: 'CardCurtisLeschyshyn.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DCEAA, end: 0x000DD214 }, // CardCurtisLeschyshyn
    { name: 'CardMatsSundin.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DD214, end: 0x000DD57E }, // CardMatsSundin
    { name: 'CardKellyKisio.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DD57E, end: 0x000DD8E8 }, // CardKellyKisio
    { name: 'CardDougWilson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DD8E8, end: 0x000DDC52 }, // CardDougWilson
    { name: 'CardPatFalloon.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DDC52, end: 0x000DDFBC }, // CardPatFalloon
    { name: 'CardArtursIrbe.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DDFBC, end: 0x000DE326 }, // CardArtursIrbe
    { name: 'CardNeilWilkinson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DE326, end: 0x000DE690 }, // CardNeilWilkinson
    { name: 'CardJohanGarpenlov.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DE690, end: 0x000DE9FA }, // CardJohanGarpenlov
    { name: 'CardCurtisJoseph.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DE9FA, end: 0x000DED64 }, // CardCurtisJoseph
    { name: 'CardCraigJanney.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DED64, end: 0x000DF0CE }, // CardCraigJanney
    { name: 'CardBrettHull.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DF0CE, end: 0x000DF438 }, // CardBrettHull
    { name: 'CardGarthButcher.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DF438, end: 0x000DF7A2 }, // CardGarthButcher
    { name: 'CardJeffBrown.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DF7A2, end: 0x000DFB0C }, // CardJeffBrown
    { name: 'CardBrendanShanahan.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DFB0C, end: 0x000DFE76 }, // CardBrendanShanahan
    { name: 'CardBrianBradley.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000DFE76, end: 0x000E01E0 }, // CardBrianBradley
    { name: 'CardWendellYoung.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E01E0, end: 0x000E054A }, // CardWendellYoung
    { name: 'CardRomanHamrlik.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E054A, end: 0x000E08B4 }, // CardRomanHamrlik
    { name: 'CardBobBeers.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E08B4, end: 0x000E0C1E }, // CardBobBeers
    { name: 'CardMikaelAndersson.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E0C1E, end: 0x000E0F88 }, // CardMikaelAndersson
    { name: 'CardChrisKontos.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E0F88, end: 0x000E12F2 }, // CardChrisKontos
    { name: 'CardFelixPotvin.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E12F2, end: 0x000E165C }, // CardFelixPotvin
    { name: 'CardDougGilmour.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E165C, end: 0x000E19C6 }, // CardDougGilmour
    { name: 'CardNikolaiBorshevsky.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E19C6, end: 0x000E1D30 }, // CardNikolaiBorshevsky
    { name: 'CardDaveEllett.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E1D30, end: 0x000E209A }, // CardDaveEllett
    { name: 'CardToddGill.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E209A, end: 0x000E2404 }, // CardToddGill
    { name: 'CardDaveAndreychuk.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E2404, end: 0x000E280A }, // CardDaveAndreychuk
    { name: 'CardKirkMcLean.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E280A, end: 0x000E2B74 }, // CardKirkMcLean
    { name: 'CardGeoffCourtnall.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E2B74, end: 0x000E2EDE }, // CardGeoffCourtnall
    { name: 'CardPavelBure.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E2EDE, end: 0x000E3248 }, // CardPavelBure
    { name: 'CardJyrkiLumme.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E3248, end: 0x000E35B2 }, // CardJyrkiLumme
    { name: 'CardDougLidster.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E35B2, end: 0x000E391C }, // CardDougLidster
    { name: 'CardCliffRonning.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E391C, end: 0x000E3C86 }, // CardCliffRonning
    { name: 'CardDonBeaupre.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E3C86, end: 0x000E3FF0 }, // CardDonBeaupre
    { name: 'CardMikeRidley.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E3FF0, end: 0x000E435A }, // CardMikeRidley
    { name: 'CardDimitriKhristich.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E435A, end: 0x000E46C4 }, // CardDimitriKhristich
    { name: 'CardPeterBondra.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E46C4, end: 0x000E4A2E }, // CardPeterBondra
    { name: 'CardKevinHatcher.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E4A2E, end: 0x000E4D98 }, // CardKevinHatcher
    { name: 'CardAlIafrate.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E4D98, end: 0x000E5102 }, // CardAlIafrate
    { name: 'CardThomasSteen.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E5102, end: 0x000E546C }, // CardThomasSteen
    { name: 'CardTeemuSelanne.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E546C, end: 0x000E57D6 }, // CardTeemuSelanne
    { name: 'CardPhilHousley.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E57D6, end: 0x000E5B40 }, // CardPhilHousley
    { name: 'CardBobEssensa.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E5B40, end: 0x000E5EAA }, // CardBobEssensa
    { name: 'CardTeppoNumminen.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E5EAA, end: 0x000E62C8 }, // CardTeppoNumminen
    { name: 'CardAlexeiZhamnov.bin', folder: 'NHL94/Graphics/PlayerCards', start: 0x000E62C8, end: 0x000E6632 }, // CardAlexeiZhamnov
    { name: 'PlayerCardsScreenPic.bin', folder: 'NHL94/Graphics', start: 0x000E6632, end: 0x000E9A80 }, // PlayerCardsScreenPic
    { name: 'CornerLogoMap.bin', folder: 'NHL94/Graphics', start: 0x000E9A80, end: 0x000E9ED6 }, // unk_E9A80
    { name: 'ArenaGfxBank.bin', folder: 'NHL94/Graphics', start: 0x000E9ED6, end: 0x000F3098 }, // unk_E9ED6
    { name: 'PlayoffSprite.bin', folder: 'NHL94/Graphics', start: 0x000F3098, end: 0x000F5338 }, // unk_F3098
    { name: 'HiScoreImg.bin', folder: 'NHL94/Graphics', start: 0x000F5338, end: 0x000F5AF6 }, // HiScoreImg
    { name: 'HotIconMap.bin', folder: 'NHL94/Graphics', start: 0x000F5AF6, end: 0x000F5D1C }, // unk_F5AF6
    { name: 'ColdIconMap.bin', folder: 'NHL94/Graphics', start: 0x000F5D1C, end: 0x000F600E }, // unk_F5D1C
    { name: 'revframetbl.bin', folder: 'NHL94/Graphics', start: 0x000F600E, end: 0x000F66EE }, // revframetbl
    // NHL 94 matchup / player card palettes, src/cards94.asm TeamPalettes ($F8BF4): two 16 color palettes per team in TeamList order.
    // A is the matchup logo palette (the TeamLogoPalettes entry, except BOS, FLA, HFD, SJ), B is the other side (A with colors 1-2 and 3-4 swapped).
    { name: 'MatchupPalANHA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8BF4, end: 0x000F8C14 }, // ANH matchup logo
    { name: 'MatchupPalANHB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8C14, end: 0x000F8C34 }, // ANH other side
    { name: 'MatchupPalBOSA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8C34, end: 0x000F8C54 }, // BOS matchup logo
    { name: 'MatchupPalBOSB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8C54, end: 0x000F8C74 }, // BOS other side
    { name: 'MatchupPalBUFA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8C74, end: 0x000F8C94 }, // BUF matchup logo
    { name: 'MatchupPalBUFB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8C94, end: 0x000F8CB4 }, // BUF other side
    { name: 'MatchupPalCGYA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8CB4, end: 0x000F8CD4 }, // CGY matchup logo
    { name: 'MatchupPalCGYB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8CD4, end: 0x000F8CF4 }, // CGY other side
    { name: 'MatchupPalCHIA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8CF4, end: 0x000F8D14 }, // CHI matchup logo
    { name: 'MatchupPalCHIB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8D14, end: 0x000F8D34 }, // CHI other side
    { name: 'MatchupPalDALA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8D34, end: 0x000F8D54 }, // DAL matchup logo
    { name: 'MatchupPalDALB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8D54, end: 0x000F8D74 }, // DAL other side
    { name: 'MatchupPalDETA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8D74, end: 0x000F8D94 }, // DET matchup logo
    { name: 'MatchupPalDETB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8D94, end: 0x000F8DB4 }, // DET other side
    { name: 'MatchupPalEDMA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8DB4, end: 0x000F8DD4 }, // EDM matchup logo
    { name: 'MatchupPalEDMB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8DD4, end: 0x000F8DF4 }, // EDM other side
    { name: 'MatchupPalFLAA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8DF4, end: 0x000F8E14 }, // FLA matchup logo
    { name: 'MatchupPalFLAB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8E14, end: 0x000F8E34 }, // FLA other side
    { name: 'MatchupPalHFDA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8E34, end: 0x000F8E54 }, // HFD matchup logo
    { name: 'MatchupPalHFDB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8E54, end: 0x000F8E74 }, // HFD other side
    { name: 'MatchupPalLAA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8E74, end: 0x000F8E94 }, // LA matchup logo
    { name: 'MatchupPalLAB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8E94, end: 0x000F8EB4 }, // LA other side
    { name: 'MatchupPalMTLA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8EB4, end: 0x000F8ED4 }, // MTL matchup logo
    { name: 'MatchupPalMTLB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8ED4, end: 0x000F8EF4 }, // MTL other side
    { name: 'MatchupPalNJA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8EF4, end: 0x000F8F14 }, // NJ matchup logo
    { name: 'MatchupPalNJB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8F14, end: 0x000F8F34 }, // NJ other side
    { name: 'MatchupPalNYIA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8F34, end: 0x000F8F54 }, // NYI matchup logo
    { name: 'MatchupPalNYIB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8F54, end: 0x000F8F74 }, // NYI other side
    { name: 'MatchupPalNYRA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8F74, end: 0x000F8F94 }, // NYR matchup logo
    { name: 'MatchupPalNYRB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8F94, end: 0x000F8FB4 }, // NYR other side
    { name: 'MatchupPalOTWA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8FB4, end: 0x000F8FD4 }, // OTW matchup logo
    { name: 'MatchupPalOTWB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8FD4, end: 0x000F8FF4 }, // OTW other side
    { name: 'MatchupPalPHIA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F8FF4, end: 0x000F9014 }, // PHI matchup logo
    { name: 'MatchupPalPHIB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9014, end: 0x000F9034 }, // PHI other side
    { name: 'MatchupPalPITA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9034, end: 0x000F9054 }, // PIT matchup logo
    { name: 'MatchupPalPITB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9054, end: 0x000F9074 }, // PIT other side
    { name: 'MatchupPalQUEA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9074, end: 0x000F9094 }, // QUE matchup logo
    { name: 'MatchupPalQUEB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9094, end: 0x000F90B4 }, // QUE other side
    { name: 'MatchupPalSJA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F90B4, end: 0x000F90D4 }, // SJ matchup logo
    { name: 'MatchupPalSJB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F90D4, end: 0x000F90F4 }, // SJ other side
    { name: 'MatchupPalSTLA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F90F4, end: 0x000F9114 }, // STL matchup logo
    { name: 'MatchupPalSTLB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9114, end: 0x000F9134 }, // STL other side
    { name: 'MatchupPalTBA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9134, end: 0x000F9154 }, // TB matchup logo
    { name: 'MatchupPalTBB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9154, end: 0x000F9174 }, // TB other side
    { name: 'MatchupPalTORA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9174, end: 0x000F9194 }, // TOR matchup logo
    { name: 'MatchupPalTORB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9194, end: 0x000F91B4 }, // TOR other side
    { name: 'MatchupPalVANA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F91B4, end: 0x000F91D4 }, // VAN matchup logo
    { name: 'MatchupPalVANB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F91D4, end: 0x000F91F4 }, // VAN other side
    { name: 'MatchupPalWSHA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F91F4, end: 0x000F9214 }, // WSH matchup logo
    { name: 'MatchupPalWSHB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9214, end: 0x000F9234 }, // WSH other side
    { name: 'MatchupPalWPGA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9234, end: 0x000F9254 }, // WPG matchup logo
    { name: 'MatchupPalWPGB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9254, end: 0x000F9274 }, // WPG other side
    { name: 'MatchupPalASEA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9274, end: 0x000F9294 }, // ASE matchup logo
    { name: 'MatchupPalASEB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F9294, end: 0x000F92B4 }, // ASE other side
    { name: 'MatchupPalASWA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F92B4, end: 0x000F92D4 }, // ASW matchup logo
    { name: 'MatchupPalASWB.pal', folder: 'NHL94/Graphics/Pals', start: 0x000F92D4, end: 0x000F92F4 }, // ASW other side
    // src/title94.asm TeamLogoPalettes ($FF462): the 4 team logo palettes that differ from MatchupPal<team>A.pal; the other 24 incbin that file.
    { name: 'TeamLogoPalBOS.pal', folder: 'NHL94/Graphics/Pals', start: 0x000FF482, end: 0x000FF4A2 }, // BOS team logo
    { name: 'TeamLogoPalFLA.pal', folder: 'NHL94/Graphics/Pals', start: 0x000FF562, end: 0x000FF582 }, // FLA team logo
    { name: 'TeamLogoPalHFD.pal', folder: 'NHL94/Graphics/Pals', start: 0x000FF582, end: 0x000FF5A2 }, // HFD team logo
    { name: 'TeamLogoPalSJ.pal', folder: 'NHL94/Graphics/Pals', start: 0x000FF6C2, end: 0x000FF6E2 }, // SJ team logo

    // { name: 'Title1.map.jim', folder: 'NHL94/Graphics', start: 0x00025642, end: 0x0002ADF0 },
    // { name: 'Title2.map.jim', folder: 'NHL94/Graphics', start: 0x0002ADF0, end: 0x0002C0FE },
    // { name: 'NHLSpin.map.jim', folder: 'NHL94/Graphics', start: 0x0002C0FE, end: 0x0002E9EC },
    // { name: 'Puck.anim', folder: 'NHL94/Graphics', start: 0x0002E9EC, end: 0x0002F262 },
    // { name: 'Scouting.map.jim', folder: 'NHL94/Graphics', start: 0x0002F262, end: 0x00033590 },
    // { name: 'Framer.map.jim', folder: 'NHL94/Graphics', start: 0x00033590, end: 0x000336B0 },
    // { name: 'FaceOff.map.jim', folder: 'NHL94/Graphics', start: 0x000336B0, end: 0x00033AAE },
    // { name: 'IceRink.map.jim', folder: 'NHL94/Graphics', start: 0x00033AAE, end: 0x0003A3DC },
    // { name: 'Refs.map.jim', folder: 'NHL94/Graphics', start: 0x0003A3DC, end: 0x0003D5EE },
    // { name: 'Sprites.anim', folder: 'NHL94/Graphics', start: 0x0003D5EE, end: 0x0007216C },
    // { name: 'Crowd.anim', folder: 'NHL94/Graphics', start: 0x0007216C, end: 0x00075790 },
    // { name: 'FaceOff.anim', folder: 'NHL94/Graphics', start: 0x00075790, end: 0x0007716C },
    // { name: 'Zam.anim', folder: 'NHL94/Graphics', start: 0x0007716C, end: 0x000778D2 },
    // { name: 'BigFont.map.jim', folder: 'NHL94/Graphics', start: 0x000778D2, end: 0x00078C20 },
    // { name: 'SmallFont.map.jim', folder: 'NHL94/Graphics', start: 0x00078C20, end: 0x00079C2E },
    // { name: 'TeamBlocks.map.jim', folder: 'NHL94/Graphics', start: 0x00079C2E, end: 0x0007E79C },
    // { name: 'Arrows.map.jim', folder: 'NHL94/Graphics', start: 0x0007E79C, end: 0x0007EB12 },
    // { name: 'Stanley.map.jim', folder: 'NHL94/Graphics', start: 0x0007EB12, end: 0x0007FC20 },
    // { name: 'EASN.map.jim', folder: 'NHL94/Graphics', start: 0x0007FC20, end: 0x0007FE8A }
];

// Expected CRC32 of lst/nhl94.bin
const EXPECTED_CRC32 = 0x9438F5DD;

async function verifyCRC32(filePath) {
    try {
        const data = await fs.readFile(filePath);
        const calculatedCRC = crc32.buf(data) >>> 0; // Convert to unsigned 32-bit integer
        console.log('Caclulated CRC32:', calculatedCRC, EXPECTED_CRC32);
        return calculatedCRC === EXPECTED_CRC32;
    } catch (error) {
        console.error(`Error reading ROM file for CRC32 check: ${error.message}`);
        return false;
    }
}

async function extractAssets(romPath, options = {}) {
    // Set default options
    const extractOptions = {
        outputDir: options.outputDir || 'Extracted',
        verbose: options.verbose || false
    };
    
    try {
        // Verify CRC32
        const isValid = await verifyCRC32(romPath);
        if (!isValid) {
            console.error(`CRC32 checksum mismatch. Expected ${EXPECTED_CRC32.toString(16).toUpperCase()}. Aborting extraction.`);
            return;
        }

        // Read the ROM file
        const romData = await fs.readFile(romPath);

        // Create base Extracted directory
        const baseDir = extractOptions.outputDir;
        await fs.mkdir(baseDir, { recursive: true });

        // Extract each asset
        for (const asset of assets) {
            // Create output directory
            const outputDir = path.join(baseDir, asset.folder);
            await fs.mkdir(outputDir, { recursive: true });

            // Extract data
            const assetData = romData.slice(asset.start, asset.end);

            // Write to file
            const outputPath = path.join(outputDir, asset.name);
            await fs.writeFile(outputPath, assetData);
            
            if (extractOptions.verbose) {
                console.log(`Extracted ${asset.name} (${assetData.length} bytes) from offset 0x${asset.start.toString(16)} to 0x${asset.end.toString(16)}`);
                console.log(`Saved to ${outputPath}`);
            } else {
                console.log(`Extracted ${asset.name} to ${outputPath}`);
            }
        }

        console.log('Extraction completed successfully.');
        console.log(`Extracted ${assets.length} assets from NHL 94 ROM.`);
    } catch (error) {
        console.error(`Error during extraction: ${error.message}`);
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        romFile: null,
        outputDir: 'Extracted',
        verbose: false
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        if (arg === '-h' || arg === '--help') {
            displayHelp();
            process.exit(0);
        } else if (arg === '-v' || arg === '--verbose') {
            options.verbose = true;
        } else if (arg === '-o' || arg === '--output') {
            if (i + 1 < args.length) {
                options.outputDir = args[++i];
            } else {
                console.error('Error: Output directory not specified');
                displayHelp();
                process.exit(1);
            }
        } else if (!options.romFile) {
            options.romFile = arg;
        }
    }

    return options;
}

// Display help information
function displayHelp() {
    console.log(`
NHL 92 Asset Extractor
======================

This script extracts assets from NHL Hockey (1991/1992) ROM files.

Usage: node extractAssets92.js [options] <rom_file_path>

Options:
  -h, --help              Display this help message
  -v, --verbose           Display detailed extraction information
  -o, --output <dir>      Specify output directory (default: 'Extracted')

Notes:
  - This script extracts all known assets from the NHL 92 ROM
  - ROM checksums are verified to ensure correct ROM is used

Examples:
  node extractAssets92.js nhl94retail.bin
  node extractAssets92.js --verbose --output NHL94Assets nhl94retail.bin
    `);
}

// Main execution
const options = parseArgs();

if (!options.romFile) {
    console.error('Error: ROM file path not provided');
    displayHelp();
    process.exit(1);
}

console.log(`Extracting assets from: ${options.romFile}`);
console.log(`Output directory: ${options.outputDir}`);
if (options.verbose) {
    console.log('Verbose mode enabled');
}

extractAssets(options.romFile, {
    outputDir: options.outputDir,
    verbose: options.verbose
});