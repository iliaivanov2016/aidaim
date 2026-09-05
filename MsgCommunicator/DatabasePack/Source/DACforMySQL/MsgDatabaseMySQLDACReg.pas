unit MsgDatabaseMySQLDACReg;

{$I MsgDBMySQLDACVer.inc}

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
, MsgDatabaseMySQLDAC
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register started');
{$ENDIF}

RegisterComponents('MsgCommunicator', [TMsgDatabaseMySQLDAC]);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseMySQLDACReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseMySQLDACReg initialization');
{$ENDIF}

end.
