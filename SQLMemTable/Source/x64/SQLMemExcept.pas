{$I SQLMemVer.inc}

unit SQLMemExcept;

interface

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     SQLMemDebug,
 {$ENDIF}
     SQLMemConst;

type


////////////////////////////////////////////////////////////////////////////////
//
// ESQLMemException
//
////////////////////////////////////////////////////////////////////////////////


  ESQLMemException = class( Exception )
  public
    NativeError: Integer;

    constructor Create(NativeErrorCode: Integer; ErrorMsg: WideString); overload;
    constructor Create(NativeErrorCode: Integer; ErrorMsg: WideString; const Args: array of const); overload;
  end; // ESQLMemException

implementation


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor ESQLMemException.Create(NativeErrorCode: Integer; ErrorMsg: WideString);
var
  ErMessage: WideString;
begin
  NativeError := NativeErrorCode;
  ErMessage := ErrorMsg;
  ErMessage := ErMessage + ' - Native error: '+ Format('%.5d',[NativeErrorCode]);
{$IFDEF DEBUG_TRACE_ALL_SQLMem_EXCEPTIONS}
  aaWriteToLog('ESQLMemException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor ESQLMemException.Create(NativeErrorCode: Integer; ErrorMsg: WideString; const Args: array of const);
var
  ErMessage: WideString;
begin
  NativeError := NativeErrorCode;
  try
    ErMessage := Format(ErrorMsg, Args);
  except
    ErMessage := ErrorMsg + ' Arguments are invalid!';
  end;
  ErMessage := ErMessage + ' - Native error: ' + Format('%.5d',[NativeErrorCode]);
{$IFDEF DEBUG_TRACE_ALL_SQLMem_EXCEPTIONS}
  aaWriteToLog('ESQLMemException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemBaseEngine> initialized');
{$ENDIF}

end.
