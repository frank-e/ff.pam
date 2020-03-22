/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */
/*    Count RGBA colours in an image, various dubious algorihms.  */

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
   TRY = '.BMP .GIF .SGI .TGA'   /* some formats known by ffmpeg  */
   TRY = TRY '.JPEG .JPG .J2K .JLS .JP2 .DPX .PCX .WEBP .ALIAS'
   TRY = TRY '.TIFF .TIF .PAM .PBM .PGM .PPM .PNG .PGMYUV .XBM'
   TRY = wordpos( EXT, TRY )     /* allow only well-known formats */
   if TRY = 0        then  exit USAGE( 'unsupported' SRC )

   TRY = FFMPIX( SRC, OPT )
   if TRY <> ''      then  exit ERROR( TRY )
   say right( R.0, 9 ) 'bytes,' R.5 'in' R.3 * R.8 * 8 'bits'
   TMP = TMPFILE( SRC )
   call lineout TMP              ;  call SysFileDelete TMP
   call charout TMP, R..         ;  drop R..

   if R.3 = 1 & R.4 = 1 then  do /* R.3 = 2 is ya GRAYSCALE_ALPHA */
      TRY = '.PNG .PAM .BMP .PCX .PBM .XBM .XWD'
      TRY = wordpos( EXT, TRY )
      select                     /* R.5 hack for best guess mono? */
         when  TRY > 4  then  R.5 = R.5 'monow'
         when  TRY > 0  then  R.5 = R.5 'monob'
      otherwise                  /* shown in SUMMARY() image info */
         exit USAGE( 'unknown' EXT 'pixel format for' R.5 )
      end
   end
   select
      when  R.3 < 3 & R.8 = 1       then  return KWIKCNT( TMP )
      when  R.3 < 3 | R.8 = 1       then  return MINICNT( TMP )
      when  R.0 < 3 * ( 2 ** 22 )   then  return SLOWCNT( TMP, 1 )
      otherwise                           return PARKJOY( TMP )
   end                           /* PARKJOY(): 64 passes huge RGB */

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
   call lineout SRC              ;  call SysFileDelete SRC
   call charout SRC, x2c( TRY )  ;  call lineout SRC
   say 'RGBA tests for' SRC      ;  OPT = arg( 1 )
   if TRYIT.1( SRC, OPT, 0 )  then  return 1    /* 1: test failed */

   /*           P N G  crlf  lf       13 I H D R   width 4        */
   TRY =     '89504E47 0D0A1A0A 0000000D 49484452 00000004' /* 20 */
   TRY = TRY '00000003 08060000 00B4F4AE C6000000 19494441' /* 40 */
   TRY = TRY '54780163 FCCFC0C0 0023FEFF 87B01BD0 05FE230B' /* 60 */
   TRY = TRY '000092C3 107ADC71 8FCF0000 00004945 4E44AE42' /* 80 */
   TRY = TRY '6082'                                         /* 82 */
   SRC = qualify( './deleteme.png' )
   call lineout SRC              ;  call SysFileDelete SRC
   call charout SRC, x2c( TRY )  ;  call lineout SRC
   say 'Dirty tests for' SRC
   if TRYIT.1( SRC, OPT, 0 )  then  return 1    /* 1: test failed */

   /*         P 7   W  I D T H    4   H  E I G H  T   2           */
   TRY =     '50370A57 49445448 20340A48 45494748 5420320A' /* 20 */
   TRY = TRY '44455054 4820320A 4D415856 414C2031 0A545550' /* 40 */
   TRY = TRY '4C545950 4520424C 41434B41 4E445748 4954455F' /* 60 */
   TRY = TRY '414C5048 410A454E 44484452 0A000000 01010001' /* 80 */
   TRY = TRY '01010100 01010000 00'                         /* 89 */
   SRC = qualify( './deleteme.pam' )
   call lineout SRC              ;  call SysFileDelete SRC
   call charout SRC, x2c( TRY )  ;  call lineout SRC
   say 'Grey tests for' SRC
   if TRYIT.1( SRC, OPT, 1 )  then  return 1    /* 1: test failed */
   return 0                                     /* 0: test passed */

TRYIT.1: procedure
   parse arg SRC, OPT, FLG       ;  TMP = TMPFILE( SRC )
   do N = 1 to 5 until TRY <> ''
      TRY = FFMPIX( SRC, OPT )
      if TRY <> ''      then  exit ERROR( TRY )
      say right( R.0, 9 ) 'bytes,' R.5 'in' R.3 * R.8 * 8 'bits'
      call lineout TMP           ;  call SysFileDelete TMP
      call charout TMP, R..      ;  drop R..
      if N < 5 then  X = 1       ;  else  X = 3

      TIM = time( 'r' )
      select
         when  N = 1 then  TRY = KWIKCNT( TMP )
         when  N = 2 then  TRY = PARKJOY( TMP )
         when  N > 3 then  TRY = SLOWCNT( TMP, X )
         when  \ FLG then  TRY = MINICNT( TMP )
         otherwise   TRY = lineout( TMP ) + SysFileDelete( TMP )
      end
      TIM = time( 'e' ) + 0
      if TRY <> 0 then  exit ERROR( 'self test case' N 'failed' )

      select
         when  N = 1 then  TRY = 'KWIKCNT (press ENTER to continue)'
         when  N = 2 then  TRY = 'PARKJOY (press ENTER to continue)'
         when  N > 3 then  TRY = 'SLOWCNT (L.0 =' X || ')'
         when  \ FLG then  TRY = 'MINICNT (press ENTER to continue)'
         otherwise         TRY = 'MINICNT skipped for 8 bits (ya8)'
      end
      say 'Test' N 'of 5:' TRY TIM || 'sec'
      pull TRY                   /* will exit for non-empty input */
   end N
   call SysFileDelete SRC        ;  return TRY <> ''

/* -------------------------------------------------------------- */
/* Tackle the 8294400 pixels with 8294161 colours in frame 15722  */
/* of the "Parkjoy" scene in 64 iterations.  On a 64bit box with  */
/* 4 GB RAM SLOWCNT() runs out of free memory (ooRexx) or is just */
/* too slow (Regina).  JFTR, MD5=17826f21b98bda1ce5f0069f57db1d9d */

PARKJOY: procedure expose R.
   parse arg TMP                 ;  PIL = R.3 * R.8
   DEP = R.3 - 1                 ;  RO2 = min( R.1, R.2 )
   RO1 = max( R.1, R.2 )         ;  ROL = RO1 * PIL
   ODD = 1 - R.3 // 2            /* 0: no alpha, 1: transparency  */
   OPA = d2c( R.4 )              /* opaque (MAXVAL)               */
   NIX = d2c(  0, R.8 )          /* 0x00 or 0x0000 for full alpha */
   TOP = PIL - ODD * R.8         /* length of pixel without alpha */

   BAR = right( RO1 * RO2, 9 ) 'pixels'                        /***/
   UNO = 1                       /* detect mono (all 0 or MAXVAL) */
   TOT = 0                       /* count RGB   (or grey) colours */
   GRY = 0                       /* count R=G=B (or grey) colours */
   BAD = 0                       /* count RGB0  (or y0)    pixels */
   OTH = 0                       /* count semi-transparent pixels */
   BLK = 0                       /* count fixed black only once   */
   do N = 0 to 255
      SIX = d2c( N )             /* use six most significant bits */
      U.SIX = left( x2b( c2x( SIX )), 6 )
   end N                         /* ----------------------------- */
   do Z = 0 to 63                /* count in 64 = 2**6 iterations */
      X = right( x2b( d2x( Z, 2 )), 6 )
      if Z = 1 then  do          /* store "black counted" state   */
         PIX = d2c( 0, TOP )     ;  BLK = value( 'S.PIX' ) \== ''
      end
      S. = ''                    /* reset "colour counted" states */
      do N = 0 to RO2 - 1
         ROW = charin( TMP, N * ROL + 1, ROL )
         do L = 0 to RO1 - 1
            PIX = substr( ROW, L * PIL + 1, PIL )
            SIX = left( PIX, 1 ) ;  if U.SIX \== X then  iterate L
            do D = 0 to DEP
               C.D = substr( PIX, D * R.8 + 1, R.8 )
               if UNO   then  UNO = ( C.D == NIX | C.D == OPA )
            end D

            if ODD   then  do
               PIX = left( PIX, TOP )
               if C.DEP == NIX   then  do
                  C.    =  NIX   ;  BAD = BAD + 1
                  if BLK   then  iterate L
                  BLK = 1        ;  PIX   = copies( NIX, R.3 - ODD )
               end               /* normalize full transparency   */
               else  OTH = OTH + ( C.DEP \== OPA )
            end
            if value( 'S.PIX' ) == ''  then  do
               drop S.PIX        ;  TOT = TOT + 1
               if R.3 > 2
                  then  GRY = GRY + ( C.0 == C.1 & C.1 == C.2 )
                  else  GRY = GRY + 1
            end
         end L
         FOO = '(pass' Z 'of 63, row' N || ')'                 /***/
         call charout /**/, BAR FOO right( x2c( 0D ), 9 )      /***/
      end N
   end Z
   say BAR left( '', 50 )        /* terminate progress BAR line ***/
   return SUMMARY( TMP, TOT, GRY, BAD, OTH, UNO )

/* -------------------------------------------------------------- */
/* Straight forward, each found colour gets a 1 byte, the default */
/* is 0 (unknown colour), and REXX memory management has serious  */
/* problems for too many colours.                                 */

KWIKCNT: procedure expose R.
   parse arg TMP                 ;  PIL = R.3 * R.8
   DEP = R.3 - 1                 ;  RO2 = min( R.1, R.2 )
   RO1 = max( R.1, R.2 )         ;  ROL = RO1 * PIL
   ODD = 1 - R.3 // 2            /* 0: no alpha, 1: transparency  */
   OPA = d2c( R.4 )              /* opaque (MAXVAL)               */
   NIX = d2c(  0, R.8 )          /* 0x00 or 0x0000 for full alpha */
   TOP = PIL - ODD * R.8         /* length of pixel without alpha */

   FOO = 1 + RO2 % 50            /* progress BAR: 9+9+50+11=79  ***/
   BAR = right( RO1 * RO2, 9 ) 'pixels .'                      /***/

   UNO = 1                       /* detect mono (all 0 or MAXVAL) */
   TOT = 0                       /* count RGB   (or grey) colours */
   GRY = 0                       /* count R=G=B (or grey) colours */
   BAD = 0                       /* count RGB0  (or y0)    pixels */
   OTH = 0                       /* count semi-transparent pixels */
   S.  = 0
   do N = 0 to RO2 - 1
      ROW = charin( TMP, N * ROL + 1, ROL )
      do L = 0 to RO1 - 1
         PIX = substr( ROW, L * PIL + 1, PIL )
         do D = 0 to DEP
            C.D = substr( PIX, D * R.8 + 1, R.8 )
            if UNO   then  UNO = ( C.D == NIX | C.D == OPA )
         end D
         if ODD   then  do
            PIX = left( PIX, TOP )
            if C.DEP == NIX   then  do
               C.    =  NIX      ;  BAD = BAD + 1
               PIX   = copies( NIX, R.3 - ODD )
            end                  /* normalize full transparency   */
            else  OTH = OTH + ( C.DEP \== OPA )
         end
         if S.PIX = 0   then  do
            S.PIX = 1            ;  TOT = TOT + 1
            if R.3 > 2
               then  GRY = GRY + ( C.0 == C.1 & C.1 == C.2 )
               else  GRY = GRY + 1
         end
      end L
      if N // FOO = 0      then  BAR = BAR || '.'              /***/
      call charout /**/, BAR ( N * RO1 ) || x2c( 0D )          /***/
   end N
   say BAR left( N * RO1, 11 )   /* terminate progress BAR line ***/
   return SUMMARY( TMP, TOT, GRY, BAD, OTH, UNO )

/* -------------------------------------------------------------- */
/* Algorithm for RGB (24 bits), RGBA (32), or ya16be (16) only in */
/* 256 sets (MSB) for 32 bits (2**5, 5=16-11 ya16be) or 8192 bits */
/* (2**13, 13=24-11).  Regina or ooRexx OVERLAY() on long strings */
/* for 2097152 bits (2**21, 21=24-3) is too slow.                 */

MINICNT: procedure expose R.     /* requires 16 / 24 / 32 bits    */
   parse arg TMP                 ;  PIL = R.3 * R.8
   DEP = R.3 - 1                 ;  RO2 = min( R.1, R.2 )
   RO1 = max( R.1, R.2 )         ;  ROL = RO1 * PIL
   ODD = 1 - R.3 // 2            /* 0: no alpha, 1: transparency  */
   OPA = d2c( R.4 )              /* opaque (MAXVAL)               */
   NIX = d2c(  0, R.8 )          /* 0x00 or 0x0000 for full alpha */
   TOP = PIL - ODD * R.8         /* length of pixel without alpha */
   if TOP = 1 | TOP > 3 then  exit ERROR( 'got' TOP 'wanted 2..3' )
   S.  = d2c( 0, 2 ** ( 8 * TOP - 11 ))

   FOO = 1 + RO2 % 50            /* progress BAR: 9+9+50+11=79  ***/
   BAR = right( RO1 * RO2, 9 ) 'pixels .'                      /***/

   UNO = 1                       /* detect mono (all 0 or MAXVAL) */
   TOT = 0                       /* count RGB   (or grey) colours */
   GRY = 0                       /* count R=G=B (or grey) colours */
   BAD = 0                       /* count RGB0  (or y0)    pixels */
   OTH = 0                       /* count semi-transparent pixels */
   do N = 0 to RO2 - 1
      ROW = charin( TMP, N * ROL + 1, ROL )
      do L = 0 to RO1 - 1
         PIX = substr( ROW, L * PIL + 1, PIL )
         do D = 0 to DEP
            C.D = substr( PIX, D * R.8 + 1, R.8 )
            if UNO   then  UNO = ( C.D == NIX | C.D == OPA )
         end D
         if ODD   then  do
            PIX = left( PIX, TOP )
            if C.DEP == NIX   then  do
               C.    =  NIX      ;  BAD = BAD + 1
               PIX   = copies( NIX, R.3 - ODD )
            end                  /* normalize full transparency   */
            else  OTH = OTH + ( C.DEP \== OPA )
         end
         H   = left( PIX, 1 )    ;  PIX = substr( PIX, 2 )
         PIX = c2d( PIX )        ;  NEW = d2c( 2 ** ( PIX // 8 ))
         PIX = PIX % 8           ;  OLD = substr( S.H, PIX + 1, 1 )
         NEW = bitor( NEW, OLD ) ;  if NEW == OLD  then  iterate L
         S.H = overlay( NEW, S.H, PIX + 1 )
         TOT = TOT + 1
         if R.3 > 2
            then  GRY = GRY + ( C.0 == C.1 & C.1 == C.2 )
            else  GRY = GRY + 1
      end L
      if N // FOO = 0      then  BAR = BAR || '.'              /***/
      call charout /**/, BAR ( N * RO1 ) || x2c( 0D )          /***/
   end N
   say BAR left( N * RO1, 11 )   /* terminate progress BAR line ***/
   return SUMMARY( TMP, TOT, GRY, BAD, OTH, UNO )

/* -------------------------------------------------------------- */
/* L.0 = 0 works in tests, but is actually a very slow KWIKCNT(). */
/* L.0 = 1 processes the three least significant RGB bits as a    */
/* set in one byte (2**3 = 8).                                    */
/* L.0 = 2 processes 6 least significant bits as set in 8 bytes,  */
/* etc. (L.0 = 6 would need 8 GB for initialization).  This makes */
/* no sense, the chances that two pixels in an image fall within  */
/* a set of 8 (etc.) similar colours are slim for 2**48 colours.  */
/* OTOH if a byte is anyway used for 1 as in KWIKCNT(), it can as */
/* well store a set (2**3 bits for RGB) of least significant bits */
/* and thereby reduce the remaining high bits, e.g., 48 - 3 = 45. */

SLOWCNT: procedure expose R.     /* L.0 = 1..5 for 15..11 hi bits */
   parse arg TMP, L.0            ;  PIL = R.3 * R.8
   DEP = R.3 - 1                 ;  RO2 = min( R.1, R.2 )
   RO1 = max( R.1, R.2 )         ;  ROL = RO1 * PIL
   ODD = 1 - R.3 // 2            /* 0: no alpha, 1: transparency  */
   OPA = d2c( R.4 )              /* opaque (MAXVAL)               */
   NIX = d2c(  0, R.8 )          /* 0x00 or 0x0000 for full alpha */

   L.2 = 3 - 2 * ( R.3 < 3 )     /* 3: RGB or RGBA, 1: gray or ya */
   L.3 = 2 ** ( L.2 * L.0 )      ;  L.1 = ( L.3 + 7 ) % 8
   NEW = d2c( 0, L.1 )           /* NEW is L.1 * 8 bits, all zero */
   do N = 0 to L.3 - 1           /* B.N is bit N (of L.1 * 8) set */
      L = N  % 8                 ;  B.N = copies( d2c( 0 ), L )
      M = N // 8                 ;  B.N = d2c( 2 ** M ) || B.N
      B.N = right( B.N, L.1, d2c( 0 ))
   end N
   L.5 = 2 ** L.0                ;  L.4 = 8 * R.8 - L.0
   L.6 = 2 ** L.4                ;  L.2 = ( L.2 * L.4 + 7 ) % 8
   if L.5 * L.6 <> 256 ** R.8 then  exit ERROR( 'toast' L.5 L.6 )

   FOO = 1 + RO2 % 50            /* progress BAR: 9+9+50+11=79  ***/
   BAR = right( RO1 * RO2, 9 ) 'pixels .'                      /***/

   UNO = 1                       /* detect mono (all 0 or MAXVAL) */
   TOT = 0                       /* count RGB   (or grey) colours */
   GRY = 0                       /* count R=G=B (or grey) colours */
   BAD = 0                       /* count RGB0  (or y0)   pixels  */
   OTH = 0                       /* count semi-transparent pixels */
   S. = NEW
   do N = 0 to RO2 - 1
      ROW = charin( TMP, N * ROL + 1, ROL )
      do L = 0 to RO1 - 1
         PIX = substr( ROW, L * PIL + 1, PIL )
         do D = 0 to DEP
            C.D = substr( PIX, D * R.8 + 1, R.8 )
            if UNO   then  UNO = ( C.D == NIX | C.D == OPA )
         end D
         if ODD   then  do
            if C.DEP == NIX   then  do
               C.    =  NIX      ;  BAD = BAD + 1
            end                  /* normalize full transparency   */
            else  OTH = OTH + ( C.DEP \== OPA )
         end
         PIX = 0                 ;  LOW = 0
         do D = 0 to DEP - ODD
            C.D = c2d( C.D )
            LOW = LOW * L.5 + C.D // L.5
            PIX = PIX * L.6 + C.D  % L.5
         end D                   /* 32768=2**15 for 15=16-1 bits  */
         PIX = d2c( PIX, L.2 )
         if bitand( S.PIX, B.LOW ) == NEW then  do
            TOT = TOT + 1        ;  S.PIX = bitxor( S.PIX, B.LOW )
            if R.3 > 2
               then  GRY = GRY + ( C.0 == C.1 & C.1 == C.2 )
               else  GRY = GRY + 1
         end                     /* GRAYSCALE handled as nuisance */
      end L
      if N // FOO = 0      then  BAR = BAR || '.'              /***/
      call charout /**/, BAR ( N * RO1 ) || x2c( 0D )          /***/
   end N
   say BAR left( N * RO1, 11 )   /* terminate progress BAR line ***/
   return SUMMARY( TMP, TOT, GRY, BAD, OTH, UNO )

/* -------------------------------------------------------------- */
/* common last part of PARKJOY(), KWIKCNT(), and SLOWCNT()        */

SUMMARY: procedure expose R.
   parse arg TMP, TOT, GRY, BAD, OTH, UNO
   say right( TOT, 9 ) 'colours (ignoring any transparency)'
   say right( GRY, 9 ) ' grey (R=G=B in RGB or RGBA)'
   say right( OTH, 9 ) ' semi-transparent pixels'
   say right( BAD, 9 ) 'fully transparent counted as black'
   GRY = ( GRY = TOT )           /* 1: all grey, 0: not only grey */
   OTH = ( BAD + OTH > 0 )       /* 1: has alpha, 0: has no alpha */
   select
      when  R.3 = 1        then  TOT = word( 'gray  gray16be', R.8 )
      when  R.3 = 2        then  TOT = word( 'ya8   ya16be'  , R.8 )
      when  R.3 = 3        then  TOT = word( 'rgb24 rgb48be' , R.8 )
      when  R.3 = 4        then  TOT = word( 'rgba  rgba64be', R.8 )
   end
   select
      when    OTH & \ GRY  then  BAD = TOT
      when    OTH &   GRY  then  BAD = word( 'ya8   ya16be'  , R.8 )
      when  \ OTH & \ GRY  then  BAD = word( 'rgb24 rgb48be' , R.8 )
      when  \ OTH &   GRY & UNO  then  BAD = 'monob'
      when  \ OTH &   GRY  then  BAD = word( 'gray  gray16be', R.8 )
   end
   OUT = '-pix_fmt' BAD
   TRY = word( R.5, 2 )          /* well-known monob/monow cases  */
   if BAD <> 'monob' | TRY = ''     then  TRY = TOT
   if BAD <> TOT & BAD = 'ya16be'   then  do
      say '  CAVEAT:' TOT 'hash cannot match' BAD
      OUT = '-pix_fmt' TOT    ;  BAD = TOT
   end                           /* no ya16be output (as of 2015) */
   if BAD <> TOT  then  say '  CAVEAT:' BAD 'hash for' TRY 'input'
   call lineout TMP              /* rawvideo input to compute MD5 */
   OPT = '-sws_flags bitexact+accurate_rnd+full_chroma_int+spline'
   TRY = 'ffmpeg -hide_banner -v error'
   TRY = TRY '-f rawvideo -video_size' R.1 || 'x' || R.2
   TRY = TRY '-pixel_format' TOT '-i "' || TMP || '"'
   TRY = TRY OPT OUT '-f md5 -'  /* ffmpeg MD5 output to stdout   */
   TRY                           /* SIGNAL ON ERROR catches error */
   call SysFileDelete TMP        ;  return 0

/* -------------------------------------------------------------- */

TMPFILE: procedure               /* portable work in progress...  */
   SRC = translate( arg( 1 ), '/', '\' )
   SRC = substr( SRC, 1 + lastpos( '/', SRC ))
   TMP = value( 'TMP',, 'ENVIRONMENT' )
   if TMP = '' then  TMP = value( 'TEMP',, 'ENVIRONMENT' )
   if TMP = '' then  TMP = qualify( '.' )
   return qualify( TMP || '/' || SRC || '.tmp' )

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '[image|*]'
   say                           /* suited for REXXC tokenization */
   say ' Let ffmpeg convert a given image to PAM, then count the   '
   say ' used colours (RGB0 or grayscale).  Full transparency is   '
   say ' counted as black.                                         '
   say ' Argument "*" starts a self test with a small (134 bytes)  '
   say ' lossless WebP.  Big images (48 or 64 bits per pixel) are  '
   say ' counted in 64 passes.  Slow results beat no results.      '
   return 1

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

/* ----------------------------- (REXX ERROR template 2015-11-28) */
/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR returns 1 for ordinary calls and CALL ON conditions, for */
/* SIGNAL ON conditions ERROR exits with rc 1.                    */

ERROR:
   ERROR.3 = trace( 'o' )        /* disable any trace temporarily */
   parse version ERROR.1 ERROR.2 ERROR.3
   select                        /* unify stderr output kludges   */
      when  abbrev( ERROR.1, 'REXX' ) = 0 then  ERROR.1 = ''
      when  ERROR.1 == 'REXXSAA'          then  ERROR.1 = 'STDERR:'
      when  ERROR.2 == 5.00               then  ERROR.1 = '<STDERR>'
      when  6 <= ERROR.2 & ERROR.2 < 7    then  ERROR.1 = 'STDERR:'
      otherwise                                 ERROR.1 = '/dev/con'
   end
   ERROR.3 = lineout( ERROR.1, '' )
   ERROR.3 = right( sigl '*-*', 10 )
   if sigl <= sourceline()       /* show source line if possible  */
      then  ERROR.3 = ERROR.3 strip( sourceline( sigl ))
      else  ERROR.3 = ERROR.3 '(source line unavailable)'
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
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
   if ERROR.3 <> ''  then  do
      ERROR.3 = lineout( ERROR.1, right( '>>>', 10 ) ERROR.3 )
   end
   trace ?L                      ;  ERROR:
   if condition() <> 'SIGNAL'
      then  return 1             ;  else  exit 1

