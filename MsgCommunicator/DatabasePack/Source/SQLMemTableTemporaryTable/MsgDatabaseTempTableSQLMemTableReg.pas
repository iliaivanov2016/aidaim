unit MsgDatabaseTempTableSQLMemTableReg;

{$I MsgDBVer.inc}

interface

// register MsgCommunicator Temp Table via SQLMemTable component in group MsgCommunicator
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
, MsgDatabaseTempTableSQLMemTable
      ;

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgReg.Register started');
{$ENDIF}

RegisterComponents('MsgCommunicator', [TMsgTempTableSQLMemTable]);

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseTempTableSQLMemTableReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseTempTableSQLMemTableReg initialization');
{$ENDIF}

end.
