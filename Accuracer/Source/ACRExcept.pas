{$I ACRVer.inc}

unit ACRExcept;

interface

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRConst;

type


////////////////////////////////////////////////////////////////////////////////
//
// EACRException
//
////////////////////////////////////////////////////////////////////////////////


  EACRException = class( Exception )
  public
    NativeError: Integer;

    constructor Create(NativeErrorCode: Integer; ErrorMsg: WideString); overload;
    constructor Create(NativeErrorCode: Integer; ErrorMsg: WideString; const Args: array of const); overload;
  end; // EACRException

implementation


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor EACRException.Create(NativeErrorCode: Integer; ErrorMsg: WideString);
var
  ErMessage: WideString;
begin
  NativeError := NativeErrorCode;
  ErMessage := ErrorMsg;
  ErMessage := ErMessage + ' - Native error: '+ Format('%.5d',[NativeErrorCode]);
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
  aaWriteToLog('EACRException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor EACRException.Create(NativeErrorCode: Integer; ErrorMsg: WideString; const Args: array of const);
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
{$IFDEF DEBUG_TRACE_ALL_ACR_EXCEPTIONS}
  aaWriteToLog('EACRException: '+#13#10+ErMessage);
{$ENDIF}
  inherited Create(ErMessage);
end; // Create

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRBaseEngine> initialized');
{$ENDIF}

end.
