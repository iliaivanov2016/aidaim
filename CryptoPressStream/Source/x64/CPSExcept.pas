{$I CPSVer.inc}

unit CPSExcept;

interface

uses SysUtils, Classes,
 {$IFDEF DEBUG_LOG}
     CPSDebug,
 {$ENDIF}
     CPSConst;

type


////////////////////////////////////////////////////////////////////////////////
//
// ECPSException
//
////////////////////////////////////////////////////////////////////////////////


  ECPSException = class( Exception )
  public
    NativeError: Integer;

    constructor Create(NativeErrorCode: Integer; ErrorMsg: AnsiString); overload;
    constructor Create(NativeErrorCode: Integer; ErrorMsg: AnsiString; const Args: array of const); overload;
  end; // ECPSException

implementation


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor ECPSException.Create(NativeErrorCode: Integer; ErrorMsg: AnsiString);
var
  ErMessage: AnsiString;
begin
  NativeError := NativeErrorCode;
  ErMessage := ErrorMsg;
  ErMessage := ErMessage + ' - Native error: '+ Format('%.5d',[NativeErrorCode]);
  inherited Create(ErMessage);
end; // Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor ECPSException.Create(NativeErrorCode: Integer; ErrorMsg: AnsiString; const Args: array of const);
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
  inherited Create(ErMessage);
end; // Create

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSBaseEngine> initialized');
{$ENDIF}

end.
