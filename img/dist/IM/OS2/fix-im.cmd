/*
 * fix-im.cmd  by fuji
 *
 * !!!!!  THE LINE BREAK CODE MUST BE "CR+LF" (0x0Dh + 0x0Ah).  !!!!!
 *
 * Created: 970908
 * Revised: 980907
 */

  ARG type .
  
  PARSE SOURCE . . this

  IF type ==''| ( type<>'REXX' & type <>'EXTPROC' ) THEN DO
     SAY 'Please specify fix type.'
     SAY '[usage]' FileSpec('Name', this) 'TYPE'
     SAY '	TYPE: "REXX" or "ExtProc".'
     EXIT 999
  END

  IF RxFuncQuery('SysLoadFuncs') THEN DO
     CALL RxFuncAdd "SysLoadFuncs","REXXUTIL","SysLoadFuncs"
     CALL SysLoadFuncs
  END
  CALL Time('R')
  EOL='0a'x
  template='OS2\im.cmd'

  SAY 'fix type:' type

  CALL SysFileTree 'im*.cmd','dum.','FO','*****','-----'	/* chmod im*.cmd */
  CALL SysFileTree 'im*.','f.','FO'				/* IM scripts */
  DO i=1 TO f.0
     cmdfile=f.i'.cmd'
     rb=SysFileDelete(cmdfile)
     SAY 'creating' FileSpec('Name',cmdfile) || '..'
     func = 'CALL' type || '("' || f.i || '")'
     INTERPRET func
  END
  SAY Time('E')
EXIT


EXTPROC: PROCEDURE EXPOSE cmdfile EOL
PARSE ARG src
   head=LineIn(src)
   PARSE VAR head '#' '!' prog opt
   IF Pos('PERL',Translate(prog)) <>0 THEN opt = '-Sx' opt
   CALL CharOut cmdfile, 'extproc' prog opt ||EOL
   CALL CharOut cmdfile, head ||EOL
   DO WHILE Lines(src)
      line=LineIn(src)
      IF Pos('###DELETE-ON-INSTALL###', line) ==0	/* not WordPos() */
      THEN CALL CharOut cmdfile, line ||EOL
   END
   CALL CharOut cmdfile		/* close handle */
RETURN

REXX: PROCEDURE EXPOSE template cmdfile
   '@copy' template cmdfile '>nul 2>&1'
   IF rc<>0  THEN CALL LineOut STDERR,,
   'FILE ERROR:' template 'NOT found, or' FileSpec('N',cmdfile) 'has been opened by another process EXCLUSIVELY.'
RETURN

/* End of procedure */
