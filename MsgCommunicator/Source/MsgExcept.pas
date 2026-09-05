{$I MsgVer.inc}

unit MsgExcept;

interface

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgConst;

type


////////////////////////////////////////////////////////////////////////////////
//
// EMsgException
//
////////////////////////////////////////////////////////////////////////////////


  EMsgException = class( Exception )
  public
    NativeError: Integer;

    constructor Create(NativeErrorCode: Integer; ErrorMsg: AnsiString); overload;
    constructor Create(NativeErrorCode: Integer; ErrorMsg: AnsiString; const Args: array of const); overload;
  end; // EMsgException

implementation


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor EMsgException.Create(NativeErrorCode: Integer; ErrorMsg: AnsiString);
var
  ErMessage: AnsiString;
begin
  NativeError := NativeErrorCode;
  ErMessage := ErrorMsg;
  ErMessage := ErMessage + ' - Native error: '+ Format('%.5d',[NativeErrorCode]);
{$IFDEF DEBUG_TRACE_MSG_EXCEPTIONS}
aaWriteToLog('EMsgException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor EMsgException.Create(NativeErrorCode: Integer; ErrorMsg: AnsiString; const Args: array of const);
var
  ErMessage: AnsiString;
begin
  NativeError := NativeErrorCode;
  try
    ErMessage := Format(ErrorMsg, Args);
  except
    ErMessage := ErrorMsg + ' Arguments are invalid!';
  end;
  ErMessage := ErMessage + ' - Native error: ' + Format('%5d',[NativeErrorCode]);
{$IFDEF DEBUG_TRACE_MSG_EXCEPTIONS}
aaWriteToLog('EMsgException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgComBaseEngine> initialized');
{$ENDIF}

end.
