/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) without RexxUtil  */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20

/* -------------------------------------------------------------- */

   if arg() > 2 then  exit USAGE( arg( 3 ))
   if arg() = 2 then  parse arg FILE, NICO
                else  parse arg FILE ',' NICO
   FILE = strip( FILE )
   NICO = strip( NICO )          ;  TEST = '? -? /? -h /h'
   if FILE = ''                     then  exit USAGE()
   if sign( wordpos( FILE, TEST ))  then  exit USAGE()
   if \ datatype( 0 || NICO, 'w' )  then  exit USAGE( NICO )
   if abbrev( FILE, '"' )           then  do
      TEST = length( FILE )
      if pos( '"', FILE, 2 ) < TEST then  exit USAGE( FILE )
      FILE = strip( substr( FILE, 2, TEST - 2 ))
   end

   SIZE = stream( FILE, 'c', 'query size' )
   if SIZE = ''   then  exit USAGE( 'found no' FILE )
   if SIZE < 22   then  exit USAGE( 'no BMP or ICO in' FILE )

   TEST = stream( FILE, 'c', 'open read' )
   BUFF = charin( FILE, 1, SIZE )
   TEST = stream( FILE, 'c', 'close' )

   if \ abbrev( BUFF, 'BM' )  then  do
      if LE2U( BUFF, 1, 2 ) <> 0 | LE2U( BUFF, 3, 2 ) <> 1
         then  exit USAGE( 'no BMP or ICO in' FILE )
      ICON = LE2U( BUFF, 5, 2 )
      if SIZE < 6 + 16 * ICON | ICON = 0
         then  exit USAGE( 'no BMP or ICO in' FILE )
      TEST = 'at most' ICON 'icons in' FILE
      if NICO = ''            then  exit USAGE( TEST )
      if NICO + 1 > ICON      then  exit USAGE( TEST )
      OFFS = 6 + 16 * NICO + 1
      say 'icon entry       :' RMAX( NICO ) XOFF( OFFS )
      XICO = LE2U( BUFF, OFFS +  0, 1 )
      if XICO = 0    then  XICO = 256
      say 'icon width       :' RMAX( XICO )
      YICO = LE2U( BUFF, OFFS +  1, 1 )
      if YICO = 0    then  YICO = 256
      say 'icon height      :' RMAX( YICO )
      CICO = LE2U( BUFF, OFFS +  2, 1 )
      TEST = c2x( substr( BUFF, OFFS + 3, 3 ))
      if TEST <> 000100
         then  exit ERROR( TEST '<> 000100' XOFF( OFFS + 3 ))
      BICO = LE2U( BUFF, OFFS +  6, 2 )
      ILEN = LE2U( BUFF, OFFS +  8, 4 )
      if CICO > 0 & BICO = 0
         then  exit ERROR( CICO '> 0' XOFF( OFFS + 2 ))
      TEST = '(computed)'
      if CICO = 0 & BICO < 16 & 0 < BICO
         then  CICO = 2 ** BICO
         else  TEST = ''
      say 'palette entries  :' RMAX( CICO ) TEST
      say 'icon length      :' RMAX( ILEN )
      BOFS = LE2U( BUFF, OFFS + 12, 4 )
      say 'icon begin       :' RMAX( BOFS ) XOFF( OFFS + 12 )
      TEST = BOFS + ILEN
      if SIZE < TEST then  exit ERROR( SIZE '<' TEST )
      if BICO = 0    then  exit ERROR( 'icon is no bitmap' )
      OFFS = 14 + LE2U( BUFF, BOFS + 1, 4 ) + CICO * 4
      TEST = 'BM'                ;  SIZE = ILEN + 14
      TEST = TEST || reverse( d2c( SIZE, 8 ))
      TEST = TEST || reverse( d2c( OFFS, 4 ))
      BUFF = TEST || substr( BUFF, BOFS + 1, ILEN )
      /* length( BUFF ) = SIZE = LE2U( BUFF, 3, 8 )               */
      /* LE2U( BUFF, 11, 4 ) = LE2U( BUFF, 15, 4 ) + 14           */
   end
   else  if NICO <> ''  then  exit USAGE( 'no ICO in' FILE )

   SKIP = substr( BUFF, 1, 2 )
   TEST = LE2U( BUFF,  3, 8 )    ;  BOFS = LE2U( BUFF, 11, 4 )
   HLEN = LE2U( BUFF, 15, 4 )    ;  CLEN = BOFS - HLEN - 14
   if HLEN < 12 | CLEN < 0 | SIZE < BOFS | SKIP <> 'BM'
      then  exit ERROR( 'no BMP' )

   if       TEST = HLEN + 14  then  OS22 = 64
   else  if TEST <> SIZE      then  exit ERROR( SIZE '<>' TEST )
   else  if HLEN = 64         then  OS22 = 64
   else                             OS22 = ''

   if wordpos( HLEN, 12 40 56 OS22 108 124 ) = 0
      then  exit ERROR( 'unknown BMP header size' HLEN )

   BHDR = substr( BUFF, 15, HLEN )
   if OS22 <> '' | HLEN < 60
      then  CSID = 'Win '
      else  CSID = reverse( substr( BHDR, 56 + 1, 4 ))
   select
      when  CSID = 'Win ' | CSID = 'sRGB' then  nop
      when  HLEN < 108  then  exit ERROR( 'BMP v4 broken CS' )
      when  CSID = d2c( 0, 4 )            then  nop
      when  HLEN = 108  then  exit ERROR( 'BMP v4 unknown CS' )
      when  CSID = 'LINK' | CSID = 'MBED' then  nop
      otherwise               exit ERROR( 'BMP v5 unknown CS' )
   end

   XLEN = LE2S( BHDR,  5, 4 )    ;  YLEN = LE2S( BHDR,  9, 4 )
   PLAN = LE2U( BHDR, 13, 2 )    ;  BCNT = LE2U( BHDR, 15, 2 )
   COMP = LE2U( BHDR, 17, 4 )    ;  BLEN = LE2U( BHDR, 21, 4 )
   XPPM = LE2S( BHDR, 25, 4 )    ;  YPPM = LE2S( BHDR, 29, 4 )
   CUSE = LE2U( BHDR, 33, 4 )    ;  SKIP = LE2U( BHDR, 37, 4 )

   select
      when  PLAN <> 1   then  exit ERROR( 'planes MUST be 1' )
      when  XLEN < 1    then  exit ERROR( 'width MUST be > 0' )
      when  YLEN = 0    then  exit ERROR( 'height MUST be <> 0' )
      when  XPPM < 0    then  exit ERROR( 'X PelsPerMeter < 0'  )
      when  YPPM < 0    then  exit ERROR( 'Y PelsPerMeter < 0'  )
      when  COMP > 13   then  exit ERROR( 'invalid compression' )
      when  COMP > 10   then  exit ERROR( 'BMP CMYK is invalid' )
      when  COMP > 5    then  exit ERROR( 'unknown compression' )
      when  COMP = 4 | COMP = 5  then  do
         if BCNT > 0    then  exit ERROR( 'PNG/JPEG use BCNT = 0' )
         if BLEN = 0    then  exit ERROR( 'PNG/JPEG use BLEN > 0' )
         if COMP = 4    then  exit ERROR( 'BMP JPEG is invalid' )
                        else  exit ERROR( 'BMP PNG  is invalid' )
      end
      when  COMP = 3 & BCNT <> 16 & BCNT <> 32
                        then  exit ERROR( 'no bitfields for' BCNT )
      when  wordpos( COMP, 1 2 12 13 ) > 0 & YLEN < 0
                        then  exit ERROR( 'RLE height MUST be > 0' )
      when  ( COMP = 2 | COMP = 13 ) & BCNT <> 8
                        then  exit ERROR( 'RLE8, but' BCNT 'bits' )
      when  ( COMP = 1 | COMP = 12 ) & BCNT <> 4
                        then  exit ERROR( 'RLE4, but' BCNT' bits' )
      when  wordpos( BCNT, 1 4 8 16 24 32 ) = 0
                        then  exit ERROR( 'invalid BitCount' BCNT )
      otherwise   nop            /* BCNT and COMP combination ok. */
   end

   if wordpos( COMP, 1 2 4 5 12 13 ) = 0 & NICO = ''  then  do
      TEST = ( XLEN * BCNT + 31 ) % 32    /* 32 bits padding      */
      TEST = ( TEST * 4 ) * abs( YLEN )   /* cf. MS-WMF 2.2.2.9   */
      if BLEN = 0       then  BLEN = TEST
      if BLEN < TEST    then  exit ERROR( 'unclear' BLEN '<' TEST )
      if BLEN > TEST    then  do
         say 'computed length  :' RMAX( TEST ) '<' BLEN
         BLEN = TEST
      end
   end
   if BLEN = 0 | SIZE < BOFS + BLEN
      then  exit ERROR( 'invalid BMP length' BLEN )

   if 55 < HLEN & COMP = 3 then  do
      RMSK = LE2U( BHDR, 41, 4 ) ;  GMSK = LE2U( BHDR, 45, 4 )
      BMSK = LE2U( BHDR, 49, 4 ) ;  AMSK = LE2U( BHDR, 53, 4 )
   end
   if 40 = HLEN & COMP = 3 then  do
      if CLEN <> 12  then  exit ERROR( 'found no BiBitfields' )
      RMSK = LE2U( BUFF, 55, 4 ) ; GMSK = LE2U( BUFF, 59, 4 )
      BMSK = LE2U( BUFF, 63, 4 ) ; CLEN = 0
   end

   if CUSE = 0 & BCNT <= 8 then  CUSE = 2 ** BCNT
   if CUSE * 4 > CLEN      then  exit ERROR( 'invalid palette' )

   if HLEN = 124  then  do
      CINT = LE2U( BHDR, 109, 4 );  POFS = LE2U( BHDR, 113, 4 )
      PLEN = LE2U( BHDR, 117, 4 );  SKIP = LE2U( BHDR, 121, 4 )
      if wordpos( CINT, 0 1 2 4 8 ) = 0
         then  exit ERROR( 'bad CS intent' d2x( CINT ))

      if CSID = 'LINK' | CSID = 'MBED' then  do
         TEST = POFS + 14
         if TEST < BOFS + BLEN
            then  exit ERROR( 'bad CS profile start' TEST )
         if SIZE <> TEST + PLEN
            then  exit ERROR( 'bad CS profile end' TEST + PLEN )
      end
      else  if POFS <> 0 | PLEN <> 0
         then  exit ERROR( 'spurious CS profile data' )
   end

   say 'BMP total size   :' RMAX( SIZE )
   say 'header begin     :' OMAX( 14 )
   select
      when  OS22 <> ''  then  TEST = '(OS/2 v2)'
      when  HLEN =  12  then  TEST = '(OS/2 v1)'
      when  HLEN =  40  then  TEST = '(v3)'
      when  HLEN =  56  then  TEST = '(v4 uncalibrated)'
      when  HLEN = 108  then  TEST = '(v4)'
      when  HLEN = 124  then  TEST = '(v5)'
      otherwise   exit ERROR( 'FIXME: Toast' )
   end
   say 'header length    :' RMAX( HLEN ) TEST
   if CLEN > 0 then  do
      say 'palette begin    :' OMAX( HLEN + 14 )
      say 'palette length   :' RMAX( CLEN )
      say 'palette entries  :' RMAX( CUSE )
   end
   if COMP = 3 & HLEN = 40 then  TEST = 12
                           else  TEST = CLEN
   TEST = BOFS - CLEN - HLEN - 14
   if TEST <> 0   then  say 'gap before bitmap:' RMAX( TEST )
   say 'bitmap offset    :' OMAX( BOFS )
   select
      when  COMP = 1 | COMP = 12 then  TEST = '(RLE4)'
      when  COMP = 2 | COMP = 13 then  TEST = '(RLE8)'
      when  BCNT = 1             then  TEST = '(1 bit)'
      otherwise   TEST = '(' || BCNT 'bits)'
   end
   say 'bitmap length    :' RMAX( BLEN ) TEST
   say 'image width      :' RMAX( XLEN )
   if YLEN < 0    then  TEST = '(top down)'
                  else  TEST = ''
   say 'image height     :' RMAX( YLEN ) TEST
   say 'pixels per meter :' RMAX( XPPM ) '*' YPPM
   if COMP = 3    then  do
      if BCNT < 16   then  TEST = '(unused)'
                     else  TEST = ''
      say '  red bits:' x2b( d2x( RMSK, 8 )) TEST
      say 'green bits:' x2b( d2x( GMSK, 8 )) TEST
      say ' blue bits:' x2b( d2x( BMSK, 8 )) TEST
      if 56 <= HLEN  then  do
         if BCNT = 24   then  TEST = '(unused)'
         say 'alpha bits:' x2b( d2x( AMSK, 8 )) TEST
      end
   end
   if 104 <= HLEN then  do
      if CSID = d2c( 0, 4 )   then  TEST = 'calibrated'
                              else  TEST = CSID
      if CSID = 'LINK' | CSID = 'MBED'
         then  say 'v5 color space   :' TEST
         else  say 'v4 color space   :' TEST
   end
   if 124 = HLEN  then  do
      say 'v5 CS intent     :' RMAX( CINT )
      if POFS <> 0 | PLEN <> 0   then  do
         TEST = POFS + 14 - BOFS - BLEN
         if TEST <> 0   then  say 'gap after bitmap :' RMAX( TEST )
         say 'v5 profile begin :' OMAX( POFS + 14 )
         say 'v5 profile length:' RMAX( PLEN )
      end
   end
   else  do
      TEST = SIZE - BOFS - BLEN
      if TEST <> 0   then  say 'gap after bitmap :' RMAX( TEST )
   end

   if BCNT < 16   then  return 0 /* palette (uncompressed or RLE) */
   TEST = HLEN
   if TEST = 124  then  if POFS = 0 & CINT = 0  then  TEST = 104
   if TEST = 104 & CSID <> d2c( 0, 4 )          then  TEST = 56
   if TEST =  56 & COMP <> 3                    then  TEST = 40
   if TEST < HLEN then  say 'minimal header   :' RMAX( TEST )
   return 0

RMAX: return right( arg( 1 ), 10 )
XOFF: return '(' || d2x( arg( 1 ), 8 ) || ')'
OMAX: return RMAX( arg( 1 )) XOFF( arg( 1 ))
LE2U: return c2d( reverse( substr( arg(1), arg(2), arg(3))))
LE2S: return c2d( reverse( substr( arg(1), arg(2), arg(3))), arg(3))

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'FILE[,n]'
   say                           /* suited for REXXC tokenization */
   say ' Without ",n" FILE should be a BMP, otherwise it should be '
   say ' an ICO with n+1 icons.  Use ",0" to check the first icon, '
   say ' etc.  BMP v2 and OS/2 v1 BMPs are not yet implemented.    '

   return 1                      /* exit code 1, nothing happened */

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
