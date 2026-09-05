{******************************************************************************}
{                                                                              }
{                            MsgCommunicator                                   }
{                                                                              }
{ Copyright (c) 2004-2021 AidAim Software                                      }
{                                                                              }
{  web-site: https://aidaim.com                                                }
{  e-mail:   support@aidaim.com                                                }
{                                                                              }
{******************************************************************************}

{$HINTS OFF}
{$WARNINGS OFF}

unit MsgCommunicator;

interface

{$I MsgVer.inc}

uses SysUtils, Classes, IniFiles,
     Dialogs,
{$IFDEF MSWINDOWS}
     Windows, Forms, Controls,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     Messages,
     QForms,
{$ENDIF}


{$IFDEF TRIAL_VERSION}
 {$IFDEF MSWINDOWS}
     Registry, MsgDECUtil, MsgCipher,
 {$ENDIF}
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
//  MsgCommunicator units
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF LINUX}
     MsgLinux,
{$ENDIF}


{$IFDEF DEBUG_MEMCHECK}
     MemCheck,
{$ENDIF}

     MsgComMain,
{$IFDEF CLIENT_VERSION}
     MsgClient,
{$ENDIF}
{$IFDEF SERVER_VERSION}
     MsgServer,
{$ENDIF}
     MsgCrypto,
     MsgCompression,
     MsgTypes,
     MsgExcept,
     MsgConst,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgMemory;       // UNIT MsgMemory MUST BE LAST !!!


{$IFDEF LINUX}
type
  // Delphi7 Controls.pas
  TDate = type TDateTime;
  TTime = type TDateTime;
{$ENDIF}

{$IFDEF TRIAL_VERSION}
procedure msgtrshnm;
{$ENDIF}

implementation

uses
  Math;

var
{
  FCSect:                TRTLCriticalSection;
  CurrentSessionManager: TMsgSessionComponentManager;
  Session:               TMsgSession;
  Initialized:           Boolean;
}
  IsDesignMode:          Boolean;

{$IFDEF TRIAL_VERSION}
procedure msgtrshnm;
var capt, msg: String;
begin
{$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
 Exit;
{$ENDIF}
capt := 'MsgCommunicator Trial Version - v.'+FormatFloat('0.00',MsgVersion) + ' '+ MsgVersionText;
msg :=
              'This is the trial version of MsgCommunicator by'#13+
             'AidAim Software (c) 2000-2025.'#13+
             'Web site: https://aidaim.com'#13#13+

             'Limitations of this trial version: '#13+
             '- maximum number of clients is '+IntToStr(MsgMaxSingleUserConnections)+'.'#13+

						 'This screen is created to remind you that your trial version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this product at https://aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at https://aidaim.com/help_osticket/';
{$IFDEF D12H}
MessageBoxW(0,PChar(@msg[1]),PChar(@capt[1]),
{$ELSE}
MessageBoxA(0,PAnsiChar(@msg[1]),PAnsiChar(@capt[1]),
{$ENDIF}
{$IFDEF MSWINDOWS}
		 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1
{$ENDIF}
{$IFDEF LINUX}
     [smbOK], smsInformation
{$ENDIF}
);
end;

//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function MsgWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
          stdcall;
{This function is called once for each window}
 Var MyString : PAnsiChar;
begin

    {Window text}
    MyString := Allocmem(255);
    GetWindowTextA(WHandle,MyString,255);
    TStringList(Parm).Add(MyString);
    FreeMem(MyString,255);
    Result := True; {Everything's okay. Continue to enumerate windows}
end;
{$ENDIF}


initialization
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCommunicator> initialization started');
{$ENDIF}

  {$IFDEF DEBUG_MEMCHECK}
  MemChk;
  {$ENDIF}

  IsDesignMode := False;

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCommunicator> initialization finished');
{$ENDIF}

finalization

end.
