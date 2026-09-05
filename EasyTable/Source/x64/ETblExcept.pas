{$I ETblVer.inc}

unit ETblExcept;

interface

uses SysUtils, Classes;

type
  ETblException = class( Exception )
  public
    ErrorCode: Integer;
    NativeError: Integer;

    constructor Create(NativeErr: Integer; Component: TComponent = nil); overload;
    constructor Create(NativeErr: Integer; const Args: array of const; Component: TComponent); overload;
  end;

implementation

uses ETblConst;

constructor ETblException.Create(NativeErr: Integer; Component: TComponent = nil);
var
  ErMessage,s: AnsiString;
  i: integer;
begin
  NativeError := NativeErr;

  ErrorCode := ErUnknownError;
  for i := 0 to ETblMaxNativeError do
   if (ETblNativeToErrorCode[i][0] = NativeErr) then
    begin
     ErrorCode := ETblNativeToErrorCode[i][1];
     break;
    end;
  ErMessage := ETblErrorMessages[ErrorCode];
  if Assigned(Component) and (Component.Name <> '') then
   ErMessage := Format('%s: %s', [Component.Name, ErMessage]);

  s := StringReplace(Format('%5d',[NativeError]),' ','0',[rfReplaceAll]);
  ErMessage := ErMessage+' - Native error: '+s;
  inherited Create(ErMessage);
end;


constructor ETblException.Create(NativeErr: Integer;  const Args: array of const; Component: TComponent);
var
  ErMessage,s: AnsiString;
  i: integer;
begin
  NativeError := NativeErr;

  ErrorCode := ErUnknownError;
  for i := 0 to ETblMaxNativeError do
   if (ETblNativeToErrorCode[i][0] = NativeErr) then
    begin
     ErrorCode := ETblNativeToErrorCode[i][1];
     break;
    end;
  ErMessage := ETblErrorMessages[ErrorCode];
  ErMessage := Format(ErMessage, Args);
  if Assigned(Component) and (Component.Name <> '') then
   ErMessage := Format('%s: %s', [Component.Name, ErMessage]);

  s := StringReplace(Format('%5d',[NativeError]),' ','0',[rfReplaceAll]);
  ErMessage := ErMessage+' - Native error: '+s;
  inherited Create(ErMessage);
end;

end.
