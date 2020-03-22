/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   A.1 = word( arg( 1 ), 1 )     ;  OPT = '? -? /? -h /h'
   OPT = ( A.1 = '' ) | sign( wordpos( A.1, OPT ))

   if OPT   then  exit USAGE()
   if arg() <> 1  then  do       /* 2 .. 5 arguments as function: */
      if arg() > 5   then  exit USAGE( 'extraneous arguments' )

      parse arg A.1 , A,2 , A.3 , A.4 , SRC

      select
         when  SRC <> ''   then  nop
         when  A.4 <> ''   then  parse value A.2 A.4 with A.4 SRC
         when  A.3 <> ''
         then  parse value A.1 A.2 A.3       with A.3 A.4 SRC
         when  A.2 <> ''
         then  parse value A.1 A.1 A.1 A.2   with A.2 A.3 A.4 SRC
         otherwise         exit USAGE( 'missing arguments' )
      end
   end
   else  do
      parse arg SRC              ;  A. = ''
      do N = 1 to 4
         A.N = word( SRC, 1 )    ;  C = left( A.N, 1 )
         C = substr( A.N, 1 + sign( pos( C, '+-=' )))
         if \ datatype( C, 'w' ) then  do
            A.N = ''
            if A.2 = '' then  A.2 = A.1
            if A.3 = '' then  A.3 = A.1
            if A.4 = '' then  A.4 = A.2
            leave N
         end

         SRC = subword( SRC, 2 )
      end N
      if SRC = '' then  exit USAGE( 'missing arguments' )
   end

   M. = 1
   do N = 1 to 4
      C.N = strip( A.N )         ;  E.N = abbrev( C.N, '=' )
      if E.N   then  C.N = substr( C.N, 2 )
      if \ datatype( C.N, 'w' )  then  exit USAGE( A.N )
      if C.N < 0  then  select
         when  E.N      then  exit USAGE( A.N )
         when  N // 2   then  M.2 = M.2 + abs( C.N )
         otherwise            M.1 = M.1 + abs( C.N )
      end
   end N

   OPT = '-v warning'            ;  EOL = x2c( 0A )
   if right(  SRC, 1 ) = '?'  then  do
      SRC = reverse( substr( reverse( SRC ), 2 ))
      OPT = '-strict experimental -v verbose'
   end                           /* trailing ? for verbose ffmpeg */
   TRY = stream( strip( SRC,, '"' ), 'c', 'query exists' )
   if TRY = ''       then  exit USAGE( 'found no' SRC )
   SRC = TRY                     ;  TRY = lastpos( '.', SRC )
   if TRY = 0        then  exit USAGE( 'unsupported' SRC )
   EXT = translate( substr( SRC, TRY ))
   DST = left( SRC, TRY ) || 'pam'
   TRY = stream( DST, 'c', 'query exists' )
   if TRY <> ''      then  exit USAGE( DST 'already exists' )
   TRY = '.BMP .GIF .SGI .TGA'   /* some formats known by ffmpeg  */
   TRY = TRY '.JPEG .JPG .J2K .JLS .JP2 .DPX .PCX .WEBP .ALIAS'
   TRY = TRY '.TIFF .TIF .PAM .PBM .PGM .PPM .PNG .PGMYUV .XBM'
   TRY = wordpos( EXT, TRY )     /* allow only well-known formats */
   if TRY = 0        then  exit USAGE( 'unsupported' SRC )

   TRY = FFMPIX( SRC, OPT, '-pix_fmt rgba' )
   if TRY <> ''      then  exit ERROR( TRY )
   say right( R.0, 9 ) 'bytes,' R.5 'in' R.3 * R.8 * 8 'bits'
   if R.1 < M.1      then  exit ERROR( 'width'  R.1 '<=' M.1 )
   if R.2 < M.2      then  exit ERROR( 'height' R.2 '<=' M.2 )

   PIL = R.3 * R.8               ;  ROL = R.1 * PIL
   LEN = R.0                     ;  OFS = 0
   ADD = copies( x2c( 0 ), ROL ) ;  OUT = ''
   if E.1         then  ADD = substr( R.., OFS + 1, ROL )
   if C.1 > 0     then  OUT = OUT || copies( ADD, C.1 )
   if C.1 < 0     then  OFS = ROL * abs( C.1 )
   if C.3 < 0     then  LEN = LEN - OFS - ROL * abs( C.3 )
                  else  LEN = LEN - OFS
   OUT = OUT || substr( R.., OFS + 1, LEN )
   LEN = length( OUT )           ;  OFS = LEN - ROL
   ADD = copies( x2c( 0 ), ROL )
   if E.3         then  ADD = substr( OUT, OFS + 1, ROL )
   if C.3 > 0     then  OUT = OUT || copies( ADD, C.3 )

   R.. = OUT                     ;  OUT = ''
   R.2 = R.2 + C.1 + C.3         /* adjust number of output rows  */
   R.1 = R.1 + C.2 + C.4         /* adjust number of output cols  */
   FOO = 1 + R.2 % 50            /* progress BAR: 10+8+50+11=79 ***/
   BAR = right( R.1 * R.2, 9 ) 'pixels .'                      /***/
   do N = 0 to R.2 - 1           /* crop first + last columns     */
      ROW = substr( R.., N * ROL + 1, ROL )
      ADD = copies( x2c( 0 ), PIL )
      if E.2      then  ADD = left( ROW, PIL )
      if C.2 > 0  then  ROW = copies( ADD, C.2 ) || ROW
      if C.2 < 0  then  ROW = substr( ROW, 1 + PIL * abs( C.2 ))
      ADD = copies( x2c( 0 ), PIL )
      if E.4      then  ADD = right( ROW, PIL )
      if C.4 > 0  then  ROW = ROW || copies( ADD, C.4 )
      if C.4 < 0  then  ROW = left( ROW, R.1 * PIL )
      OUT = OUT || ROW
      if N // FOO = 0      then  BAR = BAR || '.'              /***/
      call charout /**/, BAR left( N * R.1, 9 ) || x2c( 0D )   /***/
   end
   say BAR left( N * R.1, 9 )    /* terminate progress BAR line ***/
   R.0 = length( OUT )           /* check expected bitmap length: */
   if R.1 * R.2 * R.3 * R.8 <> R.0  then  do
      exit ERROR( R.1 '*' R.2 '*' R.3 '*' R.8 '<>' R.0 )
   end

   HDR = 'P7' || EOL || 'WIDTH' R.1 || EOL || 'HEIGHT' R.2
   HDR =  HDR || EOL || 'DEPTH' R.3 || EOL || 'MAXVAL' R.4
   HDR =  HDR || EOL || 'TUPLTYPE' R.5
   HDR =  HDR || EOL || 'ENDHDR'    || EOL
   call charout DST, HDR || OUT  ;  call lineout DST
   say 'created' DST             ;  return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'TOP [RIGHT [BOTTOM [LEFT]]] IMAGE'
   say                           /* suited for REXXC tokenization */
   say ' The input IMAGE can be in any format supported by FFmpeg, '
   say ' with a known file extension supported in this script excl.'
   say ' PAM used as output format (pixel format RGBA in 32 bits). '
   say
   say ' A given number of pixels will be removed or added at the  '
   say ' TOP, RIGHT, BOTTOM, and LEFT.  Following CSS conventions  '
   say ' TOP is the default for RIGHT and BOTTOM, and RIGHT is the '
   say ' default for LEFT.  To keep a side as is use 0.  To remove '
   say ' pixels on a side use n < 0.  To add transparent pixels use'
   say ' n > 0.  To add copied pixels use =n (equalsign + integer).'
   say ' CAVEAT: Metadata, e.g., EXIF, is NOT copied to the output.'
   return 1                      /* exit code 1, nothing happened */

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
