unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, constSQL, constODBC;

type
  TForm1 = class(TForm)
    OK: TButton;
    ToDo: TRadioGroup;
    procedure OKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  lpStr = pChar;
  lpcStr = pChar;

var
  Form1: TForm1;
  ErrorTxt : string;

Const
  _MAX_PATH : Cardinal = 260; //stdlib.h
  SQL_MAX_MESSAGE_LENGTH : Cardinal = 512; //SQL.H

Procedure ShowErrorMassage;

Function SQLInstallDriverManager(
            lpszPath:lpStr;
            cbPathMax:Word;
            var pcbPathOut:Word
                            ):Boolean;stdcall;far;

Function SQLRemoveDriverManager(
            var lpdwUsageCount:DWord
                            ):Boolean;stdcall;far;

Function SQLInstallDriverEx(
            lpszDriver:lpcStr;
            lpszPathIn:lpcStr;
            lpszPathOut:lpStr;
            cbPathOutMax:Word;
            var pcbPathOut:Word;
            fRequest:Word;
            var lpdwUsageCount:DWord
                            ):Boolean;stdcall;far;

Function SQLRemoveDriver(
            lpszDriver:lpcStr;
            fRemoveDSN:Boolean;
            var lpdwUsageCount:DWord
                            ):Boolean;stdcall;far;

Function SQLConfigDriver(
            hwndParent:hwnd;
            fRequest:Word;
            lpszDriver:lpcStr;
            lpszArgs:lpcStr;
            lpsMsg:lpStr;
            cbMsgMax:Word;
            var pcbMsgOut:Word
                            ):Boolean;stdcall;far;

Function SQLInstallerError(
            iError:Word;
            var pfErrorCode:DWord;
            lpszErrorMsg:lpStr;
            cbErrorMsgMax:Word;
            var pcbErrorMsg:Word
                            ):Smallint;stdcall;far;

implementation
{$R *.DFM}

Function SQLInstallDriverManager(
            lpszPath:lpStr;
            cbPathMax:Word;
            var pcbPathOut:Word
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLRemoveDriverManager(
            var lpdwUsageCount:DWord
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLInstallDriverEx(
            lpszDriver:lpcStr;
            lpszPathIn:lpcStr;
            lpszPathOut:lpStr;
            cbPathOutMax:Word;
            var pcbPathOut:Word;
            fRequest:Word;
            var lpdwUsageCount:DWord
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLRemoveDriver(
            lpszDriver:lpcStr;
            fRemoveDSN:Boolean;
            var lpdwUsageCount:DWord
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLConfigDriver(
            hwndParent:hwnd;
            fRequest:Word;
            lpszDriver:lpcStr;
            lpszArgs:lpcStr;
            lpsMsg:lpStr;
            cbMsgMax:Word;
            var pcbMsgOut:Word
                            ):Boolean;far;external 'odbccp32.dll'

Function SQLInstallerError(
            iError:Word;
            var pfErrorCode:DWord;
            lpszErrorMsg:lpStr;
            cbErrorMsgMax:Word;
            var pcbErrorMsg:Word
                            ):Smallint;far;external 'odbccp32.dll'

procedure TForm1.OKClick(Sender: TObject);
{$H+} // 4 bytes to 2GB	8-bit (ANSI) characters
var
  Path                  : PChar;
  PathSize              : Word;
  bOk                   : Boolean;
  DriverName, ConfigArgs: PChar;
  DriverPath            : PChar;
  UsageCount            : DWord;
  fRequest              : Word;
  fRemoveDSN            : Boolean;
  MsgMax                : Word;
  MsgLength             : Word;
  ConfigMsg             : PChar;
  i                     : Byte;
  buf: array[0..255] of char;
  buf2: array[0..255] of char;
Const
  Error : String = 'Installation failed!'+#13+#10;
begin
  Path:=AllocMem(_MAX_PATH+1);
  ConfigMsg:=AllocMem(SQL_MAX_MESSAGE_LENGTH);

// Install constants
  buf:='EasyTable_Driver=eodbc.dll__';
  DriverName:=pchar(@buf);
  for i:=0 to 255 do if buf[i]='_' then buf[i]:=#0;
  DriverPath:=PChar(GetCurrentDir);

// Config constants
  buf2:='ConnectFunctions=YYN_'; {SQLConnect/SQLDriverConnect/SQLBrowseConnect}
  ConfigArgs:=pchar(@buf2);
  for i:=0 to 255 do if buf2[i]='_' then buf2[i]:=#0;
  MsgMax:=4096;

  if Form1.ToDo.ItemIndex=0 then
  // install driver
  begin
//    bOk := true;
    repeat
//  SQLInstallDriverManager
     try
       PathSize := _MAX_PATH;
       bOk := SQLInstallDriverManager(Path,_MAX_PATH,PathSize);
     except
       bOk := false;
     end;
    if (not bOk) then  // failed
     begin
       ErrorTxt:=Error+'SQLInstallDriverManager has returned error(s):';
       ShowErrorMassage;
       break; // repeat
     end;
//  SQLInstallDriverEx
   fRequest:=ODBC_INSTALL_COMPLETE;
   PathSize := _MAX_PATH;
     try
       bOk := SQLInstallDriverEx(DriverName,
                                 DriverPath,
                                 Path,
                                 _MAX_PATH,
                                 PathSize,
                                 fRequest,
                                 UsageCount);
     except
       bOk := false;
     end; // except
    if (not bOk) then  // failed
     begin
       ErrorTxt:=Error+'SQLInstallDriverEx has returned error(s):';
       ShowErrorMassage;
       break; // repeat
     end;
//  SQLConfigDriver
    fRequest:=ODBC_CONFIG_DRIVER;
     try
       bOk := SQLConfigDriver(0,
                              fRequest,
                              DriverName,
                              ConfigArgs,
                              ConfigMsg,
                              MsgMax,
                              MsgLength);
     except
       bOk := false;
     end;
    if (not bOk) then  // failed
     begin
       ErrorTxt:=Error+'SQLConfigDriver has returned error(s):';
       ShowErrorMassage;
       break; // repeat
     end;
//  SQLInstallTranslatorEx

    until (bOK);
    if bOK then
      showmessage('ODBC driver successfully installed');
  end // Install (ItemIndex=0)
  else // UnInstall (ItemIndex=1)
    begin
  // uninstall driver
//    bOk := true;
    repeat
//  SQLRemoveTranslator

//  SQLRemoveDriver
      fRemoveDSN:=FALSE;
      if MessageDlg('Would you like to remove DSNs associated with '+#13+#10+
                    'the EasyTable ODBC Driver as well?', mtConfirmation,[mbYes,mbNo],0)
        =mrYes then fRemoveDSN:=True;
      try
       bOk := SQLRemoveDriver(
                              DriverName,
                              fRemoveDSN,
                              UsageCount
                               );
     except
       bOk := false;
     end;
    if (not bOk) then  // failed
     begin
       if UsageCount=0
        then
          begin
           ErrorTxt:='Setup can not remove the driver'+#13+#10+
                     'because it is not installed.';
           MessageDlg(ErrorTxt, mtError,[mbOk],0);
          end
        else
          begin
            ErrorTxt:=Error+'SQLRemoveDriver has returned error(s):';
            ShowErrorMassage;
          end;
       break; // repeat
     end;

//  SQLRemoveDriverManager
      try
       bOk := SQLRemoveDriverManager(UsageCount);
      except
       bOk := false;
      end;
    if (not bOk) then  // failed
     begin
       ErrorTxt:=Error+'SQLRemoveDriverManager has returned error(s):';
       ShowErrorMassage;
       break; // repeat
     end;

      until (bOK);
      if bOK then
        showmessage('ODBC driver successfully uninstalled');
    end; //if
    FreeMem(ConfigMsg);
    FreeMem(Path);
end;

Procedure ShowErrorMassage;
  var
    ErrorMsg       : PChar;
    iError         : word;
    pfErrorCode    : dword;
    ErrorLength    : Word;
    ErrorBufferSize: Cardinal;
{
const
    ErrorBufferSize: Cardinal = 2048;
}
  begin
   ErrorBufferSize:=SQL_MAX_MESSAGE_LENGTH;
   ErrorMsg:=AllocMem(ErrorBufferSize);
   for iError:=1 to 8 do
     begin
       ErrorMsg^:=#0;
       Case
       SQLInstallerError(iError,
                         pfErrorCode,
                         ErrorMsg,
                         ErrorBufferSize,
                         ErrorLength)
       of
       SQL_NO_DATA:
          begin
            if iError=1 then
                               ErrorTxt:=ErrorTxt+#13+#10+'- Unknown error';
            break; // for
          end;
       SQL_ERROR:             ErrorTxt:=ErrorTxt+#13+#10+'- Unknown error';
       SQL_SUCCESS:           ErrorTxt:=ErrorTxt+#13+#10+'- '+ErrorMsg;
       SQL_SUCCESS_WITH_INFO: ErrorTxt:=ErrorTxt+#13+#10+'- '+IntToStr(pfErrorCode); //It's unworked-?
       end; // Case
     end; // for
   ErrorTxt:=ErrorTxt+'.';
   MessageDlg(ErrorTxt, mtError,[mbOk],0);
   FreeMem(ErrorMsg);
  end;

end.
