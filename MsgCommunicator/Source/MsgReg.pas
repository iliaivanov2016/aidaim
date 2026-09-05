unit MsgReg;

{$I MsgVer.inc}

interface

procedure Register; // register MsgCommunicator components in group MsgCommunicator

implementation

uses  Classes, TypInfo,
{$IFDEF MSWINDOWS}
      Controls,
{$ENDIF}
{$IFDEF D6H}
      DesignIntf       
 {$ELSE}
      Dsgnintf
 {$ENDIF}
// MsgCommunicator units
 {$IFDEF DEBUG_LOG}
      ,MsgDebug
 {$ENDIF}
{$IFDEF CLIENT_VERSION}
      ,MsgClient
{$ENDIF}
{$IFDEF SERVER_VERSION}
      ,MsgServer
{$ENDIF}
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register started');
{$ENDIF}

{$IFDEF CLIENT_VERSION}
  RegisterComponents('MsgCommunicator', [TMsgClient]);
{$ENDIF}
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register 1');
{$ENDIF}
{$IFDEF SERVER_VERSION}
  RegisterComponents('MsgCommunicator', [TMsgServer]);
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg initialization');
{$ENDIF}

end.
