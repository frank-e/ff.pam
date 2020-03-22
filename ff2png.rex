/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */
/* Classic REXX:  Let ffmpeg decode an image, convert it to PNG   */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   SRC = strip( arg( 1 ))        ;  OPT = '-v warning'
   TRY = sign( wordpos( SRC, '-? /? /h -h ?' ))
   if TRY | SRC = '' then  exit USAGE()
   if SRC = '*'      then  exit TRYIT( OPT )
   if right(  SRC, 1 ) = '?'  then  do
      SRC = reverse( substr( reverse( SRC ), 2 ))
      OPT = '-strict experimental -v verbose'
   end                           /* trailing ? for verbose ffmpeg */
   TRY = stream( strip( SRC,, '"' ), 'c', 'query exists' )
   if TRY = ''       then  exit USAGE( 'found no' SRC )
   SRC = TRY                     ;  TRY = lastpos( '.', SRC )
   if TRY = 0        then  exit USAGE( 'unsupported' SRC )
   EXT = translate( substr( SRC, TRY ))
   DST = left( SRC, TRY ) || 'png'
   TRY = stream( DST, 'c', 'query exists' )
   if TRY <> ''      then  exit USAGE( DST 'already exists' )
   TRY = '.BMP .GIF .SGI .TGA'   /* some formats known by ffmpeg  */
   TRY = TRY '.JPEG .JPG .J2K .JLS .JP2 .DPX .PCX .WEBP .ALIAS'
   TRY = TRY '.TIFF .TIF .PAM .PBM .PGM .PPM .PNG .PGMYUV .XBM'
   TRY = wordpos( EXT, TRY )     /* allow only well-known formats */
   if TRY = 0        then  exit USAGE( 'unsupported' SRC )
   return MAKEPNG( SRC, DST, OPT )

MAKEPNG: procedure               /* continue, called by TRYIT()   */
   parse arg SRC, PNG, OPT       ;  TRY = FFMPIX( SRC, OPT )
   if TRY <> ''      then  exit ERROR( TRY )
   say right( R.0, 9 ) 'bytes,' R.5 'in' R.3 * R.8 * 8 'bits'
   if R.8 = 2  then  OUT = 'gray16be ya16be rgba48be rgba64be'
               else  OUT = 'gray     ya8    rgb24    rgba    '
   if R.4 = 1  then  OUT = 'monob    ya8    rgb24    rgba    '
   OUT = '-pix_fmt' word( OUT, R.3 ) '-frames 1'

   TRY = 'ffmpeg -hide_banner' OPT
   OPT = '-sws_flags bitexact+accurate_rnd+full_chroma_int+spline'
   TRY = TRY '-f image2       -i "' || SRC || '"' OPT OUT
   TRY = TRY '-f image2 -c:v png "' || PNG || '"'
   TRY                           /* SIGNAL ON ERROR catches error */

   ZAP = 'cHRM gAMA iCCP sRGB'   ;  LIN = PNGSRGB( 2 )
   OFF = -1                      ;  CNT = chars( PNG )
   do while 12 <= CNT            /* zap bogus pHYs + saved chunks */
      CHK = charin( PNG,, 8 )    ;  CNT = CNT - 8
      if OFF < 0  then  do
         OFF = 0                 ;  OUT = CHK
         if CHK == x2c( 89504E47 0D0A1A0A )     then  iterate
                                                else  leave
      end
      OFF = left(  CHK, 4 )      ;  OFF = c2d( OFF ) + 4
      CNT = CNT - OFF            ;  if CNT < 0  then  leave
      HDR = right( CHK, 4 )      ;  CHK = CHK || charin( PNG,, OFF )
      if CNT = 0  then  CNT = ( HDR == 'IEND' ) - 1
      select                     /* destroy odd ffmpeg pHYs (0*1) */
         when  datatype( HDR, 'M' ) = 0         then  leave
         when  sign( wordpos(  HDR, ZAP ))      then  nop
         when  HDR == 'pHYs'                    then  nop
         when  HDR == 'PLTE' | HDR == 'IDAT'    then  do
            CHK = LIN || CHK     ;  LIN = ''
            OUT = OUT || CHK     /* added sRGB before PLTE + IDAT */
         end
         otherwise                  OUT = OUT || CHK
      end
   end
   call lineout PNG
   if CNT <> 0       then  exit ERROR( 'cannot parse fixed' PNG )
   call SysFileDelete PNG        ;  call charout PNG, OUT
   say '  created' PNG           ;  call lineout PNG
   return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '[image|*]'
   say                           /* suited for REXXC tokenization */
   say ' Let ffmpeg convert a given image to PNG.                  '
   say ' FIXME:  Copy meta-data with exiftool.exe.                 '
   say ' Argument "*" starts a self test with a small (134 bytes)  '
   say ' lossless WebP.                                            '
   return 1

/* -------------------------------------------------------------- */

TRYIT:   procedure               /* ffmpeg rgbtestsrc as a WEBP   */
   /* length 134 = 8 + 126             126 = 12 + 114             */
   /* header  R I F F  126      W E B P  V P 8 L  114             */
   TRY =     '52494646 7E000000 57454250 5650384C 72000000' /* 20 */
   TRY = TRY '2F3FC13B 0009A269 1BA8EDFF 4F576D2E A2FFC91D' /* 40 */
   TRY = TRY '66CC6CC6 CC0B3169 D2BFE52A 89CF8047 FF931C72' /* 60 */
   TRY = TRY '0718B46D 2429C31F F4DE1D82 FF2C2028 F27FB409' /* 80 */
   TRY = TRY '88558828 8733F7C2 FFFCCFFF FCCFFFFC EF06361B' /*100 */
   TRY = TRY 'C731C6F3 F6C2FFFC CFFFFCCF FFFCEF06 B6C8CCC8' /*120 */
   TRY = TRY 'F3F6C2FF FCCFFFFC CFFFFCEF F605'              /*134 */
   SRC = qualify( './deleteme.webp' )
   PNG = qualify( './deleteme.png' )
   call lineout PNG              ;  call SysFileDelete PNG
   call lineout SRC              ;  call SysFileDelete SRC
   call charout SRC, x2c( TRY )  ;  call lineout SRC

   TRY = MAKEPNG( SRC, PNG, arg( 1 ))
   say 'for input' SRC           ;  return 0

/* -------------------------------------------------------------- */

PNGSRGB: procedure expose sigl   /* sRGB chunk size big endian 1: */
   parse arg N                   ;  S = d2c( 1, 4 ) || 'sRGB'
   if N = 0 then  return S || x2c( 00AECE1CE9 )    /* perceptive  */
   if N = 1 then  return S || x2c( 01D9C92C7F )    /* relative    */
   if N = 2 then  return S || x2c( 0240C07DC5 )    /* saturation  */
   if N = 3 then  return S || x2c( 0337C74D53 )    /* absolute    */
   exit ERROR( 'PNGSRGB() error near line' sigl )

/* ----------------------------- (REXX FFmpeg to PAM, 2016-01-05) */
/* R.. is a global pixmap.                                        */
/* R.0 is a checked length( R.. ) = WIDTH * HEIGHT * DEPTH * R.8  */
/* R.1 is the WIDTH, R.2 is the HEIGHT                            */
/* R.3 is DEPTH 1..4 with 3: TUPLTYPE RGB, 4: TUPLTYPE RGB_ALPHA. */
/* R.4 is MAXVAL 1..65535 (but ffmpeg creates only 255 or 65535). */
/* R.5 is a TUPLTYPE matching the DEPTH.                          */
/* R.8 is 1 + ( MAXVAL > 255 ) for 8 vs. 16 bits components.      */
/* R.9 contains any header comment lines (leading '#' stripped).  */
/* SRC is the absolute path of the image processed by ffmpeg.     */
/* OPI can be ffmpeg input or global options, e.g., "-v warning". */
/* OPA can be ffmpeg PAM output options, e.g., "-pix_fmt rgba".   */
/* PAM is a TEMP file with "long name" of source + suffix ".tmp". */

FFMPIX:  procedure expose R.
   signal on error    name ERROR ;  parse arg SRC, OPI, OPA
   signal on notready name ERROR

   PAM = translate( SRC, '/', '\' )
   PAM = substr( SRC, 1 + lastpos( '/', PAM ))
   TRY = value( 'TMP',, 'ENVIRONMENT' )
   if TRY = '' then  TRY = value( 'TEMP',, 'ENVIRONMENT' )
   if TRY = '' then  TRY = qualify( '.' )
   PAM = qualify( TRY || '/' || PAM || '.tmp' )
   TRY = '-sws_flags bitexact+accurate_rnd+full_chroma_int+spline'
   OPA = TRY OPA                 /* CAVEAT: no +full_chroma_inp   */
   TRY = 'ffmpeg -hide_banner'   OPI   '-i "' || SRC || '"' OPA
   TRY = TRY '-f image2 -frames 1 -c:v pam "' || PAM || '"'
   TRY                           /* SIGNAL ON ERROR catches error */

   VAL = chars( PAM )            ;  EOL = x2c( 0A )
   R.  = EOL                     ;  R.. = charin( PAM, 1, VAL )
   call lineout PAM              ;  call SysFileDelete PAM
   TOP = 1                       ;  HDR = pos( EOL, R.., TOP )
   do while TOP <= HDR           /* parse PAM header as specified */
      TRY = substr( R.., TOP, HDR - TOP )
      TOP = HDR + 1              ;  HDR = pos( EOL, R.., TOP )

      if abbrev( TRY, '#' ) = 0  then  do
         TRY = translate( TRY, x2c( 20202020 ), x2c( 090B0C0D ))
         parse var TRY DEF VAL   ;  VAL = strip( VAL )
      end                        /* strip WSP before or after VAL */
      else  parse var TRY DEF =2 VAL
      select      /* <http://netpbm.sourceforge.net/doc/pam.html> */
         when  TRY == 'P7'       &  R.0 == EOL  then  R.0 = 1
         when                       R.0 == EOL  then  HDR = 0
         when  TRY == 'ENDHDR'                  then  HDR = 1
         when  DEF == 'WIDTH'    &  R.1 == EOL  then  R.1 = VAL
         when  DEF == 'HEIGHT'   &  R.2 == EOL  then  R.2 = VAL
         when  DEF == 'DEPTH'    &  R.3 == EOL  then  R.3 = VAL
         when  DEF == 'MAXVAL'   &  R.4 == EOL  then  R.4 = VAL
         when  DEF == 'TUPLTYPE' &  R.5 == EOL  then  R.5 = VAL
         when  DEF == 'TUPLTYPE'                then  R.5 = R.5 VAL
         when  DEF == '#'        then  R.9 = R.9 || VAL || EOL
         when  DEF == ''         then  nop
         otherwise   R.0 = TRY   ;                    HDR = 0
      end                        /* FWIW: collect comments in R.9 */
   end                           /* ----------------------------- */

   HDR = ( R.0 = 1 & HDR = 1 )   /* found good P7 and good ENDHDR */
   do N = 1 to 4 while HDR       /* unsigned non-zero integer is  */
      if datatype( R.N, 'w' )    /* "decimal number" in PAM spec. */
         then  HDR = ( 0 < R.N ) & ( R.N + 0 == R.N )
         else  HDR = 0           /* FIXME: leading zeros are okay */
   end N                         /* PAM spec. only limits MAXVAL: */
   if   HDR then  HDR = ( R.4 < 65536 )
   if \ HDR then  do
      TRY = translate( R.1 R.2 R.3 R.4 R.0, '?', EOL )
      return 'FFMPIX' TRY        /* invalid header (?: undefined) */
   end
   R.. = substr( R.., TOP )      ;  R.0 = length( R.. )
   R.8 = 1 + ( 255 < R.4 )       /* 255 < MAXVAL requires 2 bytes */
   if R.0 <> R.1 * R.2 * R.3 * R.8  then  do
      return 'FFMPIX' R.0 '<>' R.1 '*' R.2 '*' R.3 '*' R.8
   end                           /* N.B.: spec. permits multi-PAM */
   if R.4 < 255   then  do       /* 255 < MAXVAL not yet checked: */
      TRY = verify( R.., xrange( d2c( 0 ), d2c( R.4 )))
      if TRY > 0  then  return 'FFMPIX MAXVAL' R.4 'violation'
   end                           /* ----------------------------- */
   select                        /* ignore TUPLTYPE for DEPTH > 4 */
      when  R.3 > 4     then  return 'FFMPIX DEPTH > 4 unsupported'
      when  R.3 > 2     then  do /* R.3 > 2 is RGB or RGB_ALPHA   */
         VAL = word( 'RGB RGB_ALPHA', R.3 - 2 )
         if R.5 == EOL  then  R.5 = VAL
         if R.5 == VAL  then  return ''
      end                        /* empty result string: no error */
      when  R.3 = 2     then  do /* ----------------------------- */
         VAL = 'GRAYSCALE_ALPHA' ;  DEF = 'BLACKANDWHITE_ALPHA'
         if R.5 == EOL  then  R.5 = word( VAL DEF, 1 + ( R.4 = 1 ))
         if R.5 == VAL | ( R.5 == DEF & R.4 = 1 )  then  return ''
      end                        /* DEPTH 2 has an ALPHA TUPLTYPE */
      when  R.3 = 1     then  do /* ----------------------------- */
         VAL = 'GRAYSCALE'       ;  DEF = 'BLACKANDWHITE'
         if R.5 == EOL  then  R.5 = word( VAL DEF, 1 + ( R.4 = 1 ))
         if R.5 == VAL | ( R.5 == DEF & R.4 = 1 )  then  return ''
      end                        /* DEPTH 1 has no ALPHA channel  */
   end                           /* ----------------------------- */
   return 'FFMPIX TUPLTYPE' R.5 'expecting' VAL

/* ----------------------------- (Regina SysLoadFuncs 2015-12-06) */

REGUTIL: procedure               /* Not needed for ooRexx > 6.03  */
   if RxFuncQuery( 'SysLoadFuncs' ) then  do
      ERR = RxFuncAdd( 'SysLoadFuncs', 'RexxUtil' )
      if ERR <> 0 then  exit ERROR( 'RexxUtil load error' ERR )
   end                           /* static Regina has no RexxUtil */
   ERR = SysLoadFuncs()          ;  return SysUtilVersion()

/* ----------------------------- (STDERR: unification 2020-03-14) */
/* PERROR() emulates lineout( 'STDERR:', emsg ) with ERROUT().    */
/* ERROUT() emulates charout( 'STDERR:', emsg ).                  */

/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR() uses ERROR. in the context of its caller and returns 1 */
/* for explicit calls or CALL ON conditions.  For a SIGNAL ON ... */
/* condition ERROR() ends with exit 1.                            */

PERROR:  return sign( ERROUT( arg( 1 ) || x2c( 0D0A )))
ERROUT:  procedure
   parse version S V .           ;  signal off notready
   select
      when  6 <= V & V < 7 then  S = 'STDERR:'        /* (o)oRexx */
      when  S == 'REXXSAA' then  S = 'STDERR:'        /* IBM Rexx */
      when  V == 5.00      then  S = '<STDERR>'       /* Regina   */
      otherwise                  S = '/dev/con'       /* Quercus  */
   end                           /* Kedit KEXX 5.xy not supported */
   return charout( S, arg( 1 ))

ERROR:                           /* trace off, save result + sigl */
   ERROR.3 = trace( 'o' )        ;  ERROR.1 = value( 'result' )
   ERROR.2 = sigl                ;  call PERROR
   ERROR.3 = right( ERROR.2 '*-*', 10 )
   if ERROR.2 <= sourceline()
      then  call PERROR ERROR.3 strip( sourceline( ERROR.2 ))
      else  call PERROR ERROR.3 '(source line unavailable)'

   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   call PERROR ERROR.3
   select
      when  sign( wordpos( condition( 'c' ), 'ERROR FAILURE' ))
      then  ERROR.3 = 'RC' rc
      when  condition( 'c' ) = 'SYNTAX'
      then  ERROR.3 = errortext( rc )
      when  condition( 'c' ) = 'HALT'
      then  ERROR.3 = errortext( 4 )
      when  condition( 'c' ) = 'NOTREADY' then  do
         ERROR.3 = condition( 'd' )
         if ERROR.3 <> ''  then  do
            ERROR.3 = stream( ERROR.3, 'd' )
         end
      end
      otherwise   ERROR.3 = ''
   end
   if ERROR.3 <> ''  then  call PERROR right( '>>>', 10 ) ERROR.3
   parse value ERROR.2 ERROR.1 with sigl result
   if ERROR.1 == 'RESULT'  then  drop result
   trace ?L                      /* -- interactive label trace -- */
ERROR:   if condition() = 'SIGNAL'  then  exit 1
                                    else  return 1
