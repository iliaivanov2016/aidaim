unit MsgDatabaseParadoxReg;

{$I MsgDBVer.inc}

interface

// register MsgCommunicator Database Connection component in group MsgCommunicator
procedure Register; 

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
, MsgDatabaseParadox
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register started');
{$ENDIF}

RegisterComponents('MsgCommunicator', [TMsgDatabaseParadox]);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseParadoxReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseParadoxReg initialization');
{$ENDIF}

end.
