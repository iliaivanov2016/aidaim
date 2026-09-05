{$IFDEF MSWINDOWS}

{$IFDEF X64_ON}
 {$LINK .\ppmdi\x64\ppmdlib.c.obj}
 {$LINK .\ppmdi\x64\Ppmd8.c.obj}
 {$LINK .\ppmdi\x64\Ppmd8Enc.c.obj}
 {$LINK .\ppmdi\x64\Ppmd8Dec.c.obj}
{$ELSE}
 {$LINK ppmdi\ppmdlib.c.obj}
 {$LINK \ppmdi\Ppmd8.c.obj}
 {$LINK ppmdi\Ppmd8Enc.c.obj}
 {$LINK ppmdi\Ppmd8Dec.c.obj}
{$ENDIF}

{$ELSE} //Not MSWindows

{$LINK .\ppmdi\unix\ppmdlib.c.o}
{$LINK .\ppmdi\unix\Ppmd8.c.o}
{$LINK .\ppmdi\unix\Ppmd8Dec.c.o}
{$LINK .\ppmdi\unix\Ppmd8Enc.c.o}

{$ENDIF}