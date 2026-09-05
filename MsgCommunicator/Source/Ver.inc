{$A+,B-,E-,F-,G+,H+,I-,J+,K-,N+,P+,Q-,R-,S-,T-,V+,W-,X+,Y-}

{.$DEFINE 486GE}   // Assembler Core only for >= 486 CPU
{$IFNDEF X64_ON}
 {$DEFINE UseASM}   // use Assembler optimated core
{$ENDIF}

{.$DEFINE ManualRegisterClasses} // all Cipher- and Hashclasses must be manual register

{$IFDEF VER80}  { Delphi 1.0     }
  {$DEFINE VER_D1}
{$ENDIF}

{$IFDEF VER90}  { Delphi 2.0     }
  {$DEFINE VER_D2}
{$ENDIF}

{$IFDEF VER100} {Borland Delphi 3.0 }
  {$DEFINE VER_D3}
{$ENDIF}

{$IFDEF VER120} {Borland Delphi 4.0 }
  {$DEFINE VER_D4}
{$ENDIF}

{$IFDEF VER93}  { Borland C++Builder 1.0 }
  {$DEFINE VER_BCB1}
{$ENDIF}

{$IFDEF VER110} { Borland C++Builder 3.0 }
  {$DEFINE VER_BCB3}
{$ENDIF}

{$IFNDEF VER80}           { Delphi 1.0     }
 {$IFNDEF VER90}          { Delphi 2.0     }
  {$IFNDEF VER93}         { C++Builder 1.0 }
    {$DEFINE VER_D3H}     { Delphi 3.0 or higher }
    {$IFNDEF VER100}
      {$DEFINE VER_BCB3H} { C++Builder 3.0 or higher }
      {$IFNDEF VER110}
        {$DEFINE VER_D4H} { Delphi 4.0 or higher }
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
 {$ENDIF}
{$ENDIF}

