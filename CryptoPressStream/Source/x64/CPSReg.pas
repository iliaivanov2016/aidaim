unit CPSReg;

{$I CPSVer.inc}

interface

uses
 Classes, TypInfo,
 {$IFDEF D6H}
  DesignIntf, DesignEditors,
 {$ELSE}
  DSGNINTF,
 {$ENDIF}
{$IFDEF MSWINDOWS}
  Controls,
  FileCtrl,
  Forms,
  Windows,
{$ENDIF}
// CPS units
 {$IFDEF DEBUG_LOG}
   CPSDebug,
 {$ENDIF}
  CPSMain;

{$IFDEF MSWINDOWS}
 type
 // file open dialog - for selecting table name
 TDirectoryProperty = class (TStringProperty)
   public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
   end; //TDirectoryProperty
{$ENDIF}

procedure Register; // register Accuracer components in group Accuracer

implementation


{$IFDEF MSWINDOWS}
//------------------------------------------------------------------------------
// file name editor (extension is subtracted from name)
//------------------------------------------------------------------------------
procedure TDirectoryProperty.Edit;
var s: String;
begin
 s := GetStrValue;
 if (SelectDirectory('Select directory...','',s)) then
  SetStrValue(s);
end; // TDirectoryProperty.Edit


//------------------------------------------------------------------------------
// file name editor's attributes (paDialog - for ... button in design mode)
//------------------------------------------------------------------------------
function TDirectoryProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end; //TDirectoryProperty.GetAttributes


{$ENDIF}

//------------------------------------------------------------------------------
// registration
//------------------------------------------------------------------------------
procedure Register;
begin
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSReg.Register started');
{$ENDIF}

  RegisterComponents('CryptoPressStream', [TCPSManager]);
{$IFDEF MSWINDOWS}
  RegisterPropertyEditor(TypeInfo(string), TCPSManager, 'TempDir',
      TDirectoryProperty);
{$IFDEF D12H}
  RegisterPropertyEditor(TypeInfo(string), TCPSManager, 'TempDirUnicode',
      TDirectoryProperty);
{$ELSE}
  RegisterPropertyEditor(TypeInfo(string), TCPSManager, 'TempDirAnsi',
      TDirectoryProperty);
{$ENDIF}
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSReg.Register finished');
{$ENDIF}
end; // Register

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('CPSReg initialization');
{$ENDIF}

end.
