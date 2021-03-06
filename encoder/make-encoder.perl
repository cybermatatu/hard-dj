#!/usr/bin/perl
#
# make-encoder.perl
# Bryce Denney <bryce at tlw.com>
# $Id: make-encoder.perl,v 1.6 2002/02/21 19:30:07 bryce Exp $
#
# Create one postscript page containing 4 encoder wheels.  The number of
# divisions is specified by command line arguments.  Also, you can add
# a thin circle at a specified radius to mark where you will cut out your
# encoder wheel.  To do this, uncomment the $cutoff_circle variable and
# set it to the radius of the circle.
#
# This program likes to create 4 wheels.  If you specify fewer than 4, the
# last arg will determine the number of divisions in the remaining wheels.
# If you really want fewer than 4, specify 0 divisions and no wheel will 
# appear in that position.
#
# These command line examples are given for a typical unix machine.
# To create four wheels with 100 divisions:
#   make-encoder.perl 100 > encoders.ps
#
# To create four wheels with different numbers of divisions:
#   make-encoder.perl 95 100 105 110 > encoders.ps
#
# To preview the page:
#   ghostview encoders.ps
#
# To print:
#   lpr encoders.ps
#
# Here's my to do list:
# - most of the size of this code, and the size of the output code,
#   is in the postscript header.  something about font definitions 
#   which I doubt is really necessary.  Figure out what can be removed
#   and throw it out for more efficient output.
# - now you must print 4 in a 2x2 hardcoded grid.  it wouldn't be herd
#   make it smarter and allow more wheels per page, etc.
# - improve interface to help people choose how many divisions based on
#   the geometry.
#
#########################################################################
# 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#########################################################################


# default setup is 4 wheels per page
$per_page = 4;
$center_x[0] = 162; $center_y[0] = 576;  # upper left
$center_x[1] = 450; $center_y[1] = 576;  # upper right
$center_x[2] = 162; $center_y[2] = 216;  # lower left
$center_x[3] = 450; $center_y[3] = 216;  # lower right
$encoder_radius = 140;   # radius of the wheels
$label_offset_x = 127 - 162;
$label_offset_y = 738 - 576;
# uncomment cutoff_circle to enable it. All wheels will have the same
# cutoff circle radius.
#$cutoff_circle = 1.0;                      # in inches
$cutoff_circle_thickness = 0.02;
$PI = 3.14159265;

if ($#ARGV < 0) {
  print <<EOF;
Usage: make-encoder.perl DIV1              makes one encoder wheel
   or: make-encoder.perl DIV1...DIV4       makes up to 4 wheels

To make an encoder wheel, the circle is cut into DIVn equal pieces.
Alternating pieces are painted black or white to make the encoder
pattern.  Odd numbers of divisions do not make any sense, because that
would create two black pieces next to each other when you reach the end.
EOF
  exit 1;
}
for ($i=0; $i<$per_page; $i++) {
  $divisions[$i] = $ARGV[$i];
  if (defined $divisions[$i]) {
    if (($divisions[$i] % 2) == 1) {
      print STDERR "Odd numbers of divisions ($divisions[$i]) are not allowed!\n";
      exit 1;
    }
    print STDERR "Wheel $i will have $divisions[$i] divisions.\n";
  }
}

&emit_header;
for ($i=0; $i<$per_page; $i++) {
  next if $divisions[$i] == 0;
  &emit_wheel ($divisions[$i], $center_x[$i], $center_y[$i], $encoder_radius);
  &emit_circle (400, $center_x[$i], $center_y[$i], $cutoff_circle*72, 
    $cutoff_circle_thickness) if defined $cutoff_circle
  &emit_label ("$divisions[$i] divisions", 
    $center_x[$i] + $label_offset_x,
    $center_y[$i] + $label_offset_y);
}
&emit_footer;
exit 0;

# Each pie piece looks like this:
#
#  A = (Ax,Ay)
#    +-------______
#    |       ______------   C = (Cx,Cy)
#    +-------
#  B = (Bx,By)
#
# The formula for points on the circle is 
#   x(theta) = Cx + radius * cos(theta)
#   y(theta) = Cy + radius * sin(theta)
# The control points for the curve will be 1/3 and 2/3 between A and B,
# on the circle.  Call those CP1 and CP2.  The postscript pattern will be
# 
# Ax Ay m
# CP1x CP1y CP2x CP2y Bx By c
# Cx Cy l
# Ax Ay l
# h
# f 

sub emit_wheel {
  ($divs, $Cx, $Cy, $radius) = @_;
  # draw in black
  print "0 0 0 1 k\n";
  # only draw the black features
  $thetastep = 2*$PI/($divs/2);
  #print STDERR "thetastep = $thetastep\n";
  for ($theta = 0; $theta<2*$PI; $theta += $thetastep) {
    $Ax = $Cx + $radius * cos($theta);
    $Ay = $Cy + $radius * sin($theta);
    $Bx = $Cx + $radius * cos($theta + $thetastep*1/2);
    $By = $Cy + $radius * sin($theta + $thetastep*1/2);
    $CP1x = $Cx + $radius * cos($theta + $thetastep*1/6);
    $CP1y = $Cy + $radius * sin($theta + $thetastep*1/6);
    $CP2x = $Cx + $radius * cos($theta + $thetastep*2/6);
    $CP2y = $Cy + $radius * sin($theta + $thetastep*2/6);
    print <<EOF;
$Ax $Ay m
$CP1x $CP1y $CP2x $CP2y $Bx $By c
$Cx $Cy l
$Ax $Ay l
h
f
EOF
  }
}

# I know this is not an efficient way to make a circle.  Sorry.
sub emit_circle {
  ($divs, $Cx, $Cy, $radius, $strokewidth) = @_;
  # draw in black
  print "0 0 0 1 k\n";
  # set pen width
  print "$strokewidth w\n";
  $theta = 0;
  $Ax = $Cx + $radius * cos($theta);
  $Ay = $Cy + $radius * sin($theta);
  print "$Ax $Ay m\n";
  #$thetastep = 2*$PI/$divs;
  for ($theta = 0; $theta<2*$PI; $theta += $thetastep) {
    #$Ax = $Cx + $radius * cos($theta);
    #$Ay = $Cy + $radius * sin($theta);
    $Bx = $Cx + $radius * cos($theta + $thetastep);
    $By = $Cy + $radius * sin($theta + $thetastep);
    $CP1x = $Cx + $radius * cos($theta + $thetastep*1/3);
    $CP1y = $Cy + $radius * sin($theta + $thetastep*1/3);
    $CP2x = $Cx + $radius * cos($theta + $thetastep*2/3);
    $CP2y = $Cy + $radius * sin($theta + $thetastep*2/3);
    print "$CP1x $CP1y $CP2x $CP2y $Bx $By c\n";
EOF
  }
  print "h\n";
  print "S\n";
}

sub emit_label {
  ($text, $x, $y) = @_;
  print <<EOF;
BT
/N5 1 Tf
12 0 0 12 $x $y Tm
($text)Tj 
ET
EOF
}

sub emit_header {
print <<EOF;
%!PS-Adobe-3.0
%%Title: (4encoders.pdf)
%%Version: 1 2
%%CreationDate: (D:20020121120658)
%%DocumentData: Clean7Bit
%%BoundingBox: 0 0 612 792
%%Pages: 1
%%DocumentProcessColors: (atend)
%%DocumentSuppliedResources: (atend)
%%EndComments
%%BeginDefaults
%%EndDefaults
%%BeginProlog
%%EndProlog
%%BeginSetup
/currentpacking where{pop currentpacking true setpacking}if
%%BeginResource: procset pdfvars
%%Copyright: Copyright 1987-1999 Adobe Systems Incorporated. All Rights Reserved.
%%Version: 4.0 2
%%Title: definition of dictionary of variables used by PDF & PDFText procsets
userdict /PDF 160 dict put
userdict /PDFVars 86 dict dup begin put
/_save 0 def
/_cshow 0 def
/InitAll 0 def
/TermAll 0 def
/DocInitAll 0 def
/DocTermAll 0 def
/_lp /none def
/_doClip 0 def
/sfc 0 def
/_sfcs 0 def
/_sfc 0 def
/ssc 0 def
/_sscs 0 def
/_ssc 0 def
/_fcs 0 def
/_scs 0 def
/_fp 0 def
/_sp 0 def
/AGM_MAX_CS_COMPONENTS 10 def
/_fillColors [ 0 1 AGM_MAX_CS_COMPONENTS { array } for ] def
/_strokeColors [ 0 1 AGM_MAX_CS_COMPONENTS { array } for ] def
/_fc null def
/_sc null def
/DefaultGray [/DeviceGray] def
/DefaultRGB [/DeviceRGB] def
/DefaultCMYK [/DeviceCMYK] def
/_inT false def
/_tr -1 def
/_rise 0 def
/_ax 0 def
/_cx 0 def
/_ld 0 def
/_tm matrix def
/_ctm matrix def
/_mtx matrix def
/_hy (-) def
/_fScl 0 def
/_hs 1 def
/_pdfEncodings 2 array def
/_baselineadj 0 def
/_fTzero false def
/_Tj 0 def
/_italMtx [1 0 .212557 1 0 0] def
/_italMtx_WMode1 [1 -.212557 0 1 0 0] def
/_italMtxType0 [1 0 .1062785 1 0 0] def
/_italMtx_WMode1Type0 [1 -.1062785 0 1 0 0] def
/_basefont 0 def
/_basefonto 0 def
/_pdf_oldCIDInit null def
/_pdf_FontDirectory 30 dict def
/_categories 10 dict def
/_sa? true def
/_op? false def
/_OP? false def
/_opmode 0 def
/_ColorSep5044? false def
/_tmpcolr? [] def
/_tmpop? {} def
/_processColors 0 def
/_defaulttransfer currenttransfer def
/_defaultflatness currentflat def
/_defaulthalftone null def
/_defaultcolortransfer null def
/_defaultblackgeneration null def
/_defaultundercolorremoval null def
/_defaultcolortransfer null def
end
%%EndResource
PDFVars begin PDF begin
%%BeginResource: procset pdfutil
%%Copyright: Copyright 1993-1999 Adobe Systems Incorporated. All Rights Reserved.
%%Version: 4.0 2
%%Title: Basic utilities used by other PDF procsets
/bd {bind def} bind def
/ld {load def} bd
/bld {
dup length dict begin
{ null def } forall
bind
end
def
} bd
/dd { PDFVars 3 1 roll put } bd
/xdd { exch dd } bd
/Level2?
systemdict /languagelevel known
{ systemdict /languagelevel get 2 ge } { false } ifelse
def
/Level3?
systemdict /languagelevel known
{systemdict /languagelevel get 3 eq } { false } ifelse
def
/getifknown {
2 copy known { get true } { pop pop false } ifelse
} bd
/here {
currentdict exch getifknown
} bd
/isdefined? { where { pop true } { false } ifelse } bd
/StartLoad { dup dup not { /_save save dd } if } bd
/EndLoad { if not { _save restore } if } bd
%%EndResource
%%BeginResource: l2compat
%%Copyright: Copyright 1987-1993 Adobe Systems Incorporated. All Rights Reserved.
/cshow isdefined? not StartLoad {
/cshow {
exch /_cshow xdd
{ 0 0 _cshow exec } forall
} bd
} EndLoad
/setcmykcolor isdefined? not StartLoad {
/setcmykcolor {
1 sub 4 1 roll
3 {
3 index add neg dup 0 lt { pop 0 } if
3 1 roll
} repeat
setrgbcolor
pop
} bd
} EndLoad
/rectclip isdefined? not StartLoad {
/re 0 def
/rectclip { newpath re clip newpath } bd
} EndLoad
/execform isdefined? not StartLoad {
/execform {
gsave dup begin
Matrix concat
BBox aload pop
exch 3 index sub
exch 2 index sub
rectclip
PaintProc end grestore
} def
} EndLoad
/sethalftone isdefined? not StartLoad {
/sethalftone {
begin
HalftoneType 1 eq
{ Frequency Angle /SpotFunction load setscreen }
if
end
} bd
} EndLoad
%%EndResource
%%BeginResource: procset pdf
%%Version: 4.0 3
%%Copyright: Copyright 1998-1999 Adobe Systems Incorporated. All Rights Reserved.
%%Title: General operators for PDF, common to all Language Levels.
[/b/B/b*/B*/BDC/BI/BMC/BT/BX/c/cm/cs/CS/d/d0/d1/Do/DP/EI/EMC/ET/EX/f/f*/g/G/gs
/h/i/j/J/k/K/l/m/M/MP/n/q/Q/re/rg/RG/ri/s/S/sc/SC/scn/SCN/sg/Tc/Td/TD/Tf/Tj/TJ
/TL/Tm/Tr/Ts/Tw/Tz/T*/v/w/W/W*/y/'/"
/applyInterpFunc/applystitchFunc/domainClip/EF/encodeInput/gsDI/ilp/icl
/initgs/int/limit/PS/rangeClip/RC/rf/makePat/csfamily 
/? /! /| /: /+ /GetGlyphDirectory
] {null def} bind forall
/v { currentpoint 6 2 roll c } bd
/y { 2 copy c } bd
/h/closepath ld
/d/setdash ld
/j/setlinejoin ld
/J/setlinecap ld
/M/setmiterlimit ld
/w/setlinewidth ld
/i {
dup 0 eq { pop _defaultflatness } if
setflat
} bd
/gsDI {
begin
/OP here { /_OP? xdd } if
/op here { /_op? xdd }
{ /OP here { /_op? xdd } if }
ifelse
/OPM here { /_opmode xdd } if
/Font here { aload pop Tf } if
/LW here { w } if
/LC here { J } if
/LJ here { j } if
/ML here { M } if
/D here { aload pop d } if
end
} bd
/ilp { /_lp /none dd } bd
/icl { /_doClip 0 dd } bd
/W { /_doClip 1 dd } bd
/W* { /_doClip 2 dd } bd
/n {
{{} {clip} {eoclip}} _doClip get exec
icl
newpath
} bd
/s { h S } bd
/B { q f Q S } bd
/B* { q f* Q S } bd
/b { h B } bd
/b* { h B* } bd
/q/save ld
/Q { restore ilp } bd
/GetCSFamily {
dup type /arraytype eq {0 get} if
} bd
/GetCompsDict
11 dict begin
/DeviceGray { pop 1 } bd
/DeviceRGB { pop 3 } bd
/DeviceCMYK { pop 4 } bd
/CIEBasedA { pop 1 } bd
/CIEBasedABC { pop 3 } bd
/CIEBasedDEF { pop 3 } bd
/CIEBasedDEFG { pop 4 } bd
/DeviceN { 1 get length } bd
/Separation { pop 1 } bd
/Indexed { pop 1 } bd
/Pattern { pop 0 } bd
currentdict
end
def
/GetComps {
GetCompsDict
1 index GetCSFamily
get exec
} bd
/cs
{
dup _fcs eq
{ pop }
{ dup /_fcs xdd
GetComps
_fillColors exch get
/_fc xdd
/_fp null dd
} ifelse
} bd
/CS
{
dup _scs eq
{ pop }
{ dup /_scs xdd GetComps _strokeColors exch get /_sc xdd /_sp null dd }
ifelse
} bd
/sc {
_fc astore pop
ilp
} bd
/SC {
_sc astore pop
ilp
} bd
/g { DefaultGray cs sc } bd
/rg { DefaultRGB cs sc } bd
/k { DefaultCMYK cs sc } bd
/G { DefaultGray CS SC } bd
/RG { DefaultRGB CS SC } bd
/K { DefaultCMYK CS SC } bd
/cm { _mtx astore concat } bd
/re {
4 2 roll m
1 index 0 rlineto
0 exch rlineto
neg 0 rlineto
h
} bd
/RC/rectclip ld
/EF/execform ld
/PS { cvx exec } bd
/initgs {
/DefaultGray [/DeviceGray] dd
/DefaultRGB [/DeviceRGB] dd
/DefaultCMYK [/DeviceCMYK] dd
0 g 0 G
[] 0 d
0 j
0 J
10 M
1 w
true setSA
/_op? false dd
/_OP? false dd
/_opmode 0 dd
/_defaulttransfer load settransfer
0 i
/RelativeColorimetric ri
newpath
} bd
/int {
dup 2 index sub 3 index 5 index sub div 6 -2 roll sub mul
exch pop add exch pop
} bd
/limit {
dup 2 index le { exch } if pop
dup 2 index ge { exch } if pop
} bd
/domainClip {
Domain aload pop 3 2 roll
limit
} [/Domain] bld
/applyInterpFunc {
0 1 DimOut 1 sub
{
dup C0 exch get exch
dup C1 exch get exch
3 1 roll
1 index sub
3 index
N exp mul add
exch
currentdict /Range_lo known
{
dup Range_lo exch get exch
Range_hi exch get
3 2 roll limit
}
{
pop
}
ifelse
exch
} for
pop
} [/DimOut /C0 /C1 /N /Range_lo /Range_hi] bld
/encodeInput {
NumParts 1 sub
0 1 2 index
{
dup Bounds exch get
2 index gt
{ exit }
{ dup
3 index eq
{ exit }
{ pop } ifelse
} ifelse
} for
3 2 roll pop
dup Bounds exch get exch
dup 1 add Bounds exch get exch
2 mul
dup Encode exch get exch
1 add Encode exch get
int
} [/NumParts /Bounds /Encode] bld
/rangeClip {
exch dup Range_lo exch get
exch Range_hi exch get
3 2 roll
limit
} [/Range_lo /Range_hi] bld
/applyStitchFunc {
Functions exch get exec
currentdict /Range_lo known {
0 1 DimOut 1 sub {
DimOut 1 add -1 roll
rangeClip
} for
} if
} [/Functions /Range_lo /DimOut] bld
%%EndResource
%%BeginResource: procset pdflev1
%%Version: 4.0 4
%%Copyright: Copyright 1987-1999 Adobe Systems Incorporated. All Rights Reserved.
%%LanguageLevel: 1
%%Title: PDF operators, with code specific for Level 1
/_defaulthalftone
/currenthalftone where
{ pop currenthalftone }
{ 4 dict dup begin
currentscreen
/SpotFunction exch def
/Angle exch def
/Frequency exch def
/HalftoneType 1 def
end }
ifelse
dd
/initialize {
_defaulthalftone sethalftone
} bd
/terminate { } bd
/pl {
transform
0.25 sub round 0.25 add exch
0.25 sub round 0.25 add exch
itransform
} bd
/m { _sa? { pl } if moveto } bd
/l { _sa? { pl } if lineto } bd
/c { _sa? { pl } if curveto } bd
/setSA { /_sa? xdd } bd
/AlmostFull?
{ dup maxlength exch length sub 2 le
} bd
/Expand
{ 1 index maxlength mul cvi dict
dup begin exch { def } forall end
} bd
/xput {
3 2 roll
dup 3 index known not
{ dup AlmostFull? { 1.5 Expand } if
} if
dup 4 2 roll put
} bd
/defineRes {
_categories 1 index known not
{ /_categories _categories 2 index 10 dict xput store
} if
_categories exch 2 copy get 5 -1 roll 4 index xput put
} bd
/findRes {
_categories exch get exch get
} bd
/ri/pop ld
/L1setcolor {
aload length
dup 0 eq
{ pop .5 setgray }
{ dup 1 eq
{ pop setgray }
{ 3 eq
{ setrgbcolor }
{ setcmykcolor }
ifelse }
ifelse }
ifelse
} bind dd
/_sfcs { } dd
/_sscs { } dd
/_sfc { _fc L1setcolor } dd
/_ssc { _sc L1setcolor } dd
/scn { sc } bd
/SCN { SC } bd
/gs
{ begin
/SA here { /_sa? xdd } if
/TR here
{
dup xcheck
{ settransfer }
{ aload pop setcolortransfer }
ifelse
} if
/HT here { sethalftone } if
/FL here { i } if
currentdict gsDI
end
} bd
/sfc {
_lp /fill ne {
_sfcs
_sfc
/_lp /fill dd
} if
} dd
/ssc {
_lp /stroke ne {
_sscs
_ssc
/_lp /stroke dd
} if
} dd
/f {
{ { sfc fill }
{gsave sfc fill grestore clip newpath icl ilp}
{gsave sfc fill grestore eoclip newpath icl ilp}
} _doClip get exec
} bd
/f* {
{ { sfc eofill }
{gsave sfc eofill grestore clip newpath icl ilp}
{gsave sfc eofill grestore eoclip newpath icl ilp}
} _doClip get exec
} bd
/S {
{ { ssc stroke }
{gsave ssc stroke grestore clip newpath icl ilp}
{gsave ssc stroke grestore eoclip newpath icl ilp}
} _doClip get exec
} bd
/rf {re f} bd
/setoverprint where
{ pop }
{ /setoverprint { pop } bd }
ifelse
%%EndResource
%%BeginResource: procset spots
%%Version: 4.0 1
%%Copyright: Copyright 1987-1999 Adobe Systems Incorporated. All Rights Reserved.
%%Title: Predefined (named) spot functions for PDF
21 dict dup begin
/CosineDot
{ 180 mul cos exch 180 mul cos add 2 div } bd
/Cross
{ abs exch abs 2 copy gt { exch } if pop neg } bd
/Diamond
{ abs exch abs 2 copy add .75 le
{ dup mul exch dup mul add 1 exch sub }
{ 2 copy add 1.23 le
{ .85 mul add 1 exch sub }
{ 1 sub dup mul exch 1 sub dup mul add 1 sub }
ifelse }
ifelse } bd
/Double
{ exch 2 div exch 2 { 360 mul sin 2 div exch } repeat add } bd
/DoubleDot
{ 2 { 360 mul sin 2 div exch } repeat add } bd
/Ellipse
{ abs exch abs 2 copy 3 mul exch 4 mul add 3 sub dup 0 lt
{ pop dup mul exch .75 div dup mul add 4 div
1 exch sub }
{ dup 1 gt
{pop 1 exch sub dup mul exch 1 exch sub
.75 div dup mul add 4 div 1 sub }
{ .5 exch sub exch pop exch pop }
ifelse }
ifelse } bd
/EllipseA
{ dup mul .9 mul exch dup mul add 1 exch sub } bd
/EllipseB
{ dup 5 mul 8 div mul exch dup mul exch add sqrt 1 exch sub } bd
/EllipseC
{ dup mul exch dup mul .9 mul add 1 exch sub } bd
/InvertedDouble
{ exch 2 div exch 2 { 360 mul sin 2 div exch } repeat add neg } bd
/InvertedDoubleDot
{ 2 { 360 mul sin 2 div exch } repeat add neg } bd
/InvertedEllipseA
{ dup mul .9 mul exch dup mul add 1 sub } bd
/InvertedEllipseC
{ dup mul exch dup mul .9 mul add 1 sub } bd
/InvertedSimpleDot
{ dup mul exch dup mul add 1 sub } bd
/Line
{ exch pop abs neg } bd
/LineX
{ pop } bd
/LineY
{ exch pop } bd
/Rhomboid
{ abs exch abs 0.9 mul add 2 div } bd
/Round
{ abs exch abs 2 copy add 1 le
{ dup mul exch dup mul add 1 exch sub }
{ 1 sub dup mul exch 1 sub dup mul add 1 sub }
ifelse } bd
/SimpleDot
{ dup mul exch dup mul add 1 exch sub } bd
/Square
{ abs exch abs 2 copy lt { exch } if pop neg } bd
end
{ /Function defineRes pop } forall
%%EndResource
%%BeginResource: procset pdftext
%%Version: 4.0 2
%%Copyright: Copyright 1987-1998 Adobe Systems Incorporated. All Rights Reserved.
%%Title: Text operators for PDF
PDF /PDFText 75 dict dup begin put
/docinitialize
{
/resourcestatus where {
pop
/CIDParams /ProcSet resourcestatus {
pop pop
false /CIDParams /ProcSet findresource /SetBuildCompatible get exec
} if
} if
PDF begin
PDFText /_pdfDefineIdentity-H known
{ PDFText /_pdfDefineIdentity-H get exec}
if
end
} bd
/initialize {
PDFText begin
/_intT false dd
0 Tr
} bd
/terminate { end } bd
/_safeput
{
Level2? not
{
2 index load dup dup length exch maxlength ge
{ dup length 5 add dict copy
3 index xdd
}
{ pop }
ifelse
}
if
3 -1 roll load 3 1 roll put
}
bd
/pdf_has_composefont? systemdict /composefont known def
/CopyFont {
{
1 index /FID ne 2 index /UniqueID ne and
{ def } { pop pop } ifelse
} forall
} bd
/Type0CopyFont
{
exch
dup length dict
begin
CopyFont
[
exch
FDepVector
{
dup /FontType get 0 eq
{
1 index Type0CopyFont
/_pdfType0 exch definefont
}
{
/_pdfBaseFont exch
2 index exec
}
ifelse
exch
}
forall
pop
]
/FDepVector exch def
currentdict
end
} bd
/cHexEncoding
[/c00/c01/c02/c03/c04/c05/c06/c07/c08/c09/c0A/c0B/c0C/c0D/c0E/c0F/c10/c11/c12
/c13/c14/c15/c16/c17/c18/c19/c1A/c1B/c1C/c1D/c1E/c1F/c20/c21/c22/c23/c24/c25
/c26/c27/c28/c29/c2A/c2B/c2C/c2D/c2E/c2F/c30/c31/c32/c33/c34/c35/c36/c37/c38
/c39/c3A/c3B/c3C/c3D/c3E/c3F/c40/c41/c42/c43/c44/c45/c46/c47/c48/c49/c4A/c4B
/c4C/c4D/c4E/c4F/c50/c51/c52/c53/c54/c55/c56/c57/c58/c59/c5A/c5B/c5C/c5D/c5E
/c5F/c60/c61/c62/c63/c64/c65/c66/c67/c68/c69/c6A/c6B/c6C/c6D/c6E/c6F/c70/c71
/c72/c73/c74/c75/c76/c77/c78/c79/c7A/c7B/c7C/c7D/c7E/c7F/c80/c81/c82/c83/c84
/c85/c86/c87/c88/c89/c8A/c8B/c8C/c8D/c8E/c8F/c90/c91/c92/c93/c94/c95/c96/c97
/c98/c99/c9A/c9B/c9C/c9D/c9E/c9F/cA0/cA1/cA2/cA3/cA4/cA5/cA6/cA7/cA8/cA9/cAA
/cAB/cAC/cAD/cAE/cAF/cB0/cB1/cB2/cB3/cB4/cB5/cB6/cB7/cB8/cB9/cBA/cBB/cBC/cBD
/cBE/cBF/cC0/cC1/cC2/cC3/cC4/cC5/cC6/cC7/cC8/cC9/cCA/cCB/cCC/cCD/cCE/cCF/cD0
/cD1/cD2/cD3/cD4/cD5/cD6/cD7/cD8/cD9/cDA/cDB/cDC/cDD/cDE/cDF/cE0/cE1/cE2/cE3
/cE4/cE5/cE6/cE7/cE8/cE9/cEA/cEB/cEC/cED/cEE/cEF/cF0/cF1/cF2/cF3/cF4/cF5/cF6
/cF7/cF8/cF9/cFA/cFB/cFC/cFD/cFE/cFF] def
/modEnc {
/_enc xdd
/_icode 0 dd
counttomark 1 sub -1 0
{
index
dup type /nametype eq
{
_enc _icode 3 -1 roll put
_icode 1 add
}
if
/_icode xdd
} for
cleartomark
_enc
} bd
/trEnc {
/_enc xdd
255 -1 0 {
exch dup -1 eq
{ pop /.notdef }
{ Encoding exch get }
ifelse
_enc 3 1 roll put
} for
pop
_enc
} bd
/TE {
/_i xdd
StandardEncoding 256 array copy modEnc
_pdfEncodings exch _i exch put
} bd
/TZ
{
/_usePDFEncoding xdd
findfont
dup length 6 add dict
begin
{
1 index /FID ne { def } { pop pop } ifelse
} forall
/pdf_origFontName FontName def
/FontName exch def
_usePDFEncoding 0 ge
{
/Encoding _pdfEncodings _usePDFEncoding get def
pop
}
{
_usePDFEncoding -1 eq
{
counttomark 0 eq
{ pop }
{
Encoding 256 array copy
modEnc /Encoding exch def
}
ifelse
}
{
256 array
trEnc /Encoding exch def
}
ifelse
}
ifelse
pdf_EuroProcSet pdf_origFontName known
{
pdf_origFontName pdf_AddEuroGlyphProc
} if
FontName currentdict
end
definefont pop
}
bd
/Level2?
systemdict /languagelevel known
{systemdict /languagelevel get 2 ge}
{false}
ifelse
def
Level2?
{
/_pdfFontStatus
{
currentglobal exch
/Font resourcestatus
{pop pop true}
{false}
ifelse
exch setglobal
} bd
}
{
/_pdfFontStatusString 50 string def
_pdfFontStatusString 0 (fonts/) putinterval
/_pdfFontStatus
{
FontDirectory 1 index known
{ pop true }
{
_pdfFontStatusString 6 42 getinterval
cvs length 6 add
_pdfFontStatusString exch 0 exch getinterval
{ status } stopped
{pop false}
{
{ pop pop pop pop true}
{ false }
ifelse
}
ifelse
}
ifelse
} bd
}
ifelse
Level2?
{
/_pdfCIDFontStatus
{
/CIDFont /Category resourcestatus
{
pop pop
/CIDFont resourcestatus
{pop pop true}
{false}
ifelse
}
{ pop false }
ifelse
} bd
}
if
/_pdfString100 100 string def
/_pdfComposeFontName
{
dup length 1 eq
{
0 get
1 index
type /nametype eq
{
_pdfString100 cvs
length dup dup _pdfString100 exch (-) putinterval
_pdfString100 exch 1 add dup _pdfString100 length exch sub getinterval
2 index exch cvs length
add 1 add _pdfString100 exch 0 exch getinterval
exch pop
true
}
{
pop pop
false
}
ifelse
}
{
false
}
ifelse
dup {exch cvn exch} if
} bd
/_pdfConcatNames
{
exch
_pdfString100 cvs
length dup dup _pdfString100 exch (-) putinterval
_pdfString100 exch 1 add dup _pdfString100 length exch sub getinterval
3 -1 roll exch cvs length
add 1 add _pdfString100 exch 0 exch getinterval
cvn
} bind def
/_pdfTextTempString 50 string def
/_pdfRegOrderingArray [(Adobe-Japan1) (Adobe-CNS1) (Adobe-Korea1) (Adobe-GB1)] def
/_pdf_CheckSupplements
{
1 index _pdfTextTempString cvs
false
_pdfRegOrderingArray
{
2 index exch
anchorsearch
{ pop pop pop true exit}
{ pop }
ifelse
}
forall
exch pop
{
/CIDFont findresource
/CIDSystemInfo get /Supplement get
exch /CMap findresource
/CIDSystemInfo get
dup type /dicttype eq
{/Supplement get}
{pop 0 }
ifelse
ge
}
{ pop pop true }
ifelse
} bind def
pdf_has_composefont?
{
/_pdfComposeFont
{
2 copy _pdfComposeFontName not
{
2 index
}
if
(pdf) exch _pdfConcatNames
dup _pdfFontStatus
{ dup findfont 5 2 roll pop pop pop true}
{
4 1 roll
1 index /CMap resourcestatus
{
pop pop
true
}
{false}
ifelse
1 index true exch
{
_pdfCIDFontStatus not
{pop false exit}
if
}
forall
and
{
1 index 1 index 0 get _pdf_CheckSupplements
{
3 -1 roll pop
2 index 3 1 roll
composefont true
}
{
pop pop exch pop false
}
ifelse
}
{
_pdfComposeFontName
{
dup _pdfFontStatus
{
exch pop
1 index exch
findfont definefont true
}
{
pop exch pop
false
}
ifelse
}
{
exch pop
false
}
ifelse
}
ifelse
{ true }
{
dup _pdfFontStatus
{ dup findfont true }
{ pop false }
ifelse
}
ifelse
}
ifelse
} bd
}
{
/_pdfComposeFont
{
_pdfComposeFontName not
{
dup
}
if
dup
_pdfFontStatus
{exch pop dup findfont true}
{
1 index
dup type /nametype eq
{pop}
{cvn}
ifelse
eq
{pop false}
{
dup _pdfFontStatus
{dup findfont true}
{pop false}
ifelse
}
ifelse
}
ifelse
} bd
}
ifelse
/_pdfStyleDicts 4 dict dup begin
/Adobe-Japan1 4 dict dup begin
Level2?
{
/Serif
/HeiseiMin-W3-83pv-RKSJ-H _pdfFontStatus
{/HeiseiMin-W3}
{
/HeiseiMin-W3 _pdfCIDFontStatus
{/HeiseiMin-W3}
{/Ryumin-Light}
ifelse
}
ifelse
def
/SansSerif
/HeiseiKakuGo-W5-83pv-RKSJ-H _pdfFontStatus
{/HeiseiKakuGo-W5}
{
/HeiseiKakuGo-W5 _pdfCIDFontStatus
{/HeiseiKakuGo-W5}
{/GothicBBB-Medium}
ifelse
}
ifelse
def
/HeiseiMaruGo-W4-83pv-RKSJ-H _pdfFontStatus
{/HeiseiMaruGo-W4}
{
/HeiseiMaruGo-W4 _pdfCIDFontStatus
{/HeiseiMaruGo-W4}
{
/Jun101-Light-RKSJ-H _pdfFontStatus
{ /Jun101-Light }
{ SansSerif }
ifelse
}
ifelse
}
ifelse
/RoundSansSerif exch def
/Default Serif def
}
{
/Serif /Ryumin-Light def
/SansSerif /GothicBBB-Medium def
{
(fonts/Jun101-Light-83pv-RKSJ-H) status
}stopped
{pop}{
{ pop pop pop pop /Jun101-Light }
{ SansSerif }
ifelse
/RoundSansSerif exch def
}ifelse
/Default Serif def
}
ifelse
end
def
/Adobe-Korea1 4 dict dup begin
/Serif /HYSMyeongJo-Medium def
/SansSerif /HYGoThic-Medium def
/RoundSansSerif SansSerif def
/Default Serif def
end
def
/Adobe-GB1 4 dict dup begin
/Serif /STSong-Light def
/SansSerif /STHeiti-Regular def
/RoundSansSerif SansSerif def
/Default Serif def
end
def
/Adobe-CNS1 4 dict dup begin
/Serif /MKai-Medium def
/SansSerif /MHei-Medium def
/RoundSansSerif SansSerif def
/Default Serif def
end
def
end
def
/TZzero
{
/_fyAdj xdd
/_wmode xdd
/_styleArr xdd
/_regOrdering xdd
3 copy
_pdfComposeFont
{
5 2 roll pop pop pop
}
{
[
0 1 _styleArr length 1 sub
{
_styleArr exch get
_pdfStyleDicts _regOrdering 2 copy known
{
get
exch 2 copy known not
{ pop /Default }
if
get
}
{
pop pop pop /Unknown
}
ifelse
}
for
]
exch pop
2 index 3 1 roll
_pdfComposeFont
{3 -1 roll pop}
{
findfont dup /FontName get exch
}
ifelse
}
ifelse
dup /WMode 2 copy known
{ get _wmode ne }
{ pop pop _wmode 1 eq}
ifelse
_fyAdj 0 ne or
{
exch _wmode _pdfConcatNames _fyAdj _pdfConcatNames
dup _pdfFontStatus
{ exch pop dup findfont false}
{ exch true }
ifelse
}
{
dup /FontType get 0 ne
}
ifelse
{
dup /FontType get 3 eq _wmode 1 eq and
{
_pdfVerticalRomanT3Font dup length 10 add dict copy
begin
/_basefont exch
dup length 3 add dict
begin
{1 index /FID ne {def}{pop pop} ifelse }
forall
/Encoding Encoding dup length array copy
dup 16#27 /quotesingle put
dup 16#60 /grave put
_regOrdering /Adobe-Japan1 eq
{dup 16#5c /yen put dup 16#a5 /yen put dup 16#b4 /yen put}
if
def
FontName
currentdict
end
definefont
def
/Encoding _basefont /Encoding get def
/_fauxfont true def
}
{
dup length 3 add dict
begin
{1 index /FID ne {def}{pop pop} ifelse }
forall
FontType 0 ne
{
/Encoding Encoding dup length array copy
dup 16#27 /quotesingle put
dup 16#60 /grave put
_regOrdering /Adobe-Japan1 eq
{dup 16#5c /yen put}
if
def
/_fauxfont true def
} if
} ifelse
/WMode _wmode def
/BaseLineAdj _fyAdj def
dup dup /FontName exch def
currentdict
end
definefont pop
}
{
pop
}
ifelse
/_pdf_FontDirectory 3 1 roll _safeput
}
bd
/swj {
dup 4 1 roll
dup length exch stringwidth
exch 5 -1 roll 3 index mul add
4 1 roll 3 1 roll mul add
6 2 roll /_cnt 0 dd
{1 index eq {/_cnt _cnt 1 add dd} if} forall pop
exch _cnt mul exch _cnt mul 2 index add 4 1 roll 2 index add 4 1 roll pop pop
} bd
/jss {
4 1 roll
{
pop pop
(0) exch 2 copy 0 exch put
gsave
exch false charpath currentpoint
5 index setmatrix stroke
3 -1 roll
32 eq
{
moveto
5 index 5 index rmoveto currentpoint
}
if
grestore
moveto
2 copy rmoveto
} exch cshow
6 {pop} repeat
} def
/jsfTzero {
{
pop pop
(0) exch 2 copy 0 exch put
exch show
32 eq
{
4 index 4 index rmoveto
}
if
2 copy rmoveto
} exch cshow
5 {pop} repeat
} def
/jsp
{
{
pop pop
(0) exch 2 copy 0 exch put
32 eq
dup {currentfont /Encoding get dup length 33 ge 
{32 get /space eq and}{pop}ifelse
}if
{ exch 5 index 5 index 5 index 5 -1 roll widthshow }
{ false charpath }
ifelse
2 copy rmoveto
} exch cshow
5 {pop} repeat
} bd
/trj { _cx 0 fWModeProc 32 _ax 0 fWModeProc 6 5 roll } bd
/pjsf { trj sfc fawidthshowProc } bd
/pjss { trj _ctm ssc jss } bd
/pjsc { trj jsp } bd
/_Tjdef [
/pjsf load
/pjss load
{
dup
currentpoint 3 2 roll
pjsf
newpath moveto
pjss
} bind
{
trj swj rmoveto
} bind
{
dup currentpoint 4 2 roll gsave
pjsf
grestore 3 1 roll moveto
pjsc
} bind
{
dup currentpoint 4 2 roll
currentpoint gsave newpath moveto
pjss
grestore 3 1 roll moveto
pjsc
} bind
{
dup currentpoint 4 2 roll gsave
dup currentpoint 3 2 roll
pjsf
newpath moveto
pjss
grestore 3 1 roll moveto
pjsc
} bind
/pjsc load
] def
/BT
{
/_inT true dd
_ctm currentmatrix pop matrix _tm copy pop
0 _rise _baselineadj add translate _hs 1 scale
0 0 moveto
} bd
/ET
{
/_inT false dd
_tr 3 gt {clip} if
_ctm setmatrix newpath
} bd
/Tr {
_inT { _tr 3 le {currentpoint newpath moveto} if } if
dup /_tr xdd
_Tjdef exch get /_Tj xdd
} bd
/Tj {
userdict /$$copystring 2 index put
_Tj
} bd
/iTm { _ctm setmatrix _tm concat 0 _rise _baselineadj add translate _hs 1 scale } bd
/Tm { _tm astore pop iTm 0 0 moveto } bd
/Td { _mtx translate _tm _tm concatmatrix pop iTm 0 0 moveto } bd
/TD { dup /_ld xdd Td } bd
/_nullProc {} bd
/Tf {
dup 1000 div /_fScl xdd
_pdf_FontDirectory 2 index 2 copy known
{get exch 3 -1 roll pop}
{pop pop}
ifelse
Level2?
{ selectfont }
{ exch findfont exch scalefont setfont}
ifelse
currentfont dup
/_nullProc exch
/WMode known
{
1 index /WMode get 1 eq
{pop /exch}
if
}
if
load /fWModeProc xdd
dup
/FontType get 0 eq dup _cx 0 ne and
{ /jsfTzero }
{ /awidthshow }
ifelse
load /fawidthshowProc xdd
/_fTzero xdd
dup /BaseLineAdj known
{ dup /BaseLineAdj get _fScl mul }
{ 0 }
ifelse
/_baselineadj xdd
dup /_pdfT3Font known
{ 0 }
{_tr}
ifelse
_Tjdef exch get /_Tj xdd
_intT
{currentpoint iTm moveto}
if
pop
} bd
/TL { neg /_ld xdd } bd
/Tw {
/_cx xdd
_cx 0 ne _fTzero and
{ /jsfTzero }
{ /awidthshow }
ifelse
load /fawidthshowProc xdd
} bd
/Tc { /_ax xdd } bd
/Ts { /_rise xdd currentpoint iTm moveto } bd
/Tz { 100 div /_hs xdd iTm } bd
/Tk { exch pop _fScl mul neg 0 fWModeProc rmoveto } bd
/T* { 0 _ld Td } bd
/' { T* Tj } bd
/" { exch Tc exch Tw ' } bd
/TJ {
{
dup type /stringtype eq
{ Tj }
{ 0 exch Tk }
ifelse
} forall
} bd
/T- { _hy Tj } bd
/d0/setcharwidth ld
/d1 { setcachedevice /sfc{}dd /ssc{}dd } bd
/nND {{/.notdef} repeat} bd
/T3Defs {
/BuildChar
{
1 index /Encoding get exch get
1 index /BuildGlyph get exec
}
def
/BuildGlyph {
exch begin
GlyphProcs exch get exec
end
} def
/_pdfT3Font true def
} bd
/_pdfBoldRomanWidthProc
{
stringwidth 1 index 0 ne { exch .03 add exch }if setcharwidth
0 0
} bd
/_pdfType0WidthProc
{
dup stringwidth 0 0 moveto
2 index true charpath pathbbox
0 -1
7 index 2 div .88
setcachedevice2
pop
0 0
} bd
/_pdfType0WMode1WidthProc
{
dup stringwidth
pop 2 div neg -0.88
2 copy
moveto
0 -1
5 -1 roll true charpath pathbbox
setcachedevice
} bd
/_pdfBoldBaseFont
11 dict begin
/FontType 3 def
/FontMatrix[1 0 0 1 0 0]def
/FontBBox[0 0 1 1]def
/Encoding cHexEncoding def
/_setwidthProc /_pdfBoldRomanWidthProc load def
/_bcstr1 1 string def
/BuildChar
{
exch begin
_basefont setfont
_bcstr1 dup 0 4 -1 roll put
dup
_setwidthProc
3 copy
moveto
show
_basefonto setfont
moveto
show
end
}bd
currentdict
end
def
pdf_has_composefont?
{
/_pdfBoldBaseCIDFont
11 dict begin
/CIDFontType 1 def
/CIDFontName /_pdfBoldBaseCIDFont def
/FontMatrix[1 0 0 1 0 0]def
/FontBBox[0 0 1 1]def
/_setwidthProc /_pdfType0WidthProc load def
/_bcstr2 2 string def
/BuildGlyph
{
exch begin
_basefont setfont
_bcstr2 1 2 index 256 mod put
_bcstr2 0 3 -1 roll 256 idiv put
_bcstr2 dup _setwidthProc
3 copy
moveto
show
_basefonto setfont
moveto
show
end
}bd
currentdict
end
def
/_pdfDefineIdentity-H
{
/Identity-H /CMap resourcestatus
{
pop pop
}
{
/CIDInit/ProcSet findresource begin 12 dict begin
begincmap
/CIDSystemInfo
3 dict begin
/Registry (Adobe) def
/Ordering (Identity) def
/Supplement 0 def
currentdict
end
def
/CMapName /Identity-H def
/CMapVersion 1 def
/CMapType 1 def
1 begincodespacerange
<0000> <ffff>
endcodespacerange
1 begincidrange
<0000> <ffff> 0
endcidrange
endcmap
CMapName currentdict/CMap defineresource pop
end
end
} ifelse
} def
} if
/_pdfVerticalRomanT3Font
10 dict begin
/FontType 3 def
/FontMatrix[1 0 0 1 0 0]def
/FontBBox[0 0 1 1]def
/_bcstr1 1 string def
/BuildChar
{
exch begin
_basefont setfont
_bcstr1 dup 0 4 -1 roll put
dup
_pdfType0WidthProc
moveto
show
end
}bd
currentdict
end
def
/MakeBoldFont
{
dup /ct_SyntheticBold known
{
dup length 3 add dict begin
CopyFont
/ct_StrokeWidth .03 0 FontMatrix idtransform pop def
/ct_SyntheticBold true def
currentdict
end
definefont
}
{
dup dup length 3 add dict
begin
CopyFont
/PaintType 2 def
/StrokeWidth .03 0 FontMatrix idtransform pop def
/dummybold currentdict
end
definefont
dup /FontType get dup 9 ge exch 11 le and
{
_pdfBoldBaseCIDFont
dup length 3 add dict copy begin
dup /CIDSystemInfo get /CIDSystemInfo exch def
/_Type0Identity /Identity-H 3 -1 roll [ exch ] composefont
/_basefont exch def
/_Type0Identity /Identity-H 3 -1 roll [ exch ] composefont
/_basefonto exch def
currentdict
end
/CIDFont defineresource
}
{
_pdfBoldBaseFont
dup length 3 add dict copy begin
/_basefont exch def
/_basefonto exch def
currentdict
end
definefont
}
ifelse
}
ifelse
} bd
/MakeBold {
1 index
_pdf_FontDirectory 2 index 2 copy known
{get}
{exch pop}
ifelse
findfont
dup
/FontType get 0 eq
{
dup /WMode known {dup /WMode get 1 eq }{false} ifelse
version length 4 ge
and
{version 0 4 getinterval cvi 2015 ge }
{true}
ifelse
{/_pdfType0WidthProc}
{/_pdfType0WMode1WidthProc}
ifelse
_pdfBoldBaseFont /_setwidthProc 3 -1 roll load put
{MakeBoldFont} Type0CopyFont definefont
}
{
dup /_fauxfont known not 1 index /SubstMaster known not and
{
_pdfBoldBaseFont /_setwidthProc /_pdfBoldRomanWidthProc load put
MakeBoldFont
}
{
2 index 2 index eq
{ exch pop }
{
dup length dict begin
CopyFont
currentdict
end
definefont
}
ifelse
}
ifelse
}
ifelse
pop pop
dup /dummybold ne
{/_pdf_FontDirectory exch dup _safeput }
{ pop }
ifelse
}bd
/MakeItalic {
_pdf_FontDirectory exch 2 copy known
{get}
{exch pop}
ifelse
dup findfont
dup /FontInfo 2 copy known
{
get
/ItalicAngle 2 copy known
{get 0 eq }
{ pop pop true}
ifelse
}
{ pop pop true}
ifelse
{
exch pop
dup /FontType get 0 eq Level2? not and
{ dup /FMapType get 6 eq }
{ false }
ifelse
{
dup /WMode 2 copy known
{
get 1 eq
{ _italMtx_WMode1Type0 }
{ _italMtxType0 }
ifelse
}
{ pop pop _italMtxType0 }
ifelse
}
{
dup /WMode 2 copy known
{
get 1 eq
{ _italMtx_WMode1 }
{ _italMtx }
ifelse
}
{ pop pop _italMtx }
ifelse
}
ifelse
makefont
dup /FontType get 42 eq Level2? not or
{
dup length dict begin
CopyFont
currentdict
end
}
if
1 index exch
definefont pop
/_pdf_FontDirectory exch dup _safeput
}
{
pop
2 copy ne
{
/_pdf_FontDirectory 3 1 roll _safeput
}
{ pop pop }
ifelse
}
ifelse
}bd
/MakeBoldItalic {
/dummybold exch
MakeBold
/dummybold
MakeItalic
}bd
Level2?
{
/pdf_CopyDict
{1 index length add dict copy}
def
}
{
/pdf_CopyDict
{
1 index length add dict
1 index wcheck
{ copy }
{ begin
{def} forall
currentdict
end
}
ifelse
}
def
}
ifelse
/pdf_AddEuroGlyphProc
{
currentdict /CharStrings known
{
CharStrings /Euro known not
{
dup
/CharStrings
CharStrings 1 pdf_CopyDict
begin
/Euro pdf_EuroProcSet 4 -1 roll get def
currentdict
end
def
/pdf_PSBuildGlyph /pdf_PSBuildGlyph load def
/pdf_PathOps /pdf_PathOps load def
/Symbol eq
{
/Encoding Encoding dup length array copy
dup 160 /Euro put def
}
if
}
{ pop
}
ifelse
}
{ pop
}
ifelse
}
def
/pdf_PathOps 4 dict dup begin
/m {moveto} def
/l {lineto} def
/c {curveto} def
/cp {closepath} def
end
def
/pdf_PSBuildGlyph
{
gsave
8 -1 roll pop
7 1 roll
currentdict /PaintType 2 copy known {get 2 eq}{pop pop false} ifelse
dup 9 1 roll
{
currentdict /StrokeWidth 2 copy known
{
get 2 div
5 1 roll
4 -1 roll 4 index sub
4 1 roll
3 -1 roll 4 index sub
3 1 roll
exch 4 index add exch
4 index add
5 -1 roll pop
}
{
pop pop
}
ifelse
}
if
setcachedevice
pdf_PathOps begin
exec
end
{
currentdict /StrokeWidth 2 copy known
{ get }
{ pop pop 0 }
ifelse
setlinewidth stroke
}
{
fill
}
ifelse
grestore
} def
/pdf_EuroProcSet 13 dict def
pdf_EuroProcSet
begin
/Courier-Bold
{
600 0 6 -12 585 612
{
385 274 m
180 274 l
179 283 179 293 179 303 c
179 310 179 316 180 323 c
398 323 l
423 404 l
197 404 l
219 477 273 520 357 520 c
409 520 466 490 487 454 c
487 389 l
579 389 l
579 612 l
487 612 l
487 560 l
449 595 394 612 349 612 c
222 612 130 529 98 404 c
31 404 l
6 323 l
86 323 l
86 304 l
86 294 86 284 87 274 c
31 274 l
6 193 l
99 193 l
129 77 211 -12 359 -12 c
398 -12 509 8 585 77 c
529 145 l
497 123 436 80 356 80 c
285 80 227 122 198 193 c
360 193 l
cp
600 0 m
}
pdf_PSBuildGlyph
} def
/Courier-BoldOblique /Courier-Bold load def
/Courier
{
600 0 17 -12 578 584
{
17 204 m
97 204 l
126 81 214 -12 361 -12 c
440 -12 517 17 578 62 c
554 109 l
501 70 434 43 366 43 c
266 43 184 101 154 204 c
380 204 l
400 259 l
144 259 l
144 270 143 281 143 292 c
143 299 143 307 144 314 c
418 314 l
438 369 l
153 369 l
177 464 249 529 345 529 c
415 529 484 503 522 463 c
522 391 l
576 391 l
576 584 l
522 584 l
522 531 l
473 566 420 584 348 584 c
216 584 122 490 95 369 c
37 369 l
17 314 l
87 314 l
87 297 l
87 284 88 272 89 259 c
37 259 l
cp
600 0 m
}
pdf_PSBuildGlyph
} def
/Courier-Oblique /Courier load def
/Helvetica
{
556 0 24 -19 541 703
{
541 628 m
510 669 442 703 354 703 c
201 703 117 607 101 444 c
50 444 l
25 372 l
97 372 l
97 301 l
49 301 l
24 229 l
103 229 l
124 67 209 -19 350 -19 c
435 -19 501 25 509 32 c
509 131 l
492 105 417 60 343 60 c
267 60 204 127 197 229 c
406 229 l
430 301 l
191 301 l
191 372 l
455 372 l
479 444 l
194 444 l
201 531 245 624 348 624 c
433 624 484 583 509 534 c
cp
556 0 m
}
pdf_PSBuildGlyph
} def
/Helvetica-Oblique /Helvetica load def
/Helvetica-Bold
{
556 0 12 -19 563 710
{
563 621 m
537 659 463 710 363 710 c
216 710 125 620 101 462 c
51 462 l
12 367 l
92 367 l
92 346 l
92 337 93 328 93 319 c
52 319 l
12 224 l
102 224 l
131 58 228 -19 363 -19 c
417 -19 471 -12 517 18 c
517 146 l
481 115 426 93 363 93 c
283 93 254 166 246 224 c
398 224 l
438 319 l
236 319 l
236 367 l
457 367 l
497 462 l
244 462 l
259 552 298 598 363 598 c
425 598 464 570 486 547 c
507 526 513 517 517 509 c
cp
556 0 m
}
pdf_PSBuildGlyph
} def
/Helvetica-BoldOblique /Helvetica-Bold load def
/Symbol
{
750 0 20 -12 714 685
{
714 581 m
650 645 560 685 465 685 c
304 685 165 580 128 432 c
50 432 l
20 369 l
116 369 l
115 356 115 347 115 337 c
115 328 115 319 116 306 c
50 306 l
20 243 l
128 243 l
165 97 300 -12 465 -12 c
560 -12 635 25 685 65 c
685 155 l
633 91 551 51 465 51 c
340 51 238 131 199 243 c
555 243 l
585 306 l
184 306 l
183 317 182 326 182 336 c
182 346 183 356 184 369 c
614 369 l 644 432 l
199 432 l
233 540 340 622 465 622 c
555 622 636 580 685 520 c
cp
750 0 m
}
pdf_PSBuildGlyph
} def
/Times-Bold
{
500 0 16 -14 478 700
{
367 308 m
224 308 l
224 368 l
375 368 l
380 414 l
225 414 l
230 589 257 653 315 653 c
402 653 431 521 444 457 c
473 457 l
473 698 l
444 697 l
441 679 437 662 418 662 c
393 662 365 700 310 700 c
211 700 97 597 73 414 c
21 414 l
16 368 l
69 368 l
69 359 68 350 68 341 c
68 330 68 319 69 308 c
21 308 l
16 262 l
73 262 l
91 119 161 -14 301 -14 c
380 -14 443 50 478 116 c
448 136 l
415 84 382 40 323 40 c
262 40 231 77 225 262 c
362 262 l
cp
500 0 m
}
pdf_PSBuildGlyph
} def
/Times-BoldItalic
{
500 0 9 -20 542 686
{
542 686 m
518 686 l
513 673 507 660 495 660 c
475 660 457 683 384 683 c
285 683 170 584 122 430 c
58 430 l
34 369 l
105 369 l
101 354 92 328 90 312 c
34 312 l
9 251 l
86 251 l
85 238 84 223 84 207 c
84 112 117 -14 272 -14 c
326 -14 349 9 381 9 c
393 9 393 -10 394 -20 c
420 -20 l
461 148 l
429 148 l
416 109 362 15 292 15 c
227 15 197 55 197 128 c
197 162 204 203 216 251 c
378 251 l
402 312 l
227 312 l
229 325 236 356 241 369 c
425 369 l
450 430 l
255 430 l
257 435 264 458 274 488 c
298 561 337 654 394 654 c
437 654 484 621 484 530 c
484 516 l
516 516 l
cp
500 0 m
}
pdf_PSBuildGlyph
} def
/Times-Italic
{
500 0 23 -10 595 692
{
399 317 m
196 317 l
199 340 203 363 209 386 c
429 386 l
444 424 l
219 424 l
246 514 307 648 418 648 c
448 648 471 638 492 616 c
529 576 524 529 527 479 c
549 475 l
595 687 l
570 687 l
562 674 558 664 542 664 c
518 664 474 692 423 692 c
275 692 162 551 116 424 c
67 424 l
53 386 l
104 386 l
98 363 93 340 90 317 c
37 317 l
23 279 l
86 279 l
85 266 85 253 85 240 c
85 118 137 -10 277 -10 c
370 -10 436 58 488 128 c
466 149 l
424 101 375 48 307 48 c
212 48 190 160 190 234 c
190 249 191 264 192 279 c
384 279 l
cp
500 0 m
}
pdf_PSBuildGlyph
} def
/Times-Roman
{
500 0 10 -12 484 692
{
347 298 m
171 298 l
170 310 170 322 170 335 c
170 362 l
362 362 l
374 403 l
172 403 l
184 580 244 642 308 642 c
380 642 434 574 457 457 c
481 462 l
474 691 l
449 691 l
433 670 429 657 410 657 c
394 657 360 692 299 692 c
204 692 94 604 73 403 c
22 403 l
10 362 l
70 362 l
69 352 69 341 69 330 c
69 319 69 308 70 298 c
22 298 l
10 257 l
73 257 l
97 57 216 -12 295 -12 c
364 -12 427 25 484 123 c
458 142 l
425 101 384 37 316 37 c
256 37 189 84 173 257 c
335 257 l
cp
500 0 m
}
pdf_PSBuildGlyph
} def
end
currentdict readonly pop end
%%EndResource
PDFText begin
[39/quotesingle 96/grave 128/Adieresis/Aring/Ccedilla/Eacute/Ntilde/Odieresis
/Udieresis/aacute/agrave/acircumflex/adieresis/atilde/aring/ccedilla/eacute
/egrave/ecircumflex/edieresis/iacute/igrave/icircumflex/idieresis/ntilde
/oacute/ograve/ocircumflex/odieresis/otilde/uacute/ugrave/ucircumflex
/udieresis/dagger/degree/cent/sterling/section/bullet/paragraph/germandbls
/registered/copyright/trademark/acute/dieresis/.notdef/AE/Oslash
/.notdef/plusminus/.notdef/.notdef/yen/mu/.notdef/.notdef
/.notdef/.notdef/.notdef/ordfeminine/ordmasculine/.notdef/ae/oslash
/questiondown/exclamdown/logicalnot/.notdef/florin/.notdef/.notdef
/guillemotleft/guillemotright/ellipsis/space/Agrave/Atilde/Otilde/OE/oe
/endash/emdash/quotedblleft/quotedblright/quoteleft/quoteright/divide
/.notdef/ydieresis/Ydieresis/fraction/currency/guilsinglleft/guilsinglright
/fi/fl/daggerdbl/periodcentered/quotesinglbase/quotedblbase/perthousand
/Acircumflex/Ecircumflex/Aacute/Edieresis/Egrave/Iacute/Icircumflex
/Idieresis/Igrave/Oacute/Ocircumflex/.notdef/Ograve/Uacute/Ucircumflex
/Ugrave/dotlessi/circumflex/tilde/macron/breve/dotaccent/ring/cedilla
/hungarumlaut/ogonek/caron
0 TE
[1/dotlessi/caron 39/quotesingle 96/grave 
127/bullet/Euro/bullet/quotesinglbase/florin/quotedblbase/ellipsis
/dagger/daggerdbl/circumflex/perthousand/Scaron/guilsinglleft/OE
/bullet/Zcaron/bullet/bullet/quoteleft/quoteright/quotedblleft
/quotedblright/bullet/endash/emdash/tilde/trademark/scaron
/guilsinglright/oe/bullet/zcaron/Ydieresis/space/exclamdown/cent/sterling
/currency/yen/brokenbar/section/dieresis/copyright/ordfeminine
/guillemotleft/logicalnot/hyphen/registered/macron/degree/plusminus
/twosuperior/threesuperior/acute/mu/paragraph/periodcentered/cedilla
/onesuperior/ordmasculine/guillemotright/onequarter/onehalf/threequarters
/questiondown/Agrave/Aacute/Acircumflex/Atilde/Adieresis/Aring/AE/Ccedilla
/Egrave/Eacute/Ecircumflex/Edieresis/Igrave/Iacute/Icircumflex/Idieresis
/Eth/Ntilde/Ograve/Oacute/Ocircumflex/Otilde/Odieresis/multiply/Oslash
/Ugrave/Uacute/Ucircumflex/Udieresis/Yacute/Thorn/germandbls/agrave
/aacute/acircumflex/atilde/adieresis/aring/ae/ccedilla/egrave/eacute
/ecircumflex/edieresis/igrave/iacute/icircumflex/idieresis/eth/ntilde
/ograve/oacute/ocircumflex/otilde/odieresis/divide/oslash/ugrave/uacute
/ucircumflex/udieresis/yacute/thorn/ydieresis
1 TE
end
currentdict readonly pop
end end
/currentpacking where {pop setpacking}if
PDFVars/DocInitAll{[ PDFText]{/docinitialize get exec}forall }put
PDFVars/InitAll{[PDF PDFText]{/initialize get exec}forall initgs}put
PDFVars/TermAll{[PDFText PDF]{/terminate get exec}forall}put
PDFVars begin PDF begin
PDFVars/DocInitAll get exec PDFVars/InitAll get exec
%%BeginResource: file Pscript_CFF PSVER
userdict/ct_CffDict 6 dict put ct_CffDict begin/F0Subr{systemdict/internaldict
known{1183615869 systemdict/internaldict get exec/FlxProc known{save true}{
false}ifelse}{userdict/internaldict known not{userdict/internaldict{count 0 eq
{/internaldict errordict/invalidaccess get exec}if dup type/integertype ne{
/internaldict errordict/invalidaccess get exec}if dup 1183615869 eq{pop 0}{
/internaldict errordict/invalidaccess get exec}ifelse}dup 14 get 1 25 dict put
bind executeonly put}if 1183615869 userdict/internaldict get exec/FlxProc
known{save true}{false}ifelse}ifelse[systemdict/internaldict known not{100
dict/begin cvx/mtx matrix/def cvx}if systemdict/currentpacking known{
currentpacking true setpacking}if{systemdict/internaldict known{1183615869
systemdict/internaldict get exec dup/$FlxDict known not{dup dup length exch
maxlength eq{pop userdict dup/$FlxDict known not{100 dict begin/mtx matrix def
dup/$FlxDict currentdict put end}if}{100 dict begin/mtx matrix def dup
/$FlxDict currentdict put end}ifelse}if/$FlxDict get begin}if grestore/exdef{
exch def}def/dmin exch abs 100 div def/epX exdef/epY exdef/c4y2 exdef/c4x2
exdef/c4y1 exdef/c4x1 exdef/c4y0 exdef/c4x0 exdef/c3y2 exdef/c3x2 exdef/c3y1
exdef/c3x1 exdef/c3y0 exdef/c3x0 exdef/c1y2 exdef/c1x2 exdef/c2x2 c4x2 def
/c2y2 c4y2 def/yflag c1y2 c3y2 sub abs c1x2 c3x2 sub abs gt def/PickCoords{{
c1x0 c1y0 c1x1 c1y1 c1x2 c1y2 c2x0 c2y0 c2x1 c2y1 c2x2 c2y2}{c3x0 c3y0 c3x1
c3y1 c3x2 c3y2 c4x0 c4y0 c4x1 c4y1 c4x2 c4y2}ifelse/y5 exdef/x5 exdef/y4 exdef
/x4 exdef/y3 exdef/x3 exdef/y2 exdef/x2 exdef/y1 exdef/x1 exdef/y0 exdef/x0
exdef}def mtx currentmatrix pop mtx 0 get abs 1e-05 lt mtx 3 get abs 1e-05 lt
or{/flipXY -1 def}{mtx 1 get abs 1e-05 lt mtx 2 get abs 1e-05 lt or{/flipXY 1
def}{/flipXY 0 def}ifelse}ifelse/erosion 1 def systemdict/internaldict known{
1183615869 systemdict/internaldict get exec dup/erosion known{/erosion get
/erosion exch def}{pop}ifelse}if yflag{flipXY 0 eq c3y2 c4y2 eq or{false
PickCoords}{/shrink c3y2 c4y2 eq{0}{c1y2 c4y2 sub c3y2 c4y2 sub div abs}ifelse
def/yshrink{c4y2 sub shrink mul c4y2 add}def/c1y0 c3y0 yshrink def/c1y1 c3y1
yshrink def/c2y0 c4y0 yshrink def/c2y1 c4y1 yshrink def/c1x0 c3x0 def/c1x1
c3x1 def/c2x0 c4x0 def/c2x1 c4x1 def/dY 0 c3y2 c1y2 sub round dtransform
flipXY 1 eq{exch}if pop abs def dY dmin lt PickCoords y2 c1y2 sub abs .001 gt{
c1x2 c1y2 transform flipXY 1 eq{exch}if/cx exch def/cy exch def/dY 0 y2 c1y2
sub round dtransform flipXY 1 eq{exch}if pop def dY round dup 0 ne{/dY exdef}{
pop dY 0 lt{-1}{1}ifelse/dY exdef}ifelse/erode PaintType 2 ne erosion .5 ge
and def erode{/cy cy .5 sub def}if/ey cy dY add def/ey ey ceiling ey sub ey
floor add def erode{/ey ey .5 add def}if ey cx flipXY 1 eq{exch}if itransform
exch pop y2 sub/eShift exch def/y1 y1 eShift add def/y2 y2 eShift add def/y3
y3 eShift add def}if}ifelse}{flipXY 0 eq c3x2 c4x2 eq or{false PickCoords}{
/shrink c3x2 c4x2 eq{0}{c1x2 c4x2 sub c3x2 c4x2 sub div abs}ifelse def/xshrink
{c4x2 sub shrink mul c4x2 add}def/c1x0 c3x0 xshrink def/c1x1 c3x1 xshrink def
/c2x0 c4x0 xshrink def/c2x1 c4x1 xshrink def/c1y0 c3y0 def/c1y1 c3y1 def/c2y0
c4y0 def/c2y1 c4y1 def/dX c3x2 c1x2 sub round 0 dtransform flipXY -1 eq{exch}
if pop abs def dX dmin lt PickCoords x2 c1x2 sub abs .001 gt{c1x2 c1y2
transform flipXY -1 eq{exch}if/cy exch def/cx exch def/dX x2 c1x2 sub round 0
dtransform flipXY -1 eq{exch}if pop def dX round dup 0 ne{/dX exdef}{pop dX 0
lt{-1}{1}ifelse/dX exdef}ifelse/erode PaintType 2 ne erosion .5 ge and def
erode{/cx cx .5 sub def}if/ex cx dX add def/ex ex ceiling ex sub ex floor add
def erode{/ex ex .5 add def}if ex cy flipXY -1 eq{exch}if itransform pop x2
sub/eShift exch def/x1 x1 eShift add def/x2 x2 eShift add def/x3 x3 eShift add
def}if}ifelse}ifelse x2 x5 eq y2 y5 eq or{x5 y5 lineto}{x0 y0 x1 y1 x2 y2
curveto x3 y3 x4 y4 x5 y5 curveto}ifelse epY epX}systemdict/currentpacking
known{exch setpacking}if/exec cvx/end cvx]cvx executeonly exch{pop true exch
restore}{systemdict/internaldict known not{1183615869 userdict/internaldict
get exec exch/FlxProc exch put true}{1183615869 systemdict/internaldict get
exec dup length exch maxlength eq{false}{1183615869 systemdict/internaldict
get exec exch/FlxProc exch put true}ifelse}ifelse}ifelse{systemdict
/internaldict known{1183615869 systemdict/internaldict get exec/FlxProc get
exec}{1183615869 userdict/internaldict get exec/FlxProc get exec}ifelse}if}
executeonly def/F1Subr{gsave currentpoint newpath moveto}bind def/F2Subr{
currentpoint grestore gsave currentpoint newpath moveto}bind def/HSSubr{
systemdict/internaldict known not{pop 3}{1183615869 systemdict/internaldict
get exec dup/startlock known{/startlock get exec}{dup/strtlck known{/strtlck
get exec}{pop 3}ifelse}ifelse}ifelse}bind def end
%%EndResource
%%BeginResource: font BAAAAA+Helvetica
ct_CffDict begin
16 dict begin
/FontInfo 14 dict dup begin
/Notice (Copyright (c) 1985, 1987, 1989, 1990, 1997 Adobe Systems Incorporated.  All Rights Reserved.Helvetica is a trademark of Linotype-Hell AG and/or its subsidiaries.) def
/version (002.000) def
/FullName (Helvetica) def
/FamilyName (Helvetica) def
/Weight (Medium) def
/ItalicAngle 0 def
/isFixedPitch false  def
/UnderlinePosition -100 def
/UnderlineThickness 50 def
end def
/FontName /BAAAAA+Helvetica def
/Encoding 256 array
0 1 255 {1 index exch /.notdef put} for def
/PaintType 0 def
/FontType 1 def
/FontMatrix [0.001 0 0 0.001 0 0 ] def
/FontBBox { -166 -225 1000 931 } def
/StrokeWidth 0 def
currentdict end
systemdict begin
dup /Private 30 dict dup begin
/-|{string currentfile exch readhexstring pop}executeonly def
/|-{def}executeonly def
/|{put}executeonly def
/BlueValues [ -19 0 718 737 523 538 688 703 ] def
/OtherBlues [ 270 281 -220 -207 ] def
/FamilyBlues [ -19 0 718 737 523 538 688 703 ] def
/FamilyOtherBlues [ 270 281 -220 -207 ] def
/StdHW [ 76 ] def
/StdVW [ 88 ] def
/BlueScale 0.0437917 def
/BlueShift 7 def
/BlueFuzz 1 def
/ForceBold false  def
/ForceBoldThreshold 0 def
/LanguageGroup 0 def
/ExpansionFactor 0.06 def
/initialRandomSeed 0 def
/lenIV 4 def
/MinFeature {16 16} def
/password 5839 def
/Erode{
11 dup 3 -1 roll 0.1 mul exch 0.5 sub mul cvi sub dup mul
88 0 dtransform dup mul exch dup mul add
le{pop pop 1.0 1.0}{pop pop 0.0 1.5}ifelse}def
/OtherSubrs [
{ct_CffDict/F0Subr get exec}executeonly{ct_CffDict/F1Subr get exec}executeonly{ct_CffDict/F2Subr get exec}executeonly{ct_CffDict/HSSubr get exec}executeonly] |-
/Subrs 5  array
dup 0 15 -| 68CCB9B7733DBF957B5C4F6827AC8A |
dup 1 9 -| 68CCB9B776ADDED836 |
dup 2 9 -| 68CCB9B776AC088F04 |
dup 3 5 -| 68CCB9B7F6 |
dup 4 13 -| 68CCB9B7733AC657EC3EB6EC2F |
|-
2 index /CharStrings 216 dict dup begin
/.notdef 9 -| 68CCB9B776D648822A |-
/space 9 -| 68CCB9B776D648822A |-
/exclam 51 -| 68CCB9B776D64882AF263664BA7116FB34D111A01917747E719CF2199E59616704E69182
B846381198EEFC5466A12B197116AC |-
/quotedbl 46 -| 68CCB9B776D615626BFE8F5051B288D1FDE88DA85352232915601884CF270AA3E12DFA13
FEC7499CC59361A4E0F3 |-
/numbersign 128 -| 68CCB9B776D98D0F1DEC23F2FDF5E97B9489B3388894AC8EF7B411FFBBFE9699253F5349
A4E4D00FAF06D7263A3C4A869215AEF3057390C2C34AFE6452E0136A7BF27B28
F46D4BF6EF2C6E6CC926971BCCE5DBDD968935423629877E951E963A9FD5F03F
9E9DFE3B766FC847170D4A87AE05B2254D2926C06FF7133E600F6AEA |-
/dollar 174 -| 68CCB9B776D98D0FC5C6D2F5E65AA3537B7ED9D6A5DEFAF951E65A2A4E66CC5E25C6F9E9
CB1735359B2EFFB41C594B6F228050C4D1B371943B2DA773DCCEDE7A9A589519
BD753A9F94CD5A2717A462E867ADCD388C916A4E23901041290CC528E8BE38DF
F5D7D9DE096BE7DC232C7AD57EE97850C8071D56D5F5834E1AA4BFFAC6A77661
298966EED21D580937DC3AAA3AC51207D304E2D4071108E4C6F14473F4B5B1FC
9C98C74868C783A3AAEF |-
/percent 294 -| 68CCB9B776DBE7C4F7346B4193B6B109606579A219F65226361943CEEDD3F19A54E00189
4F35607058CE175FF13E9825B679DA07F730AD366F0ACF9C80B37ABABCFEEEB8
3A9FB5E3A01837BAC227986F3753358C3DDA21E426DD660C309A174BEB773B8B
1CF740ED00CAC7B50ED82F952EE1C285AB6F45B0AC717A75A5F50FFB8322DA80
62F352C297C85B3AFCBF162D9656AC429F5EE87630D816F2BA104C2D0A5232CA
1FC37FA748C2DF5CC795695D990225CEF51E69A8C966700192F6747360C2198B
184ED3637662AD9140779562D7A6AE28C2B5C9B783F6E7A3E0238A2F5E12D95A
326B66CBECBD114DC35D54CADCC26717646AB4A4840BFC597B3C1B318FDEBD57
69F8BE3825155E1876D83382246B8E3AE39131237A786FC84C26CED1D7746114
9DC4 |-
/ampersand 206 -| 68CCB9B776D8503A1EB586CB3AC652878389D9DDBF2D6998B5FA765461251A6FBE7F1169
9826141A4B8157D3E8CA2020D50554031166A1902DF274278FFB72DB8F2DA272
08AFFCB2EA35B5528C6A7DB6444FE363A2513D3A8CA961A7B3A3FD1D9ADF57D0
255A3ED9AEABC67DA2F59BECEB375006472B3DE0F47F02EB314A050ECDC14E0C
66A3C790CF16994AA6C7B57068E5F7817456887177989EDCDC3AB318FCFCA127
821CA5078CC7D8FC1080185803869ECFD06D190DF764FD34276B4535B83D37FC
EEA1BAA42AD937C38292 |-
/quoteright 43 -| 68CCB9B776D69093BFEA5B3906089A7B5642606FC13B5309CD0D426F09B6E571D8870C1E
98C5115D01A8DE |-
/parenleft 68 -| 68CCB9B776D603E1DB0C64A5BF054FF2CC14DEB9DEAF5A53C854E7A5D696A2833B2548CE
900672C40BC036BEE800D55B20E161EE4871E6296D6DA66B44BA88BBD3DD784E
 |-
/parenright 68 -| 68CCB9B776D603E1DB0C64A5BF054FF2F40145F64BD0E6545205A01489BDA7A03E5B02B8
09E5B5F5D185BC147975AEB9D37C3E179D9C54E405ECCC96CE1F46E8F5AA971D
 |-
/asterisk 65 -| 68CCB9B776D95406E3325005D8A3C8D7D1C96E2460869DD9B6485415DB248E71E6724088
59EA23897F51734FA167AAF07D53202BCD08177BCC61683493FA85F857 |-
/plus 55 -| 68CCB9B776D9913639D17D99ECB254DB0D57DB6CD46EA6F8F231312EE0A25B4BDA5DB896
30BFE32A1DFE05B74A9DCF9D43A210CBA3661E |-
/comma 41 -| 68CCB9B776D64882AF22FC3E5D1620F6E099AEA3FB6873E57B4B5CDE0401703CD192D272
9024928401 |-
/hyphen 31 -| 68CCB9B776D603E1D775B624176B8948F9F48AC16E7CA3E15BC98655B00F52 |-
/period 26 -| 68CCB9B776D64882AF22FC3E5D16359CCDEA3650E742E3761AA8 |-
/slash 35 -| 68CCB9B776D64882A977E86DC7DF683B33B79D728F9F9EB6B281A2C337F76E81503F62 |-
/zero 88 -| 68CCB9B776D98D0FC5C871F34B80BBF1A440567CA38D7D85C670B40635B689E9E79BDB16
5C8406403652F0CEE9CE2247EF114117F0CEA7E16944A77D2D86CBC0C23D2D94
9E4FE0BA6FA72183915C3A7D4758091BB8D6D66B |-
/one 51 -| 68CCB9B776D98D0F1DEC23FDFE61C6419463926B3F186D77A01C5475D653AFF9EE362920
6DC1D8854A2E901C44C16E1EA5FBC8 |-
/two 133 -| 68CCB9B776D98D0F361D4CDE838DBE7C0AD239AE4A18EB1F9A19276C83875989AFC8F6A7
1B2F6E7CCE7AA9F42E2D017B3652D793A08D95D57AC9F68852A91416295F2673
0A6DB2C5A379998A813A75ADF8B975D50CCA5614398965FAE385D57A8995AC63
2EF45A03FE425B89C6FA6373E3A4DF8D84F8B1E80E76110E5C62F60BE7D941E1
1A |-
/three 179 -| 68CCB9B776D98D0FC5C871FD8622E20F6C2279C4541900B76CD19A03765FD166574E9DE7
14029D41AA1629F0E3653575DD7CA42617F00AAA0AD47A7B895775AEB6E8B698
12B16DA5200CDD0720F8C9BEAF00B4647391973749330429E3F4D765AFD97323
89157C17ECDB9419F2CC3EFAC121A44CFF82252B74D2196B749AFDDB52585770
8FB3F3D2FFF785C8D9EF93B023295C4E37B0EED7A15945DEE60F05C08D72EC84
E6CA39AAE01FB76202FBA573F4767B |-
/four 70 -| 68CCB9B776D98D0F1DEC23F2A4AC5D859A6211FE90BFD53D963E23EEC3BAA82A14B7A638
32F123115F53030C6D166728FE2D9DA8EA87FA327A289DA9849E9653526D1EE9
947C |-
/five 102 -| 68CCB9B776D98D0FC5C504AE3DC6EBAB61E41FE06F2B7BFECBE03B8675B2DF14C4FEEF52
436B53087BE897672C14DC534093B420293C3B12691AB748F3C87E6CFF95112C
03A84E19EF1194D6B53856122AEBEA9E9D1F297AACDF2848FD7C8884A228B746
E3FE |-
/six 136 -| 68CCB9B776D98D0FC5C871F2855FDCC1AA44D0BD282F9843A4CB758DBD61C8117DA7B073
50DF43794A4FAA63A202E6F362017E492BD035C0CEBC34FEEEF582B9147D0C52
0A5FF3A60A8F7F414B43123718B741E0E20C33078AA7EF692A9CEA80A471D4CA
A96FF60358E5F1158E40B055D280DD372837053E6328B22BC1E6FF6117B1D5A4
8F847A09 |-
/seven 57 -| 68CCB9B776D98D0F1DEC23FD974377CF9C870B684FF1B036B2F7C6C52586DCAE4DED1472
A2C15E0ACD373BD8CEF63501B7365328C49B3F2FCB |-
/eight 248 -| 68CCB9B776D98D0FC5C871FD813A38D5B884F488B202A95915CC25CAF4FCD97B43D6AEE1
A2AA338DEDB21DBC631C2C5C32375DD818AC2D76EA7DEA49D7FDD93302A0F71A
0B4AC142663867B2407E0AE8194B9FE037B090917D222F23D21561A037410A78
B912B867639BC10D074AFAC03603DDA31D5E848B99B4E586E61621F1607E1CCD
7497658B7CE88809C95321DA39CB43849A08AB9831419A1830034D08EFC58100
67C56530554D1987F95A0439C3CBAD0E58B34F9ED8C13C72D31BCCACD920335C
F8BEE0F1B5771F7BF724943DB324F4E7B17FC859BF5B51510958AA90924D4DBA
CDE9666C9A10BD1AC08F2AE29001ECBD0A882302 |-
/nine 123 -| 68CCB9B776D98D0FC5C6D2FBB401204003216E4E3049188BCC3BE6E54369BE19226630E4
DD29EBAEDF3CEF05CDB221890826C0C56609E5A8A75B725AACD2965A6D3AB29F
562AC5145170FFA59388B5342E97BD6F7B9BB9D22BE5605657B05C15445012E4
58BE68BA9CC1BE2EE32E618C624499C60FB0BE2332BFE9 |-
/colon 40 -| 68CCB9B776D64882AF22FC24993D3B9DA51C36AE55FCB1EAB8FEC88828ED0355A5D11A8C
D4E36673 |-
/semicolon 56 -| 68CCB9B776D64882AF22FC24993D3B9DA51C23BD82BBE6E9638A8D8FE6284F65ECD013C7
BC7E2BEB888E35E31A9989CA7AB556F6312447D2 |-
/less 46 -| 68CCB9B776D991360F315B8C03A1F7706372855D16BDD3DE9B91BFBA17F1A35D18FD18FB
03EFB7C92BB8B3ECB408 |-
/equal 47 -| 68CCB9B776D991366E64444A1704AF870E4600530A4CD008AF86AC7CA040EC6BA638EA1F
E8D533BDD804BBF8664AC4 |-
/greater 46 -| 68CCB9B776D991360F315B8C03A1F7702020E9879D69BFFF7F2560CE17EE807AA4121925
A9437ABA7B03B7D8CFCE |-
/question 149 -| 68CCB9B776D98D0F36323D4010FACB0C2BC3697082C914EB0D6D218A9A588418C99A4B63
D7FB45E80C26F54D1B5D66633A8436CC2A3B7D2CF6ABF0F66DAEF6563EAEEF86
1C2AC2605B7366B240ED6036E7A373B4ED17DBF053CF90407D2A43B72D793B9E
22C6315F0ADA966A7E53152ED889C6A95C0B01E03BFB8B6533CFCF05BD5DA27B
AEAF871A096E9339743F0E69A188445E7E |-
/at 211 -| 68CCB9B776DB61B136C1AE315A6BCCA04F9E4204860BD036C1544DD24EC3FE6BE9C10AA7
F1658B08C45C32EEFDC4AE63A6E2768EC9F876607679E4690AA54A4A0B41281D
06B07E16730350B6F7768B5FA5E6457137046106483954FADE0266A1E7034718
96812E3BCB371EC82ED86DC860FC87EBA8B35A231666255D3198A1AE4AE45D6B
2B6DDB30FEE2204B06D71D65CD0C31FE565D269333CD827F2FBB52BA38BE9FB5
3A0C9FA253D520DA818349C7491AFF783F778F9F1E23FA80CC8776DFBD5CF197
57FBDC43C3B88FB2B1BB7B927D3D94 |-
/A 87 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFBDDF43F1662936DEF3F0E71EB13E46D08D
26F008411A8895F125AAD01E52C246197D83FAC109F5CFF1C53A526C066ACC79
ADBCDDEB6A86694458FB88F421C168A5A5EDA4 |-
/B 190 -| 68CCB9B776D8503AE9CC8590D6E172898924B50BB1A48F70E2388C53DE31014D3066CAE3
234FE1D7BE57077FC169683EDB0191427E1A8088C0DF18DF348C47BD4AD46AE6
036D3E1320A98D19733B648CF2FDD54FE4F3C59AB7AEEC6A592D4758CEAC607F
EE6E898C489F27F296BA7B26C5798AEF39C97CD8CBAA8FF6C6C7BC35C0E7D831
89E2604A1AEFC29E78226AB944E394AA35EDEC586729C4B120A088F6347581F1
F8D0904EE590450589D5334648A6FEF5C2F99C6FC3A92B3B8442 |-
/C 95 -| 68CCB9B776D819D3EC5DCCAFE7196BA79B68E2C41D8F4DE4B58F175FBED20FA1E85DA5FD
B790403C778C92BDF6C18682F7D8888F29264C92AF06CD3B3D5B8C0619B1778B
7F1FFCA1270F30D0E4A815F10E15BB0E7F45BCCB9E056B6A4CB4C6 |-
/D 73 -| 68CCB9B776D819D31FB015C035FBF73A891B60195EBE794510F4300030BCDA0908D22184
C665C782EAB4D5D4246AB990BB0904634F45B967FAC64AF8FBFA577BBCD302E2
ADEA71F7BF |-
/E 59 -| 68CCB9B776D8503AE9F3F72EE8E631C4A3171B522DEECBB7B3CDBCBEC0A872B56B151F1B
A2E31D5C6A6630CCF3F50D80D3F51033DA25A10E26EFB5 |-
/F 53 -| 68CCB9B776D9BA469B7A97DBDE389F6D95AAF401BF0717F155BC0F255401E9D201B7DB0A
171BE08253F938568A37F30639A828C6ED |-
/G 148 -| 68CCB9B776D8E12E52A8883559711998A19B0F1FD474778F660446BFA881FA18E9FB896B
9FE6ECBDA0FA6570D606490FAEC9429243F69DF6827B6CEC6F87E52547C02001
D73296F720D3F44180549C5D8AA3A47E407021217BB6BCF5231B0B46D8B502DC
76287FC4C56E11110E33615B52ABEA1572C303EC3B216038357064D946232C25
C80C8E3562866CB203636935D8C8D551 |-
/H 62 -| 68CCB9B776D819D3342B81E606D18D1A823CAAAD86B373C0D666AEE317A707E544171CB6
917C1E096774ECBA1106C8E2CE66F72B7CE510551ACFA2353E8A |-
/I 32 -| 68CCB9B776D64882845DA0E9DBDF164B58144CA02A82B6B79573CAC15818A5A9 |-
/J 64 -| 68CCB9B776D9C5240BD71EBE0873015CB6D46E9C4BFAC247B1A5F57F7D622CFEB3CB18E3
9F6E58031E6D3EA558CB99446857A3F627441FF320B84CCD2AD073DB |-
/K 66 -| 68CCB9B776D8503AC2D60FF017EE59AFC43CC86D2CADB989B6C1B17CE0F26A6D0D50562B
5BD88A371A2DAB0C9C75B6C0B68F6BAAE17BCC6E356B6A082B61A8D94EA3 |-
/L 38 -| 68CCB9B776D98D0F36225467F70C5A13593F0ED0558D9EB93AC1C081B2A209D5ACF44009
54B4 |-
/M 123 -| 68CCB9B776D8AAC7FDE0D126146E7A3221055F3FBD107605CD7A19CCF98B3E7CD66AB41F
ED738A765F5DB3942EF51B30B09AE08132CD502C7FD9F061BA2F171A8E284E0D
CB6CA06F3795197D9A27F1A2C844834F297F31C6BF270C0ADBC36E8F4F3D0B41
F4F56A03A32E976AAA389369EF4E773FB9F8DD15FEB4A0 |-
/N 96 -| 68CCB9B776D819D3342B81E8E059C1F72B699DB33E3A304C4BF462CF58BEC8B0E6504A51
A421CA6DF52F323F58C88FA85238E7A2BB2C4EF78105920920E6CAE8D236C9F8
0051EFE954FBF76198527D42380E5A5DC41815C10F094A0C13DB47CE |-
/O 96 -| 68CCB9B776D8E12E5297D2D47702D21FF3AE7D32968EE063992EC99B2269503A27D2A471
DEF4DAE25694FDA13B8E8783B7EB524F0595040692B2B3B28FAAD45C93BA6DEC
168B95A1D9D101513988F67C8065D5EFE31176CAED0147D541D6C7F6 |-
/P 77 -| 68CCB9B776D8503AC2D60FFE7CA24CF268A5A8B12917B45430890CEF1EAA2CE04866AAAD
6743654107C72A2ADF4DCC9ACFBB07524C96018E00BEC85622C1C646738E7F94
69FB456D2CFF37B729 |-
/Q 173 -| 68CCB9B776D8E12E5297D2D47702D21FF3AE7D32968EE106FCE6778015AA276D21A4775C
1240C470B0812C2F08C434ABC9A4B66E109B86B5D4D965ECBFC5B12A6EDED846
B09CDDF89B952F0E944246F9F068486F4B92E1680CDD6384F95E6B5A65390CC8
FEE9B0F0CDD2EB6723C7714EAE14F591212EF9E79150DFB808836001276EFB2D
3F7A2433E5FA4EF6259CF1210BC39D99201748E580B37E4DE86CD6806F4C257D
5ED2FDE1D675F760E9 |-
/R 157 -| 68CCB9B776D819D31FF5B9E2253A1F9AAB3D23FCBE564561986A39199D4F92647E5C13AB
31F84E7F07D99501E000EFB76B13DB66D1672109F934B7EBBB5AC8703FE7ED4A
B4871F4A2E3635597E1DDB5E0D66A002A1AF223EB41122ECE85DDC8EEFFD2F43
E924FBDF5FFCD1B0C92118524253C317C44C55C0ECAC35D4809F58809AD1C193
01020E5C0570E73D2F6A43869B8037188EB4115D45E1DC57BF |-
/S 168 -| 68CCB9B776D8503A1AF6868DB9E81A38716F38C11BBAADEFAFC3A2B1A12C6337A1C9E076
5C291F8B1B2523EDD87D5659A800161BD058CE0FC2FCF974F3AD86F45062222D
BBF61D9CC4F91975A30543BE9AF47343E02EB432D35664B408776A3C28DF7226
BDB3536A4F2C24B8060DA09970C4DE4106C07B61B97EFB535663A5B4DA2E7F5C
69A3993C7313980A300BBB8C5FA9B9CAA0313CBC224B39F445FF7C2884D58B6A
7389D7C3 |-
/T 44 -| 68CCB9B776D9BA469B7A97D52242DCCA2A81F528BE9169552CA68E2844DB7E16D99FDA05
9BAB20A8F6FF3294 |-
/U 71 -| 68CCB9B776D819D3EC5DCCAF9A96C51F931B14571341E191ED9C3AC4BB018EA1D7A81AEF
96A3E517B219A621F624B9569B6A35D10E4A5C43ED730AB3C0C2BE3727E6F858
25EBF0 |-
/V 63 -| 68CCB9B776D8503AC2D60FF017EE59E7A9464DE46F7DB50CD7BD2B4A81C0E0FBBB8ACCB9
470FB668C0B948EF4DBA4620F48B46966C5B891D4357BD5FA3074B |-
/W 105 -| 68CCB9B776DBAEDEA82A924E56F786AC01DB8DE216AC47F6E8867B7EFC262417C9D7651C
4474B12693A0817EB0BFD43CF9E2CC06181DD9E7349F42DDA19011FE0DC08965
649E9D480D2CA4F4C9D6693A0735ED76D0BC8676A27ACE14A99997D0C552031F
63005EFFB9 |-
/X 73 -| 68CCB9B776D8503AC2D60FF017EE59E6782AEC67E3C5F957209DC2A07ED0DAEB94085A0F
539859E2C75D08588291333B1A77E29312875458DC908D489DA18C21E108C7E0
3F3B4FD042 |-
/Y 57 -| 68CCB9B776D8503AC2D60FF017EE598FEB8946D0CFBDA278DE86BB6AD6B5C0740C784B0A
E7AE856A0A8C3C09FB38A6717ADEDAD3CA1803D92E |-
/Z 53 -| 68CCB9B776D9BA46B01AD98E699C5159480CD7604D97ED787F9E29FA94F72B467FD121EE
91C59767DCB80EE9A37F9B19D9CAC6CF09 |-
/bracketleft 45 -| 68CCB9B776D64882DFD4AB4BA16E87F60EE566A436366D155AC3CAC8D776CD03AD19E575
9BCAF5EAE3B17231CF |-
/backslash 34 -| 68CCB9B776D64882A977E86DC7DF683B33B79D724C27AB147A3D69AB1C343367548E |-
/bracketright 46 -| 68CCB9B776D64882DFD4AB4BA16E87F633098B3EAF43420273400CBBEAC5EC89BDBD501D
8F25C103DADAEBFCF65D |-
/asciicircum 57 -| 68CCB9B776D9245A1B10448F648A4D06225974F7D03FD9C6821184A682FA6447E8984D0C
4D943BE77999C5369029B40145A384FCFF49035C72 |-
/underscore 27 -| 68CCB9B776D98D0F46BBE73ABBBEEA6DB108C894EDD95490BC4099 |-
/quoteleft 48 -| 68CCB9B776D69093BF783402F268BEA7AFD95F37076DC0941F3B0799A91CE4BDF6725849
B0F840B8C2E71B16E49F3A97 |-
/a 182 -| 68CCB9B776D98D0FC10C6FEDD76154EDA72BD880274460B324EA0DE034240055449D72B2
3DAA2A31C205010B95D8A10B0EA398FDFD1448B0EFD265C008593311CC392000
EE1B9513279377F762D855962F6090D81378BDE7B4846681700D6FFFB754215F
C7B31AE4E43B30B347F829709EC42D6BD93A19B9A0071F2ABCCD1EC9916EDD5A
FF5002CF22A7BBB3DE156259C987D0770F16856208350B317EFAAF08F5EACCBE
9887E7949AC5C32BA9EB274F0A33DC5C9087 |-
/b 207 -| 68CCB9B776D98D0FC10FDB0250EED238E3F264178CCAD81DE2641C37BE7BFB6171AB23AD
E4229040DAAC70E77462AAF8F3038E5DF2AD303ECC067243AAC789E49834FCCA
B3D147806C74B54ED31CDEFBBEA9F4E05138C3239DEC48969248C44809BDA0C1
E83D873D4B0A7F026BCD93F674F5FDB2626A9B8C47F937722A80002A48E65252
112592404390274B73535D48558AA3F0CE57B5BD52220B91FCED8F3657B8F40E
AE4A05ACB3BA8E1C1FF1273BE4A41B8B8FEFBF929B61CAE67CB83F2D08D7058C
D59DE9C0AAD8312774118D |-
/c 87 -| 68CCB9B776D9C5240F955172657B97F47BDEC9C97A5CEA08721F13D0E57342146426C42A
3E9F38E4DFA0FC4A8674143217F27A8D7AC5ACFAD0AFBFD90E22C4809D92CAFC
971C8814F2C7AAF32858E9044CB63495D486A0 |-
/d 148 -| 68CCB9B776D98D0FC10FDB0250EED238E3F2647C06A464262BC827C0634DA3638C1F96B6
BA208B2F8F485DEBDBEC81ED943A2D6D2A7F828B72A16D40C753B482BF14D3F9
C0160D534642730F67FE1466380474C9290ABCA114459988928FDD29730776E8
D78CA2506E1EB600821A9DD55BCD7D337FA4F5595EAB82E6E67D54B4294E78FF
774E96793103928BE74249DB5A576D56 |-
/e 105 -| 68CCB9B776D98D0FC10FDB0D90A38EAA5F8ED31F6B07B8E822F40B686BD211A92336483D
7A9D892C02CAB40A3A377770539F74AF7D2495AFB3D3E3A5815B29431A0B899F
790B80848221830BDDAAB9AB432585B4C4040E70867BA2020741BB2568D66FBB
10BE23F66B |-
/f 77 -| 68CCB9B776D64882845DA0E8BD093268931F705E893740E32CCBD181E14C8B66B989C880
A8D7B28B254B5C445D56F7957243161355A90E477ED035371DE8B73F6DE62778
C3828D3499C26F484F |-
/g 173 -| 68CCB9B776D98D0F46DA8E2BBF6CF963EB9C972E9782C094844BE1F9D41F968386A25EB4
254E84ECF6599A3B3078BACB85F74C15BCFC6F955AD39FE1492046380E2C150C
93D59DBD82D6A341303FFDD6B999A3C8635DEA353678C3FCC5972322B088D7DB
4A876D8E4AAF218576A5E8EAC01BF5E49BE887E7B83888C473B7F510372F6CEB
240BBF7DFE139E60AF350ED64BD06E2967B4B8B02E37875C8E6AA2B7221D5B20
80626953431260F3AD |-
/h 77 -| 68CCB9B776D98D0F1DEC23FD265E1272AE0E6DD34A132072C43EBA678E94CA645FEC9460
8BCC5FCAA562CF7A90E1AA3308684651C325B3DCB6C199577A7BAEBD7B8BA6ED
7B8C20886F9D6F8D90 |-
/i 46 -| 68CCB9B776D69093E725F5F7B14E54E09AAD00370069EC7E9750C9821935AD61D8F3BFDE
F726005456C36BD0A681 |-
/j 101 -| 68CCB9B776D69093BCC11554B1096DAE9629819B725ADC16AA3FE50FEEEB318817074792
A19E2CF4D78CA64BD9C385A93E258D39A7B7E2838E2EE397B19B0FB908215C57
6E565C4245E87E777F421E84CF91F3EAD9021ABD6414E05DDC0579B891D9D0B2
78 |-
/k 66 -| 68CCB9B776D9C524D3388A1B2F319E6A83258913C25B1E9DBDA1456C30524D3B81F5393D
005872A6E614DBCAEB7936B4D7BA51F7E014480EBBF55687F84834887F94 |-
/l 32 -| 68CCB9B776D69093E725F5F602F5351B2F7B42C9B11F6A910DCBE769C804202C |-
/m 123 -| 68CCB9B776D8AAC7FDE0D1271B83DE9724AAC9196A69CD3B1A2028F6E5E0FD5FCF019A6D
2423364D88BEE138807C41DEFC7DF33433BFE52D98292D5A46610BC4B6A5945D
B6F5739C603CF914B75D2F2D87A9F5AF8A1F75F3F5EB81874C0A53A7F710A9B4
AF16A2AE8B21E1D9ECFD641FC79BD2E1831FE4099302F4 |-
/n 104 -| 68CCB9B776D98D0F1DEC23FD265E1247FC6CE9D1D53FE715ECA90EB18D88C4EE7A69DA01
1E0CE6D5067113ADD3002B313BC5B50F40725F0B44FEBDF1420F292B35A88E1E
36829D0F95C61D36409B151445BAC64BA63C007FBEE27BCF0E706766F6AE359E
B5C6842A |-
/o 91 -| 68CCB9B776D98D0FC0DE28BA6F649B884D112C3DFAF18046AD3845916E1485342528D6D5
1093F729EE23E8233F88D6A3AE2B90D460B02FA43F69049DD793D98942934883
C90D05E7B25AC9196A28B3943A55154A54F30C9569CABF |-
/p 127 -| 68CCB9B776D98D0F46E41C44F4AD857D5464D5C58F5CC2035D08C1568DDFFEBE5555DDC7
DB04E38C03740674372B81F4A51C94CFAC598234477C17F6A235F5ACF3393FE6
FE2CEE07D810001170EF8453B1886D3B022B479EBC90DB4B77FF456F166F887F
91C367785C9CF24581AE25557E7B51B156459F93C50BB03DDF418C |-
/q 147 -| 68CCB9B776D98D0F46E41C44F4AD857D5464D5AE0604D64870FFCC773E58E8DEB89D8E59
AEA8DB62A025E9F7623B84C5790C48DC3BE3DC3E96154B7C806E9635254A027E
78884C59E419A18641357A4BE7D58B5277965FD70E599156AC4092A2EFD30E65
86FBD4B7E676C4CCD7C4BC21C274B1A89530193D07D372311E6D4B4FCB287069
ACEB7B28B896E843152CC346510A41 |-
/r 95 -| 68CCB9B776D603E18094D997F3EBE6D60B6CA57BA1EE171E51295DFE8BCA62F1804B11E7
FC55EDE1912065A07FD48DA5CBA3397B3A2809B5EFECB9443442E87F5178864E
B11A528B5F4D9641ECE82A1A88BBED9EDB81423883C2EC38370948 |-
/s 121 -| 68CCB9B776D9C5240F95517258F2B5FC0222FC52E8B39EC104D49E20C21402E2DF30291B
CFAA1586D16073F2EF98C32E9E6DB1B21A4B07E7889D34A14E7ED919A9EE437C
8F93E2C198A69BC9B54EE23023FB4AF9CFEF686C25029A705E8B7C9EF2606CC3
B56FDBBDEE75FE47F481FC47A38EB717B2B8D487EC |-
/t 70 -| 68CCB9B776D64882A06862A0AED43959D93EB9451AE63127405853AF41277BB6BA612654
6B0F87925DDEA40EE476C25D1E2C6FBD759D9C669356B30749F426003D40C8E5
7F50 |-
/u 120 -| 68CCB9B776D98D0FC10FDB0290A72C8F958E900AB180F1268333F0A59A148E650CD6D43F
2BDBFD1DFFBB23465A212222C20041E3E4AB16D56D96C8FC9BF368C2D5378446
A6FF9C1CFFBA8F4C3B10CB641FF3A4FD98B1DF454357C029B3BA40293A396742
D39E3A611C15345CA69F6C3153B63735BBA179A1 |-
/v 61 -| 68CCB9B776D9C524D3388A1B2F319E0090A64199E9DA33CBFFA494787DBF5F73467CF358
CFE3DD51658EC0DC341141BAA7D086F6E376F041A8D8809987 |-
/w 100 -| 68CCB9B776D819D3342B81E9CF649B0F41FCEB1650BF97F6B0210C75A9568832B1C59339
A96652792E5C0F108231EEDADEE94728E74626AA3045F8082F867F2666AF5C92
84C0ECFA552FC61BC4FCBB8603C07487BC627856660215744F18B25C85742D42
 |-
/x 77 -| 68CCB9B776D9C524D3388A14BDFB7F664265A11F3F04C764B6710114C905CB223AD19737
6E38CF75738E51249426D74A479D39B81641720E847AECEC29BEF6919A3BD778
AE1771C81D251B437F |-
/y 113 -| 68CCB9B776D9C52488BE81AAE652600D6819D51DFE8A61B91D72C8AB2175A326B8144CD6
94CC9DB16E45BB170A180F07D838E504D749BB452DC395C901D59618BDF2DA52
92735455108B5DE2D6D9DE47B509D5E45C2CF9F8208E374AFFEF69F33D27EFA6
9755E4635F9E34381E6F27249A |-
/z 51 -| 68CCB9B776D9C524F8F03ADB16ECC868DC7AD150B066F425BCE902B5D6D5BCEE7A5D0D8B
4E5E329BB0AB35C9C2725EA628E8FF |-
/braceleft 174 -| 68CCB9B776D6008D6EA585A428661001ABE4B208FFD72CFE2BD3DBBF1545234FBBE3FAC0
C98F2B8731FBAAFE9AD3A4D5462272AD17EF915D7AE63D2066DE96AC03A0EC9A
299716A9FD6D1631B11E9B8DF2204F547AEF6217D8721B1DBC47DD808FC04438
F6EFD3CD42CB00C6BC2CBA836410156F8808E2864FF3F42A7F7E38548A42B280
B7E6704486782CAFB6CCE0458AF1B40B66A29D9C9AED59B8E4F2270384CFF977
EE92D3F96C3AE4422D4C |-
/bar 30 -| 68CCB9B776D67AED6FD4E6FA5243C1F7194F4170BDFE682D548DBE6E29ED |-
/braceright 101 -| 68CCB9B776D6008D6EA585A426D85351AB310B0F4C5B2999B4B92FA8BF04FEC55419A8F1
2DFE46F838031660CBB068A066660A9B18BCFAA659ECB4AB60860959EBA189C2
4BC8B6F5857DBD88A0C0DCC77AC873BC66313D01C368239170A3C14EDD5E74FE
4C |-
/asciitilde 130 -| 68CCB9B776D991366ED4A94BE1247BCB5251530CD0B57B80463C9AAB02EEE9AA13284E37
A1DD5915D32C0C84F13C7BF814997746DC3B7854F7DBAACD77FFB8B5DDB1AE0B
169C9FF79A34FC291FD3C35F1E0EF8B05F42D0F3794FBEA3D9E5B944CC5762CC
034D5F61BBE7BBDF0ED6CE988F36ABDC66C1FB5853BB84FDC47A8C4DB005 |-
/exclamdown 50 -| 68CCB9B776D603E1D8EE8E1DFC6C8B76514F2EFFD31CC726CFD3A7AC1942B9DCDF0FC7E5
CE721CF24074F57D045AF7F288EA |-
/cent 189 -| 68CCB9B776D98D0FC5C504AE55A18F3AF5C85F85141D2A98BB06B9C01A117050A6CF3527
D09A12446B41C05D688D191857F4CD54244AF6F4B3C4918CCA6E4EE185B7E0E7
F9E0BA13E74D94F685799A1A05B44086DF906FB77DAA94545C31E17CD8934F17
92A853FBE1E0C794C177E9AD42402FDB4F6677ADDDD70A2ABBA3368BFBA70B38
AB0C872621AA0357405BC8205CF92B941F3A6AC777A71AD901E5ED1D9E513C63
09D1FA5B9B06BB4B8A3A5FFF5BD63E1CFF4448AB624495A70B |-
/sterling 252 -| 68CCB9B776D98D0FC63EC53181DC92B7BC7D519D8086BF4F4D422AF9CF6A5C55C0C7150F
23F8E4AC0445D441CCD087ED6E7EBC23A6C506FFA03974EA00E135B44B33CFEE
B80BF94409C8ED35BF1D5537DB3475E64BF3DB492CD1BC2E9A4AA7C7786763C7
3A1576482441B060F610F6FBA465ADC402A84475752330BD34F6C54A23ADE9B6
1D086D7E7DB4B3805A39AD0DF8643894444E39B2D5B86FCCE03B88C31F15EBCB
7E6C89B98327C771FD831D37E0A932F91A279773DC7BE7E927B595DA25AA8878
26170121192375F21E49D8338F26236B89E8C7DAAA9736B9EF07B1705BEFA2B1
3133057423541714941DACAE33FB6AE085AC1F90FB3F285C |-
/yen 99 -| 68CCB9B776D98D0F1DEC23F2D60846168D239601AACFFB234A3BCDC25019A981C2A1218B
C45DFB824C1E9F80243E17E713ED406ECF9F06CDD8477D6FEDF80BCB70188470
D51A3DA008AA0820D3ECDECFB15F4F4C283B7D1CB16447AD0187A87A2F0819 |-
/florin 159 -| 68CCB9B776D98D0F46C97E032B13E71B949546F6001558939335141925A608F118C03412
FFB81BC0561C778894D2A817CDAF025C54D78842F58582449BF001421F686C0F
BF34B1D213D10D2A3509ADABEA99A17E9F6722C984268882EE19E8CE831D242B
D935CCC01CFCF5D938F68E6F73B44762D41ED614FFA9EE2CFFEC16D47D9F73E8
A374894E2D327514AC0D34DBC2D070277821D84B994DF785681C8C |-
/section 283 -| 68CCB9B776D98D0F46F98EDC2FED8CE3FF215806AA4B6A274624D6A3F9385C79A37B381D
550CF41D61BF265B99AE6657562DF8F5E40F72904A61AFF4B2BD92C77B80EA98
93C2D7EF8334F790739B8FC5D3E0296CF3D11275FAF3A7B356C9C9F0A5F49266
4992607D4F6D962461F6DB54399B288162DB6AB41AC82B443D63D9B310EE5D1B
B0ADB5957E2CCC9E70973FB09B930088D2183EFC55F2D96E147D6909488B80B5
A0F6EB2E649F753B60157FAAFCEB300D2C8D5D81789910A284E8680DBD17F30E
403C60B7609C6369EA4905D2AA9E9E64D45DEDBB62D078B8DC3C311578DE2E55
5FCEC88CF1F949403891A7A9AEDFB4FA1E078B786CE8BC31A707848DCB5A9F9F
C69B403D21F27AD1EAA7D9E24F8321D0CD3B2D128A0903 |-
/currency 144 -| 68CCB9B776D98D0F4C518180571179178256434A108C847E5AD9A4ACA760015605B59555
6CECFB8E261E7530295AB56196A0AC60C6654A008E7828A644BD4C4B9E72D7CF
26E36BC357AD4E32FFCD392CAB5B5085768DAB67C99E938479FFFDFAF3A8C338
6EDEF2B921CCE26AD1CE05C7AF9C847D749437C503F04E2AE2CF32AB804D17AE
95DC2A97A40E8BBDE5C2CE30 |-
/quotesingle 38 -| 68CCB9B776D6B1370659CB586D3BB959E71E474806DDD2CB7188A32366A7EA153DF1A18D
76F6 |-
/quotedblleft 79 -| 68CCB9B776D603E1D8BD0951DB22A6B74ECCFA6AAC0E510565F4C100747918A6B60DFAFF
1FC53705EBB75931E3E35B85CED58505DFEA4AC9414E907EEE2BA714DE1255A2
40398A3F52A2EF82AF9F3F |-
/guillemotleft 73 -| 68CCB9B776D98D0F4A5D8EB6DCFDC3BFB276DD8EB5FE6E26327D0BD924FC3D5E33BBACB1
3167D956D2321D195A7CAD20580C423416D6D8892FAE4CE9A17AC63A51BAAB4E
5E102F3669 |-
/guilsinglleft 43 -| 68CCB9B776D603E1D7B7FD352C923318B7D74E55239C82523DB9C304113DF53B4CD2B090
F022B2F6054461 |-
/guilsinglright 42 -| 68CCB9B776D603E1D7B7FD352C923318A3CA2EBFA80C471B79527A56832B4B588732E011
F8382BF81A27 |-
/endash 31 -| 68CCB9B776D98D0F4A67DCA49CF1304F5E9D30301795C093B861849AC2DBE4 |-
/dagger 56 -| 68CCB9B776D98D0F45985021DE16428E6104E94D09BE68123748C7119D522D03C678396F
AC6F7984AA771EEF6FFED5E18EF5456382B15EE5 |-
/daggerdbl 81 -| 68CCB9B776D98D0F0BC19A3D06638782454CA4DF64EF1DDA8242FA3B5633BD0F2E40CD5F
6E44EC4274791C6F8102CD533B51D6199C16E3F9CCA063B2D8D468A6A3A7BC15
610EFB1B2EB9FFEAECF51769D3 |-
/periodcentered 44 -| 68CCB9B776D64882D38D0B8AD9DFE011B14EF31120717789927FE269728C378BC790BF82
2DFC963721741F3A |-
/paragraph 59 -| 68CCB9B776D9E0E208B802B6D73B134733DFFC363D81FF57297FBCDD8251F4A78CAB725D
937C6F12838D09DEFD8DEEE8EFD512184E8037490DD8F5 |-
/bullet 44 -| 68CCB9B776D6106AF4E70EA452396B7FAE40459EE600615614319671151A98F97CA6AA15
98780B579BAA7DC9 |-
/quotesinglbase 40 -| 68CCB9B776D69093CC7B05F440F0350FC72F62826C170078A3543B59748C367C79872DEB
586E6297 |-
/quotedblbase 71 -| 68CCB9B776D603E1AB7B9E203CE46ED94675FC97DE43DF57930CE610A0C4E83CA9A7B1C7
370714015E2BA5F41AC19010E37206E7214450E3483365A9F1D0F59124B0E800
9710BB |-
/quotedblright 74 -| 68CCB9B776D603E1D82F8EE9E5A644AC5CF3296C126BDD4B47523B12EC5931242755C2CC
02090652D4CB6D9C6B3065553A6F79753CC4A924295D66DE03654626C777D706
7ECA76B23D57 |-
/guillemotright 68 -| 68CCB9B776D98D0F4A5D8EB6DCFDC3BFB276DD8EB5FE6E2611D99794A49C9B498B0AA47B
FEF0F33233C5E85B98625AADEA031977FC5CB9EF5D995615EA8C3CFDDE5F1D5B
 |-
/ellipsis 56 -| 68CCB9B776DB96756FAA99DE3E4C229137C74634B13565D2342B3D0ED863C2EE2779BE00
3EB30B06E917E2E0ECCBAC21721ED9F4C01D50A7 |-
/perthousand 317 -| 68CCB9B776DB9675608D2B9E7582F59B4FE3D36E52F52DD2B44048D8C756ACB67D11C8C6
3F2433740FBC744B26B5CF394FF856896406D37CE5C69C172A6BC2A2FC7930FB
B1B91FBC3530C885F35FC53A2FDD9983FBB049AE1D4EB70D37517973C1D3A807
35350944A5C017FBBF3F66DF006566C46BD9B72C4DA26A6F27C279462FFDD1E4
28CEFF3112AF1BAAB8BA4059348A591BE68175DFAF063CE52B4C1C0153A30080
1E0AB1FBDD614307CF6D1384426EC509C61532FC86B849377D3BE8062676803E
B4F07CA74B4EC9AD05B015114FDE73B752FCFA829F9DAEB8CEDB320C767EEE88
9CBC32E1513B3402E4A461089483936BB18F5F78157C3A4EFB21C4AAFE881096
499E34D210EBC188677154CB64E0E97BEF5D04F192E4A674263B307386BDDFDF
5A3C43123B8D9D897D9E616484EF18FE2BFF799E7EAB33C359 |-
/questiondown 151 -| 68CCB9B776D9BA46C0BF5CFC3C6954AF92EE0CFE2387308F117E353C5AC0294215D51FE9
945549C7AC537E3DE546937FDBF6816D7A3B8807DEE9A78007A1E5AB4728E180
8CD7E32C50F7AEFAD321B5A3A1964E919A84C632C401D7995D7C206C924E2257
A0DE3D0AF8CA7F7C8835A24F5A49FABBAB5BCBDE35ADA63EC2131E935A2AD348
075FE751DBA4F1F4EED49FB2FB6411D5772BC6 |-
/grave 33 -| 68CCB9B776D603E1D832103FE0BB470312B61460C42B40176AAD426E6CF1BBAF76 |-
/acute 34 -| 68CCB9B776D603E1D832103FE0D5A9F8BFAF0F435755243E4CDE75DF53C8CD60042E |-
/circumflex 62 -| 68CCB9B776D603E1D832103FE0824D7880282771920C6B041F76DBA160B4713CF6AEA081
24A446D8DC375582E2FDF4853710A49A3D3848AFB057C8A486FF |-
/tilde 115 -| 68CCB9B776D603E1D82E67DA9D5835D8962F84695712F2B97BF7F25C0C7021F909956218
7BB844B9678176E7ED625A55B324CFBCB4572D074C87195413DFE8144597661F
0BE509ECAC85F7B9D9EFF263400D766AADB8FDE298C939173D7C8E4500178F1F
B9935093B24A0F563C38E46B5F5293 |-
/macron 31 -| 68CCB9B776D603E1D9A215F1EEAFD4B78808C92A71BC24A225AB0458BB3D08 |-
/dieresis 43 -| 68CCB9B776D603E1D827F95DB35A7DE46C2E4FB57B53E1D3A4519E7B3BBEE348E110149A
70A2187EF12F57 |-
/cedilla 83 -| 68CCB9B776D603E1DB37042A4850BDBA60B806BF6C43FA3694B08A1DD8C414F0CD0E229C
8DF5FE2EDF719F8E4B0F9AD576E8149911FC987AF61A0AF5F342653507939B31
7FC8BDF14AFBFD37F7044602F16099 |-
/caron 40 -| 68CCB9B776D603E1D832103FE0824D78804803BC3F6372CA1F39F538F375CDF9B7100B4E
147C97BE |-
/emdash 31 -| 68CCB9B776DB967513B4FF9E528C51A1D1794125E4A87B494F973818FFF55F |-
/AE 93 -| 68CCB9B776DB96756FBEB8CFF7C6487C30E9CE5DC0E4DBA2F40E9C21EB18E9B2D70265F5
A6DEF57284A8B2291D43AE5CD7D5B544ACB02AC2BCADF45734B3453A96CD95A2
FF192D2C54554FA1BACCBB7624AA3BBD869B0BCD5DD829867A |-
/ordfeminine 206 -| 68CCB9B776D94BC7B5A9151040ED5CCE06C7D3204F82FDB1B5820794227F0E70DBC98FCA
6BDF787285C5C0250A8D3DE2797D6B550CE9974FC8F32B267794792A6E6E789F
4C7F3C698E80DC7A3D960768289375B1A4D7EFF052C568030D19368964DE4E49
EFD542A7689E9932E8F4D1FC60A17EAB4E30BCE2B7499CA279B4D081041982A9
9FF5F85E8752FBA02827599ECBDEC63673A539B61E670A4CFAA4156F4C0B93DE
592F34AAFB1B4C63E9C9FE5E888B310848AFB3BE5C102BB7EF490E2A85C53E88
2613516BF595FA00CB68 |-
/Oslash 143 -| 68CCB9B776D8E12E5297D2D47702D21FF3AE7D32968EE1DC620778FDE1A9F3979FE25F52
DC910A148B47B4B779AC3B16A7F2F08F747FE8709383885720ECB61B90D50CB9
6418DB3CD2F385EC27D089BF33A5995B58B927C3A446BFD205F00957AA17A762
3AF5F726F5CDA593F3AE3D4F668D9C9887204DB5762BEA736FB319FD976ECC77
0D5F9DB729DDD5C935A061 |-
/OE 179 -| 68CCB9B776DB96756FBEB8CF48EB9092F2AB97350EAAF45A7E19BB54EDDCF2C6B2735EC4
D578910D386281FA8440163925EBBCE21092A6E6B53801A9B8249B8FC9ECE6F6
6EB685C9D70009126A4DEB7F17FC0D17EF91208011ECA5C226321A9430A0B9BA
C9E3708B5592EC5FA455BB2F23BB298C62AC5ADE2ED910E8C4BCDA8A9771DD78
FC903CDEB4B1394F4150D6A29D6400E996CE3A600D1CD534ABE13B9EA3224BF0
2B659886297045140D8B215056E857 |-
/ordmasculine 77 -| 68CCB9B776D94C956E7DBFBDABA3BEBF2C63DA8B6FD2C9D17050DD41E35B64DF68B17467
F9A81A28EE62AD400686862CCE610E65FEA2D492486B603FAC76383F584C37DD
8C624EA421081597EA |-
/ae 270 -| 68CCB9B776DBE7C40F05949E09F7C6C9CBEA1409F548E2FBD617915B6887D50A9F5375EC
7175C4E85706E0229E4F5BA56B229ED81AD2108AEF92EF36CACFEAFE36C9A52F
483D7E4AA66D475187C3F7ACBD4309E2862C974491E883EA15DD88D67311B174
F57026F3CB8E22C09384486BF19544D1D10AB2E7EFD15ACA28340DE77BB2D3B6
3622A3762BD9B65CD5F209BF77C5003FE6301B9A28804EA9ED584C16CACECA01
F7CA72FC0ACEA5B55F949D4B6A3752C18D5F9DC131BFC54A75C970D5D892671C
3864785634F7469BC4679674A9E4DB9D8139BC22C7CC3BF0ECBC2A7C93C0FA1A
B84907621EE2EAD6BDA816FA9F7E4AB6C0CFD895BDC8CC25DC8FC51F1091BF84
54D35BA94345D6E795AB |-
/dotlessi 32 -| 68CCB9B776D64882845DA0E87477DFF08877206381D389589E736D3DD3E87C0A |-
/oslash 204 -| 68CCB9B776D9BA4646557D43AC02D0B72C8D5460A4576C4AC73032C5D2ABBBC90DB59254
1603FC041D77B1029DBB77E76815BB55F2166A016A357E806DFBF98AEAEABC9C
40CA1DAC3A3759EEF5B8E2FC61050600D121E71005A91DD3635CBBAACCC0C385
262572C8B732DBA4B7BC831DCB8C1D20A5CCC309B76502AF8EFDD8707E650E6E
373750EB3E03BF82A7DC706FE39A2ECA20A4CD82A4088CBA118AE805FE5812B0
CF754D0004BBF07110CB69F52E6EF9DCCB42AA962243FA9E131F958BF1014359
9A1CD1F19F1468B4 |-
/oe 265 -| 68CCB9B776DBAEDE75EB719BAA103FC73D0DB5861B3690F82A00E1D3DAD8B1F095A6B6A9
FE8CA65E713B9D03E9760FC105D7F1C07A059188B63778A08A8582972415FFA7
99D35AFB79750C74321C988E3A68FBEB43BE55FCD1EE2D79C3BBEE7D475BD0F2
971F75D5A4C7388D4078B0AF3C661A079C70BF3CB0330C4520B6E3FD7065AFF6
750A7D325E33FE6BF9E16B4FAFF36B8ABC7441811FACD695417FB057AED3B26B
44694E117B440CE63073823C8A35C184D2C2EBD81D50B267892F3E8C386D8421
263919809C7211CB730B2C01F4DD9B6CAFDD9AE1F9894962F291CB67473BC8E2
09516906FE0E6858AC3E7C922257A603DED3434DCCCFB31FE0C71D9EA5C7914D
720CD693B2 |-
/germandbls 231 -| 68CCB9B776D9BA46478AD28D3928A34EB0F1F6AA9006ED97D490387D0D50DD6235970348
E02002D66E2BC0AD98ADE99E897314977D18697C5CAE0130674055B2EDE5FFE5
F3834943EFE28120A7C07BDECAD2844A97EC8A5A6D2F488C3E4E182F133462C2
EA9C7F3DFB4E747315C822D4CF2FDBC8A4FC74740E5069B6011746B67B05F0EE
438BDACB829554480CF449CD542EF72F982DE4DBEC930C25C16FE7B98DD52AFF
F4D803711C560A7DA7E263520401E79BBF272037E002992FC0B2C5AC4591BFEE
AC66A9D861A4351DE446B871A9756704D487CA4EE1B4EFDAA04630FAC43F251C
0CED29 |-
/onesuperior 76 -| 68CCB9B776D603E1D7CBDD7652413D7CE62AFA770D9EC7056E46F7D779C1AD9778F79C4C
12CFF13682E20E33B4309D34A6A5789B9B6FE242BD51C4133636A6A404D55FE8
5C90250D6D4A5E12 |-
/logicalnot 36 -| 68CCB9B776D991366EB2A155AE92034853F06A81DE56786C628BDB07F3C25AF6A69A597C
 |-
/mu 144 -| 68CCB9B776D98D0F46E41C44F4AD857D942EE2D9B9A704A05ED92BD3D00DAF00571DF2D7
BB15C66DFE78BE673B28356F43066B0437CB5ACE2F972C5F912A7CA9B14A8523
3AF45D6C52469A762F6BC74497A384DC5E389D2C606B9305650DB84FFF3D170C
203EFBF80439350F2F4F61AE0DC85B23421E5DDE8C53445327463C51DC6855BD
B35A0E7C09879B22D8CEDB94 |-
/trademark 99 -| 68CCB9B776DB96751D6689CDFD9323CB8D0553B430DE69421AEFDC296018E92BD675578B
616C20042AA5DD7177D6EB600C2FAA73FDF0C87A1A7D8D1DA1228D3E5F3DCB4B
C7718673DBD9FAF92B2831900946157788591B9314F652D39BA0601370F7F1 |-
/Eth 101 -| 68CCB9B776D819D31FB015CE5E47DF5CFB80C975AB9E001C9A7C80A1EBDD51BBAFAB93BD
12C9020C52E0C551D5416BF12BF337F948646F8097A4F1CEF02565A7B42F43D4
A945B863B80065EEEFDFDD3A32D3EC1113032F32122EFB2EBF9F2CFD915D69C8
71 |-
/onehalf 239 -| 68CCB9B776D8A9F62322C5853E9B02946520ECB110CAA59611191A2F9C51F3F2417A4A9F
C649CB6CB5EFCB09E2CA7F146FF02AF4C388C069CD2C32F2973D474258CA9560
8383AA181EBC2A5E18EDEE852AD24D3258D1FC5BF09154F5A36E19C135742354
A72D8AAA55F6291864533DD436CF30C55488A5C4FDEAC7776BE1E2071D168D11
0B75794454D22FD4543D38A2CD639369975C826F47E6955C0E0804C6D27C3C07
3BE868208F05239E4AB08D86B9271D78DA84B0C03D1B0804034A944EBD677756
DB2F2FAD447D79D095909BFDE66498911CC8E9955AE62D6D297A62F36644814B
9C8261F5AC404E95B3C9B2 |-
/plusminus 69 -| 68CCB9B776D9913612E00E4DD3D0A9A0535CC1D8A4F9D6F6C9D9F4391034F7B6FC23F87E
E5BE72832E04659A318F1DBB771113C6D6877F6A06D2BAC1674839C4A9A65C09
F9 |-
/Thorn 105 -| 68CCB9B776D8503AC2D60FFEF3AF8EAB83421BDE68664530FA98DE7319FDE489977EC427
14750724214E0235419AEB786391E466DCA792BCA482B4AE03538B9C5348F8E8
7CF3707BE55E6EE7632133176FB4964C8027FCC303C7BED7F5EB42ADE5956798
9B7DE58A1E |-
/onequarter 252 -| 68CCB9B776D8A9F625F1E2C0E48CF1F7C33359B54895D512544E863D5930B58E21E6F1C3
3BFBDCA26F21964172C9C524CF64BAEDF5D239D28CA989C6BB61AE0915EB42A4
5CC36FD8344783267EDE4C56E168641F7E137C0C51E4107453A2E19C29CD554F
AEDF0127717298D20CE1306BF938C6D0643DA19BB0BC19FCCEB58A93F9DC1354
C8307CD3832FE5078FC75587DE298EA5D14556CCEF381562C41BEC33BEF80888
B776A3A92630172DD344912B4AF69C1509B23568ABCA3ABED74F15D25C235C4E
E740F466AD092C3527CC4215A24AD327BF6D47E5ECE50D17F2A7D57AAE94F17F
4CBBAA3240C3A2E12F155C2F5B3024B921655CA85D1F6458 |-
/divide 89 -| 68CCB9B776D991366E178E99F717D2E9B9D9919128EA8C32B05EC9408CEF0C2D74B3BB33
93227B295721B33A0D04FB99988A034145083D9898E4D6F951AD7EBB10ACAE78
C3BC3E91C5179264D1E559BCD81702C89ACF9958E9 |-
/brokenbar 39 -| 68CCB9B776D67AED6D55087131F93FCD6B7A762E09B68D1AAF209DD4253D48AF5CF09A16
EB4E07 |-
/degree 75 -| 68CCB9B776D969F7E1248D54EE3B7B7ADA9C3D360A86D6B56340976E04EB9C9A7B7D855B
DEBE4E9C66256FCC7CF714FAE16B3CFF1D7874125716B98E2D8AA9C622EC7FF1
11FFA386AFFEA4 |-
/thorn 112 -| 68CCB9B776D98D0F46E41C44F4AD857D5464D5F938E223CD19AE289DFC584009E035B897
DC8283659F97C51AF69EF597BE8CBC3DB16FBEAF5FD0E6309FEB587ECAEE0D1B
CCB5250B4D3D3FC4590EB696D241C670F043CEF8DC6BCAB9B3A87C9F120293E2
F6F4D8BD9069CE11D22C6C11 |-
/threequarters 355 -| 68CCB9B776D8A9F625F1E2C0E48CF1978987529BCF6F0F23F257E8FB33A7297F25E5105A
ABDED9FAB17AEDE3FF8E19804A6EF69DC3F5BD9B3B3DC6AED1AA4DC7F6D90AFA
729DA2E9822F7E6B541008AD71DCDA7207B7B16C7EED6EACDFD965D35F83425B
088F5D9CBB5DD2A88A3F19EE6C93D1E509CEBF7C9F3C51A59BD5C406B7BFED6C
C3B192994B276B9ABC09B6A5ADDE56700CB896563C0F181566C3AB94F39DEFC9
C77EC6949CD93CC55E189416C0F3087AE302C0A3779206B0154AABB4935C9EB2
494119609A424483D9A4E6C50C06858672838D6336073850704A8B2B782C7630
CF2BC6A4F5C10D04EF6B6A0F64C33F654B83F272B1F2B4218FEC23B165692438
FCD9F2788E85741298199952B46B2A5FCB6352D1EDB2079945C261B905A18EAC
A22276AEE8D05CAE4893AA383A62F14816373C372306904813BE9C074EA9574F
EB72B53C0327E18CB6422FC7D2BBF47A7828E90AC5C762B4D14264575053DE |-
/twosuperior 97 -| 68CCB9B776D603E1D7A4F1135FA5F3B141FFAF488D1950A003063E5FA8518B76B4D33C45
4AF460BD8EAEA2C343EA397F6728569922A2013349FEA71F6B2BD8F1B9E382A3
297F22AB7CD538EC62B8D46494D6DCD697770DE4E530A09006945B7456 |-
/registered 180 -| 68CCB9B776D80AC8D259D6564195EF341AFA7A10A4BB286E90A49A62261B95B6D8BCE139
5B8338681F1936C1325FE570052A073622C9C7FED874E72E57787BC5136B877A
237CD294EEA883C1CB96C2B5D11255FBDD3BF91E6A8517DB3C174D7A504392C5
CAA2A6580627FD014A5A3DC03FC7FF37DB6F27E01ADF9D91B14C6205FB81D483
FB59E877793EF25F8171C12A8F1FC97DB3B37F9484C4542A8A1BDD3AF27F687A
804FBA542FD7D0F6A91DB1E289402CB1 |-
/eth 226 -| 68CCB9B776D98D0FC10FDB025C36B36668BD30F9B82531A6D767D25A1316DD3C1FD40FD9
4AC36A6B8AF77C6DEE5480B1877A148F9C814F870DA60FEDC1FC42C7BE4A6BF2
DE9642EDFA2B2760AC07E1ABA15BF6028A5B8E8A6E9670864635EDDEA9698E67
E5F8A5F13988AE7244C6B181733DB4B67A607FDDE0007B777FA9888771236195
AA29B4A2A10AF95071C670DAA1FA35ACDBAA17F75D10FC3FD0C45E15627A2147
E8C42CC07AA17222E0BC0FF9E42330A2A49E6433A996927B3C774BAFEC334D21
797C433CDCB8BC92CCF85FD8A48D227299A1535315423DF327DB5B6ADC71 |-
/multiply 69 -| 68CCB9B776D9913639D17DDC7E921225C57929E9C3110DC7BBC040C6F1A88C5F9ACB8D85
8317042905D7C7EE494F87DBEE55BBA396FA5A63B8943644E5AFD5D152951353
BC |-
/threesuperior 155 -| 68CCB9B776D603E1D7AB1BBA1D9301F569BB86969DADAA4E3944D3D3207337D29395DB4C
6BFF99C3B7A95B2B509B93E36CC34475E9DE0840DBB9AB6C910539B5276887D6
CF4BD39D2CC413FCF0C0F5A07A1B46BDEED109141AD90656533CE1271DAFAEEB
D02E7BBC1E34D56ED0D10D013C63CA39F7830D8C37ED26D3D6CBD35C675ADA9C
00126F2E31AE467CAE9AE0E9C347D3FBAB0C1B44DFAF8E |-
/copyright 177 -| 68CCB9B776D80AC8D259D6568BCF54A1C8FD8E1E7B0B6225AAF3F13DA66498BE8C7072A7
5EDDFC31120D2D436A7482F5256489BD885589D014CAA823BB56CC7B4CAD5E6B
708B82D72CE53AF330665B85AEE41751F7230C9FD15A8D1B7D9DB7BE41FCB351
64A2CE94DBEE0B6C3B0810418D5231C511FA3074AAC4D1798B2B198C0366F347
85E6051C527EC2028F99EE9AEF8C3BEC5A603BBBFB7184F5D232D5F548C72509
9904ECC507A9F81AF946F9D159 |-
/Aacute 111 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDD5BC3001375E20CB076B857A1473F6C73
06FC713DACCDFFD3BCB16846881F4F8356E202B726092F185EC3ECA2836E1B9E
2F889F3125D0C79C1BC5484626260F949DF645972F2E0BC6BC08BE2B99C1CD74
093775ECA4E43CCF30D521 |-
/Acircumflex 120 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDD5BC3001375E20CB076B857A1473F6C73
06FC713DACCDFFD3BCB16846881F4F8356E202B726092F185EC3ECA2836E1B9E
2F889F3125D0C79C1BC5484626260F949DF645972F2E0BC6BC08BE2BD59BB72C
76454C8B2AE184BCF31CE355562A5A4ED46AEC14 |-
/Adieresis 126 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDD409E0332EE7FDCD247E21E05BDAB4CD6
9AC7461C60E50A0843EEA497AD1E9249EBE9BB3BD4777BBB92187AF972B92C08
F1E2DE37C75F176B3E51EA1B71F7AD22157F2ED66CED05866FD0DEEE44A2BE5E
F5F4D84218AEF840D5CF5FF06735D32F1675EAE1871F6BB86154 |-
/Agrave 112 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDD5BC3001375E20CB076B857A1473F6C73
06FC713DACCDFFD3BCB16846881F4F8356E202B726092F185EC3ECA2836E1B9E
2F889F3125D0C79C1BC5484626260F949DF645972F2E0BC6BC08BE2BD58DFD72
A949C2D475F3DC379B7D7F83 |-
/Aring 236 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDECD08570161C1113025B91F272D1FC3EE
4B8BB3639093E1A113BD454F0AF6B85C0E09AD5F3B88FF6D8C74DC110EAB2833
297EFC5F42895C156224F685678A4F2456E442251DF3E0AEA4AEC362E067B85D
D3E50018532F8E9FB0B1CAB75F476945D689A24109EFA9DF7040B018DEDB3D3F
B15400F74954AE4121881AC7543EF4B6F77E977AE46C148233839EAD72A87193
60D281F6F87DF8FE5FA67857AA6658956E59DEEA774F6C081F276D0CA06298A9
495015AE58ECB297C7E609D612C2B0B04504FAF9EBA160601775A3B09D851359
15B574B5F07C392D |-
/Atilde 206 -| 68CCB9B776D8503AC2D60FFEDAA9A47D16DFAFDD129D75B65710956D486AC8412709D2CD
AD40BAE0587B0FFB07618EA2F2B371CF1AF9B70DC61255E272A44673461C83D9
F5A347187A27EEBD376555A8911FA044B0567286604EADD2A2BD1CB6CA0930F2
C7DA1E5A7645DE94A3D3EF034EF40CE76EDC44664701451490D7549AE5BB987E
320FCEB163140A6FC7CCEBB69E5D1228A19CFD11101A78682C831767764E4EA2
2262615D8A29AE7D593AE396E3075CA986B5FF482AC890E49DBE2CCB057B504E
1AD9A8C7051D97CF806D |-
/Ccedilla 168 -| 68CCB9B776D819D36F8513A4DEFB1EC9BA8B9498839A6A4DA418313258008B7A0DAB95F9
1199F207386DE886B440284CD70EABFCC4E155D8C2EB572A6E73A964D5EE9D09
D503FEDF5D3A04BD058B2C765E42F58F52C89F334D2AF1BF791194CF551F5953
330D101EA1AEB72EDD6EC0649573ECF3CF1E46C7FF9FC8538438596DB16A523A
5B32E1A50326A78DAE3FB4F1A385628264F98D5AAEED54600FCBCFE4B3363F8C
E047E624 |-
/Eacute 79 -| 68CCB9B776D8503AE9F3F72EE8E631C4A3171B4AE6B1927178D9B4FAF7E8166EAB61E998
CDEA9852185BF437AFD92BC0E4A28465627F965B4DC327FD6ED556CF8ACAF85E
47F762575A7C2B8DC689AB |-
/Ecircumflex 87 -| 68CCB9B776D8503AE9F3F72EE8E631C4A3171B4AE6B1927178D9B4FAF7E8166EAB61E998
CDEA9852185BF437AFD92BC0E4A28465627F965B4DC327FD6ED556CF33F366BF
A0C4A2702562E8C30998B8E303B8A13A84E7B5 |-
/Edieresis 118 -| 68CCB9B776D8503AE9F3F72EE8E631C4A3171B4AFD23133714F88889F073AEF9AF150433
68F6EE597A1BFD3431B504A6B744857A844A718C17E5CBE6F8469E612B4AF69A
275624F22B1D2EBC7BA636425C055932837019C897018F3F1AD6802C048DCD9B
2885FB55202DC304509F7A9EFCDB076814B2 |-
/Egrave 79 -| 68CCB9B776D8503AE9F3F72EE8E631C4A3171B4AE6B1927178D9B4FAF7E8166EAB61E998
CDEA9852185BF437AFD92BC0E4A28465627F965B4DC327FD6ED556CF59572CC4
966109FDBF77045DA7CF0D |-
/Iacute 51 -| 68CCB9B776D64882845DA0E9DBDF16545EAC2CB451EB0CFEEEE267C2D700A2EF4E6DE339
0853D8796EF2219F30696D434328A0 |-
/Icircumflex 59 -| 68CCB9B776D64882845DA0E9DBDF16545EAC2CB451EB0CFEEEE267C2D700A2EF4E6DE339
A1F26E3688DBBEFC827BFEFB2388D0FE045C9062552E45 |-
/Idieresis 78 -| 68CCB9B776D64882845DA0E9DBDF165445C2B7C743845AC8219AAC900009CE5395C8716D
863A76C376156DEEAED7829F5118DFD04096ADA722017FD6FE20E58903F38F00
A50BF0AD8CCA86817006 |-
/Igrave 51 -| 68CCB9B776D64882845DA0E9DBDF16545EAC2CB451EB0CFEEEE267C2D700A2EF4E6DE339
BFC09A87E6B794FF03B2F78B400AAC |-
/Ntilde 217 -| 68CCB9B776D819D3342B81E8E059C1D9703F090C55C0459C8D77A6A147D54E6835E2B0E9
AE9C393E19CDC0227ED594E761C08DE90C60C9220C6ED2E0778BFC9A1B73B3E3
08BC6F86E1489C1133DBFAE467C36418EBD4304FB704F9E04D6E8B82810586EC
C883A030423BF874D33C1DFE19FDCA3CBE3C331F79B55A7062FA1E89AFF8E652
9503BBCB7473AB91A8C185E45CBCEF73E53F94381AC807F6B5DA452B95E55584
D8A1F72FF0D03F2155228F3E3063EF1B91D6FC360AF955E89D8E7ED4AB41CE0C
3BDFBA7C089DB978797B4166EDB619DA31F3C87D7C |-
/Oacute 116 -| 68CCB9B776D8E12E5297D2D47702D2547125151CC0EB73B3949C65196BD064021B3D40BD
18D30559F80D267A230E0B14AC2AED6DDA18A621B16746FB9EADD1AB78371543
B0DD800A966929835867ABA59D0563B4FF52EE44A25F1B217E5D142C08A4DB05
3EC0F0628360270B65AFC29C7677B3D6 |-
/Ocircumflex 124 -| 68CCB9B776D8E12E5297D2D47702D2547125151CC0EB73B3949C65196BD064021B3D40BD
18D30559F80D267A230E0B14AC2AED6DDA18A621B16746FB9EADD1AB78371543
B0DD800A966929835867ABA59D0563B4FF52EE44A25F1B217E5D142C08A4DB05
3E6B8670DD816BF02CB81FFE03B3A3C2BCFBAB1E31A07ABD |-
/Odieresis 131 -| 68CCB9B776D8E12E5297D2D47702D2546ADC8A9F7D1835508BB2FFBD48B088ACA0CF5F41
A880304A2CD6F5FC4B05D0AEEB89535572F7127D5C3069B324CAB8DF5491593B
4B9CB29D18386863C710BC906F3560F9F1C0CF68D3D7293CEF43410194F26C38
739F8EAA978169EF1E4EA0DB4FA55CA7993D46941AA5AA9C47F9E5EA2247D2 |-
/Ograve 116 -| 68CCB9B776D8E12E5297D2D47702D2547125151CC0EB73B3949C65196BD064021B3D40BD
18D30559F80D267A230E0B14AC2AED6DDA18A621B16746FB9EADD1AB78371543
B0DD800A966929835867ABA59D0563B4FF52EE44A25F1B217E5D142C08A4DB05
39996AABF0B29F37BC66D0E3A8E74537 |-
/Otilde 210 -| 68CCB9B776D8E12E5297D2D47702D25465EFD8EB0394F22101337C6B43E1E513E3667160
C835902EA2516B43C42A4D204EA06F4EDF754FCE703D6F4B0E52A619E675344B
2E1DFB5731B3F38303313E70C2E8520F84BCF99F3604F24E3B71686E4F7332EC
16F328AE12F441AD6FCDD43F8FDF723AFD6D85FA033BD0300CFF15DD27A946A3
3C1AC84A32C181903049F6061A65FD01C57FC83AA44B1B14945F64D9E9ADACC2
486FE7B666601B22FEBD195A598AA943366D5CDAE8F59FE15E804671B0352DAC
C38D987424562235860B8446CD08 |-
/Scaron 206 -| 68CCB9B776D8503A1AF6868DB9E81A15F7AAFB9F92955A24880FCB36E1DDF46A1E252C9C
D5CE78F81B89BC2C883C461D5ABA8A2662754B37C543F92F641523B98C6CBF08
457C61E472FA0BB278D3E9937CBB4DCED0555B6778B3D6AADA01FCDAB5A0ABA2
515AA1D87D23D832B7EDA4121BB328699F41430F61C379E947559AEE91B7270D
0268F50206ACD9421BD9B9BFA3D96C00301073435632C4141D67DEB8D6D50D0D
0DADF4A6F8B9AD6C18992FC82C46DAB4FE02E7F40A59E707F5827D71702E1A55
163EB4B5E3C45CDA2063 |-
/Uacute 91 -| 68CCB9B776D819D3EC5DCCAF9A96C53C4A4EC570AFA480E765DBF9A6ACF3E8E24D46D9B1
59222891892646F7AB6681C6EB818E33749A3159D3AFC7292B4C310BE9AE6997
53868D8542E16705F75CA6C4EFD62A37864E5792D079CF |-
/Ucircumflex 99 -| 68CCB9B776D819D3EC5DCCAF9A96C53C4A4EC570AFA480E765DBF9A6ACF3E8E24D46D9B1
59222891892646F7AB6681C6EB818E33749A3159D3AFC7292B4C310BE9AE6997
53868D8542E167054E926AFBE57B359BD292ABEE3298D4C1F4369C1D6E8B66 |-
/Udieresis 106 -| 68CCB9B776D819D3EC5DCCAF9A96C53C51AF54A45923D31FDA7DC2D50A1FD122D3CC3F24
2A0C519AD12B9502E45D899AD4D522646FEE6B2D2D4C99BD2BECD087BBB469A1
62EC174B40FEB002132A83485A4E2EA5049884CFC27AE77F5E88F03FFCB2C9DD
C2A5AFC540F9 |-
/Ugrave 90 -| 68CCB9B776D819D3EC5DCCAF9A96C53C4A4EC570AFA480E765DBF9A6ACF3E8E24D46D9B1
59222891892646F7AB6681C6EB818E33749A3159D3AFC7292B4C310BE9AE6997
53868D8542E167052456B36B06655D9C3A2FFECE87D8 |-
/Yacute 76 -| 68CCB9B776D8503AC2D60FF017EE5981B8249E26524C0DF89FD46DD262D72D42FE8D6D71
918A34AC434214454170A9F32184AEE5B12E23DD0F86355A3C43D715139D3BAC
585C32C59AC3FB75 |-
/Ydieresis 104 -| 68CCB9B776D8503AC2D60FF017EE5981A315FD4DDB48BE0337C75CD7ABDFA42F55DD1AD8
802E75C7996625C4F7D04C0760AC28C6994C07C8FDEDAA78AA654B9DC9D0BD5D
BC1266290DD4F55BB89E84C1C3B9200109FDFADD744490638DC915B7FF0E15AE
E8B796E0 |-
/aacute 211 -| 68CCB9B776D98D0FC10C6FEDD76154BAC43F87E282427BA9CFF187A6EE09B80ACEEE3600
B2E0DC0087D9A441758268973E5D180F0AAE45FC6C0F53D45263BC0D676226E7
4E81EBA163D91A25219455B08C4A4C0088D94A80772F4BD2AA7F12DBE6C3FCE5
F494298899D4DA7A271583756AD641C13295717F70A32BBB8B7B5C39E2E00AA0
BEC6E4CB7645500D9B485A789EDB80151D4350526302543513F0B6A82C87F163
F973FB4D04959905D78AA4633577EB94640BDE3E970E07C65C7BCA7EF5D380F8
BC61BEC8276CC6A46BECC7A15A6FE6 |-
/acircumflex 239 -| 68CCB9B776D98D0FC10C6FEDD76154BAC43F87E282427BA9CFF187A6EE09B80ACEEE3600
B2E0DC0087D9A441758268973E5D180F0AAE45FC6C0F53D45263BC0D676226E7
4E81EBA163D91A25219455B08C4A4C0088D94A80772F4BD2AA7F12DBE6C3FCE5
F494298899D4DA7A271583756AD641C13295717F70A32BBB8B7B5C39E2E00AA0
BEC6E4CB7645500D9B485A789EDB80151D4350526302543513F0B7597A201E7F
454DA030F97AE67A0C82F4B62EF118993C2481426AFA4DBFB9640612ADF5036D
26333BE8BE910C81C44C8E50EABF3D9142C35EB5A30527BE7C6AFCFCF4DFE107
CA0D500A89869B2716B28C |-
/adieresis 268 -| 68CCB9B776D98D0FC10C6FEDD76154BAD1B23855A20CFC287E52A274C432550E67D95DA7
DDD28E757040E200DB49B34AC6882B6CF29C62CF88E48308837FF83FF5E1E2C6
77847D683865481E826890D73C241A5337E05D1EA88470CED5BEB6C5ABD8609A
C3867B2737FF1B80F58BCC3ADC3FF4ACDBAFC1D6B209E38DA7C46F47B5F74F52
54565E65954C1045482D09255DF80362B085A54C6F821E95708924D83C56B322
7631023B11C413D8BBF5F2F6338D3284F9E9D0473188860EE1C752054B75CBF4
BFB236F2940A81EC6FA56AC14D1A4475D7DA03C7CFB930D60912733EF3DCDE6B
7ED509C1AE0D5F2DADE48E68BE42E11AD9D354BE6DFFA048FFBA53F7BE783560
6B7B223AB44C7DF6 |-
/agrave 212 -| 68CCB9B776D98D0FC10C6FEDD76154BAC43F87E282427BA9CFF187A6EE09B80ACEEE3600
B2E0DC0087D9A441758268973E5D180F0AAE45FC6C0F53D45263BC0D676226E7
4E81EBA163D91A25219455B08C4A4C0088D94A80772F4BD2AA7F12DBE6C3FCE5
F494298899D4DA7A271583756AD641C13295717F70A32BBB8B7B5C39E2E00AA0
BEC6E4CB7645500D9B485A789EDB80151D4350526302543513F0B6A82C87F163
F973FB4D04959905D78AA4633577EB94640BDE3E970E07C65C7BCA7EF5D380F8
FD17954F524FB0A1B4720B424C2B92A7 |-
/aring 299 -| 68CCB9B776D98D0FC10C6FEDD76154BAF1A29E2B2C062291664BE92A88C21E04CDCE98E5
48B66EF5A293BD9B00098B007C28ACFE4D5E93904C76E78458D04860FB7C95B7
52AA87F61DCF283E6C2C921A9993F667623A28C65DAFA7616643D8B2B6ACB9E2
5A441E82B8781415C7FF4DD899358801C6239FD16929736BC2D27B2A413BA59D
6B244ABE68E14DDD4ABBFA24CA50300CA35A01F7806BB795514E2FFB238E4C24
180591FB5D1FDDF1C2A0E7128013F7F0865FB7AB6F192B08043965F771EC505F
853F7714FC0C35511254C8A63AF32CF25206EF71A32FB1B4ED0C6AA906512A8C
600284958C19C852B993B3E0F3712ABE653A2B3297B4399CCE2E2C15601000FA
BD3A2916BD00686B26087BEDB2086BA3EA72A3E93B2B12343040351C57A9982F
FDE8CFDB34500A |-
/atilde 319 -| 68CCB9B776D98D0FC10C6FEDD76154BAD822552BE76ED980A2FF82478D6CD0D1469B0BB9
5F2C9FB95744B049ED524A72B9A2ECF6FCB3D90A4E68BCB0BCC6700DA8E7B261
94BC752F76BDA0BEDCC68B70FFAD73A622D80F2FDB181E7EC4AFD6A56EB3BBA4
ED64CED725DEAB7A6A109BE284FFDF7A6AEA0ECC178898FC8B69FE4ABD2C8304
F5536A63D5BAB6AA63771EFC5D6CD59C43346EC3CCB49E610723F4E6EBC3DBD0
2F9CC43E2DC8D831D5B6B9BDF4BA679ED27225A0D95F85CE400F950005DB426B
52BBC3E0E6DA64E8EE5D117378032D3BAE4FB04CCD148E7831012DDF0CAED9AF
BC7FB877881A209B9C7896BBE21FC71C941E6E296A00320BEC901A5B2BCE64F2
B21BD2CA058CC6066FD1023D1ED3C50EB19F6973DB11B79D9FEADD0CEAF7527E
EC52371D947842B33D43A6A6DE935C72AECE9C54BB2ECDCCC6EB36 |-
/ccedilla 158 -| 68CCB9B776D9C52488A1432EF17A1F22A25C060A6AA2C256F9C4E9A54D8C571CF8134842
4B26D3E5C8E7869A2BF93F91295C3B0E04894B5F4A43FB8D8C16D9692F51FB86
F16F10DE9EF54F0966A7FB1D5F89099E3B17264EF51FE252B3E996FA4EB44F68
90E7D2E092FD2747AC34175BE33C443DEE45736ABC789F9DEC77947BD4BA7110
FE8908DABB3A81B1EA12E23407B8919169EFD1AF7EF84C4FC469 |-
/eacute 124 -| 68CCB9B776D98D0FC10FDB0D90A38EAA5F8ED354DA8A475D9752206573670F9393A446FF
1EFCE7E7841DBF25BC834488614516CEC97E09EB16A6AFB4BFC9F27EE7165200
71255FCB078E46DF71A5C7607DF98CECC3A530ED777B9DC56268A32CFC3DEDBA
B2CBF6D3BE261DBF8D256B44A7AC2165D49BEA7C1FEB79C4 |-
/ecircumflex 182 -| 68CCB9B776D98D0FC10FDB0D90A38EAA5F8ED354DA8A475D9752206573670F9393A446FF
1EFCE7E7841DBF25BC834488614516CEC97E09EB16A6AFB4BFC9F27EE7165200
71255FCB078E46DF71A5C7607DF98CECC3A530ED777B9DC56268A32CFC3DEDBA
B2CBF6D3BE261DBF0BEBAE7002A70B732C18B3D35C8742E8165B762E34C8D8AE
E56306AF18E8F2DD4703D2A69E4208C01E8B9CFFCD416E1D1F00BF1E2EA7150D
DDED7EBBA7B13ED5C3290F1D35360D6C217D |-
/edieresis 190 -| 68CCB9B776D98D0FC10FDB0D90A38EAA5F8ED354CF6E31E8F7A5571430EE337399B68AEA
043EAA8A9EF8441148E031AEA89094959ED24F5DCF23A4C8C8EA01ADC01A5E86
91408579732E51DD4730B425D9C0C45A7307A06CE1A97D63064AE74CA774FE68
E3AFA3A1AF83D70C38E2F1E66FC9B444E18E1BE9B67EABA978F678166BDE622B
9A6BCDF00349FBB3B6BF8A54DFC9F7CFD8A5A208843F8A48F1D2E1F292426FF2
333E7D0852F3CD28DBB95479615C1BC51E64458405E392CEB5DC |-
/egrave 125 -| 68CCB9B776D98D0FC10FDB0D90A38EAA5F8ED354DA8A475D9752206573670F9393A446FF
1EFCE7E7841DBF25BC834488614516CEC97E09EB16A6AFB4BFC9F27EE7165200
71255FCB078E46DF71A5C7607DF98CECC3A530ED777B9DC56268A32CFC3DEDBA
B2CBF6D3BE261DBF8D4F4CAA829380F5F74A06DC6935CDBCB0 |-
/iacute 52 -| 68CCB9B776D64882845DA0E87477DFE2C4936BCC336A03C5CBA2AA03A11F31E15938ABA7
96051450D21935958C675F283DB7EC8D |-
/icircumflex 92 -| 68CCB9B776D64882845DA0E87477DFE2C4936BCC336A03C5CBA2AA03A11F31E15938AB21
59A150A0998DCF615E41A6A9B5593B33D6C174659FF7E549C1832DB7E65B0F35
9B93B6A91D5A8D711B67EE62987D683E0205E59D585F9A22 |-
/idieresis 78 -| 68CCB9B776D64882845DA0E87477DFE2D12EB183565EA17B493EF5A848DF4DDC84F8AB60
E57B5E9EE0C9C15AED89150054E891C4C83D66CE427A9511D9B1DD9C932DF7E4
186E4528C49BC68D32C3 |-
/igrave 51 -| 68CCB9B776D64882845DA0E87477DFE2C4936BCC336A03C5CBA2AA03A11F31E15938ABA7
28AA4453636B1ECD78A4A60C9F8EBD |-
/ntilde 241 -| 68CCB9B776D98D0F1DEC23FD265E12736350A5355B46385AEC2F8606ACEA0130CCC7B8BE
AE4ED18160CE615D1FB234E0CE963FBEA74A9F4DB68935B4CA2787C0D116C623
FB09D1AFFE701BD74E84E306863521033B69A73A94809B68006498E1659E9984
63C814B34DBF231706EB5B19B87D6C37AE96A0E251DE4954B3ED45BD2E404DC8
44AA3271ABFB0ADA1B0D0AFA348D405F2CE8F1CF3677611534A7BE0EC8BD1C16
36CEEF1C7C772541FCCBF3CAEC0B0D04528AC1F096F2CFAE111FB5C91384A933
82B61971BAC9EF656018CE71015BA29E500BB6CBA2606C2940899AAF647CB1DE
087EBF84966993AA7B7DCE34CC |-
/oacute 111 -| 68CCB9B776D98D0FC0DE28BA6F649BDEE1BFEDDAB592D6FA4D25D7E2DF39F9F782F3A206
F12D4344AFFD2162684C41EAB896C79E627BC99B190865D5F75C15E0286EE839
78EEACACB4F5B71EF590387D20E4918487354D8491E55469545319CB95493B16
52CB95DC128AD1A29BFB19 |-
/ocircumflex 160 -| 68CCB9B776D98D0FC0DE28BA6F649BDEE1BFEDDAB592D6FA4D25D7E2DF39F9F782F3A206
F12D4344AFFD2162684C41EAB896C79E627BC99B190865D5F75C15E0286EE839
78EEACACB4F5B71EF590387D20E4918487354D8491E5546954539F4307383F67
EE4DDD3AF188870C9CD4040A38DA848ECB3BDCCFC7851C396B9CC47125621EC1
EDCE49551F92ABD28E628C111A0DC57D8BE1723DB27D434B595AB609 |-
/odieresis 168 -| 68CCB9B776D98D0FC0DE28BA6F649BDEF46AB64965F82C06A046987306DDEB9ECBE3D6F4
3F08543AE7FCE48D0B25DEB5234EEE803193B70B04AE2721DA0624AAC53ECFAA
6C16192C1F8A312CF4C7AF60C4CACBB7400FB5187B9CEA36BF879143FAB51604
85209FE50997082CC03AB662CA7B767F47C4F2DB5685883F2B715D696F1E4D5C
D6CD455F4A3A9004146CE93F69278D236F4B693C7C64481276232D458E1D0E47
8FE2B752 |-
/ograve 111 -| 68CCB9B776D98D0FC0DE28BA6F649BDEE1BFEDDAB592D6FA4D25D7E2DF39F9F782F3A206
F12D4344AFFD2162684C41EAB896C79E627BC99B190865D5F75C15E0286EE839
78EEACACB4F5B71EF590387D20E4918487354D8491E55469545319CB460A3B5D
0DEDFB3CDADA541E80ACBD |-
/otilde 213 -| 68CCB9B776D98D0FC0DE28BA6F649BDEFD1668A8020759BBB14A7FC753FB92A62965C251
A366C244522E048237D588FAFC68EAB00698B56DEE0FB70C058991352EFC53B3
7FD96734C331B8F43D20C3BA38FD618A3B1C82142F7572B5FCDB41D25ED7E573
A1F088D4ADB8FE2431E744DA5026A084B7E3A5D846EFC57075A8FB62D63B58EF
53919E0307146167A2FE6F09A9D877F2C5CBA8A7D598B24830B5EAED73F5D78C
E9C09B0F63EDAE92B41133F1C83982B150802755B5FCA4926D24029B210DBB0D
8D23F5F94C8CE0B41AA801BD73FFA2A0E0 |-
/scaron 149 -| 68CCB9B776D9C5240F95517258F2B5B8E864F7F16138A391A8C405325FAC6ADD6CB6D1F6
0D883C651683F1D562814EE35DBE111A5AF04693F1012DDE081B97F409D4DC67
6A5DC5B6ABF197D85DD050B2B208F4FAB0CC29E333396CF808A02F3165809E07
250F1F47712E55D2B2B67B39A2E793FE368CF5546CE6C0E24EF7862F5ABD686C
BF14A703B9FE3A36C51A9C93CC3779BBFC |-
/uacute 154 -| 68CCB9B776D98D0FC10FDB0290A72CB8630059AC94A8E8BF0CFE006FBA21070B98584A7E
ADA0A9BE685A3736FDF68A0D556A70B40E04D7C7D08E8B7CAB4C3464BB7ABD6A
83DED33829D030CB39D4E8957CB6F22B6DD499F561D3A21D29976A1DF752BEA6
0510497985763EC8140FB7791A47B4481717A5480C1ECD76FEBFE81C2B726B78
ED35207D308CCCE50718C465D47D07A61ECAB640FED5 |-
/ucircumflex 183 -| 68CCB9B776D98D0FC10FDB0290A72CB8630059AC94A8E8BF0CFE006FBA21070B98584A7E
ADA0A9BE685A3736FDF68A0D556A70B40E04D7C7D08E8B7CAB4C3464BB7ABD6A
83DED33829D030CB39D4E8957CB6F22B6DD499F561D3A21D29976A1DF752BEA6
0510497985763EC8140FB7791A47B4481717A5480C1ECD76FF6A8B3904B16197
0C62522BF63217EBE0AE191998828834152B4C292D41C37927C7C26E3D1F0F8E
58C5221665086FFF132C66E0CF4A782D125CD7 |-
/udieresis 180 -| 68CCB9B776D98D0FC10FDB0290A72CB876B84DB2E66221A0EAC943E69521D761570DEC83
E3940817865376D31FC7912A25751828B48E5DFF2D8C651A605680DCFA6F0488
B2AE1E3CE5C7CC8D503AF1BB1D33C957D906C8CB49EE0B64804C8F0E9D2BC0FE
55C48975CD047D3FA51D78CE96385D68D60653952FAA2ED649FA5449220C387A
0F4CBC6CA879C6BD28F8DC48011F3E9CB03487C4E8CEE42B792CF31869CF0337
B40FC686AF136A787E482998AAF7C0E9 |-
/ugrave 155 -| 68CCB9B776D98D0FC10FDB0290A72CB8630059AC94A8E8BF0CFE006FBA21070B98584A7E
ADA0A9BE685A3736FDF68A0D556A70B40E04D7C7D08E8B7CAB4C3464BB7ABD6A
83DED33829D030CB39D4E8957CB6F22B6DD499F561D3A21D29976A1DF752BEA6
0510497985763EC8140FB7791A47B4481717A5480C1ECD76FEBFE81C2B726B78
ED35207D308CCCBA78603381B481B2016B0599D1186DFB |-
/yacute 142 -| 68CCB9B776D9C52488BE81AAE652600D063E96449F5DCD688708604EDABB59EBF4CF3647
BA89A8612C1DB371FA3271AFB8C7B45487C0A3C78BAD255413E6729C08143CE6
D05D3D0091D22A2A528AC6C2916BA09EF152205D3598CF58511A3C9C122D08F1
10FA4A6FDCFD85BCA0C60D68B1183F59D946A570839D189F8DAF5F86883558AD
82CA521CBFBBE370579F |-
/ydieresis 160 -| 68CCB9B776D9C52488BE81AAE652600D062BFECDB8C1CD29E4DE8D41107C4033F2554C35
BD61D8BFF32C6664F7CD844A5711FABEA8A31F1300837E70F0F91CDD125333D4
A0A8C97A25025A0741CD078B999195661578B59D4A5BFEB78D2ADB28F4D5F7C3
C1C3B398723FD9C47C0636E856DAD2CDAE80F0C1D04236D4B04FA70802F88279
F8642875782B8BE6C50CE6467DFB58E3BC76F42960F280020A7106BC |-
end
end
put
put
dup/FontName get exch definefont pop
end
/BAAAAA+Helvetica findfont /Encoding get
dup 0 /.notdef put
pop
end
/BAAAAA+Helvetica findfont /Encoding get
dup 0 /.notdef put
dup 32 /space put
dup 33 /exclam put
dup 34 /quotedbl put
dup 35 /numbersign put
dup 36 /dollar put
dup 37 /percent put
dup 38 /ampersand put
dup 39 /quoteright put
dup 40 /parenleft put
dup 41 /parenright put
dup 42 /asterisk put
dup 43 /plus put
dup 44 /comma put
dup 45 /hyphen put
dup 46 /period put
dup 47 /slash put
dup 48 /zero put
dup 49 /one put
dup 50 /two put
dup 51 /three put
dup 52 /four put
dup 53 /five put
dup 54 /six put
dup 55 /seven put
dup 56 /eight put
dup 57 /nine put
dup 58 /colon put
dup 59 /semicolon put
dup 60 /less put
dup 61 /equal put
dup 62 /greater put
dup 63 /question put
dup 64 /at put
dup 65 /A put
dup 66 /B put
dup 67 /C put
dup 68 /D put
dup 69 /E put
dup 70 /F put
dup 71 /G put
dup 72 /H put
dup 73 /I put
dup 74 /J put
dup 75 /K put
dup 76 /L put
dup 77 /M put
dup 78 /N put
dup 79 /O put
dup 80 /P put
dup 81 /Q put
dup 82 /R put
dup 83 /S put
dup 84 /T put
dup 85 /U put
dup 86 /V put
dup 87 /W put
dup 88 /X put
dup 89 /Y put
dup 90 /Z put
dup 91 /bracketleft put
dup 92 /backslash put
dup 93 /bracketright put
dup 94 /asciicircum put
dup 95 /underscore put
dup 96 /quoteleft put
dup 97 /a put
dup 98 /b put
dup 99 /c put
dup 100 /d put
dup 101 /e put
dup 102 /f put
dup 103 /g put
dup 104 /h put
dup 105 /i put
dup 106 /j put
dup 107 /k put
dup 108 /l put
dup 109 /m put
dup 110 /n put
dup 111 /o put
dup 112 /p put
dup 113 /q put
dup 114 /r put
dup 115 /s put
dup 116 /t put
dup 117 /u put
dup 118 /v put
dup 119 /w put
dup 120 /x put
dup 121 /y put
dup 122 /z put
dup 123 /braceleft put
dup 124 /bar put
dup 125 /braceright put
dup 126 /asciitilde put
dup 161 /exclamdown put
dup 162 /cent put
dup 163 /sterling put
dup 165 /yen put
dup 166 /florin put
dup 167 /section put
dup 168 /currency put
dup 169 /quotesingle put
dup 170 /quotedblleft put
dup 171 /guillemotleft put
dup 172 /guilsinglleft put
dup 173 /guilsinglright put
dup 177 /endash put
dup 178 /dagger put
dup 179 /daggerdbl put
dup 180 /periodcentered put
dup 182 /paragraph put
dup 183 /bullet put
dup 184 /quotesinglbase put
dup 185 /quotedblbase put
dup 186 /quotedblright put
dup 187 /guillemotright put
dup 188 /ellipsis put
dup 189 /perthousand put
dup 191 /questiondown put
dup 193 /grave put
dup 194 /acute put
dup 195 /circumflex put
dup 196 /tilde put
dup 197 /macron put
dup 200 /dieresis put
dup 203 /cedilla put
dup 207 /caron put
dup 208 /emdash put
dup 225 /AE put
dup 227 /ordfeminine put
dup 233 /Oslash put
dup 234 /OE put
dup 235 /ordmasculine put
dup 241 /ae put
dup 245 /dotlessi put
dup 249 /oslash put
dup 250 /oe put
dup 251 /germandbls put
pop
%%EndResource
[/N5/BAAAAA+Helvetica 1 TZ
PDFVars/TermAll get exec end end

%%EndSetup
%%Page: 1 1
%%BeginPageSetup
userdict /pgsave save put
PDFVars begin PDF begin PDFVars/InitAll get exec
%%EndPageSetup
0 0 612 792 RC
EOF
}

sub emit_footer {
print <<EOF;
PDFVars/TermAll get exec end end
userdict /pgsave get restore
showpage
%%PageTrailer
%%EndPage
%%Trailer
%%DocumentProcessColors: Black
%%DocumentSuppliedResources:
%%+ font BAAAAA+Helvetica
%%+ procset (Adobe Acrobat - PDF operators) 1.2 0
%%+ procset (Adobe Acrobat - type operators) 1.2 0
%%EOF
EOF
}

