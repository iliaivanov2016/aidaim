unit uTestList;

{$I CPSVER.Inc}

interface

uses
{$IFNDEF CONSOLE}
  MainForm,
{$ENDIF}
  classes, forms, shellapi, windows, sysutils
{$IFNDEF D6H}
, FileCtrl
{$ENDIF}
;

Type
  TestAction = procedure of object;
  TTestList = class;

  TUnitTest = class(TObject)
   private
    FUTList: TTestList;
    FAppDir: AnsiString;
   private
    function GetTempDir: AnsiString;
   protected
    procedure WriteToProcessLog(Text: AnsiString);
    procedure WriteToErrorLog(Text: AnsiString);
   public
    procedure CheckAction(test: TestAction; const TestName: AnsiString);
    constructor Create(UnitTestList: TTestList);
    procedure TestAll;
    procedure TestShort; virtual;
    procedure TestLong; virtual;
    procedure TestExceptions; virtual;
   public
    property TempDir: AnsiString read GetTempDir;
    property AppDir: AnsiString read FAppDir;
  end;


  TTestList = class(TObject)
   private
    FTempDir:             AnsiString;
    FErrorLogFileName:    AnsiString;
    FProcessLogFileName:  AnsiString;
    FUnitTests:           TList;
   private
    procedure WriteToLog(const LogFileName: AnsiString; const Text: AnsiString);
   public
    constructor Create;
    destructor Destroy; override;
    procedure TestAll;
    procedure TestShort;
    procedure TestLong;
    procedure TestExceptions;
    procedure AddUnitTestToList(Test: TUnitTest);
    procedure WriteToProcessLog(Text: AnsiString);
    procedure WriteToErrorLog(Text: AnsiString);
   public
    property TempDir: AnsiString read FTempDir;
    property ErrorLogFileName: AnsiString read FErrorLogFileName;
    property ProcessLogFileName: AnsiString read FProcessLogFileName;
  end;

var
  UnitTestList: TTestList;

implementation


{ TTestList }

procedure TTestList.AddUnitTestToList(Test: TUnitTest);
begin
  FUnitTests.Add(Test);
end;

constructor TTestList.Create;
var
   RootDir: AnsiString;
   LogsDir: AnsiString;
   TempDir: AnsiString;
   errText: array [1..255] of byte;
   pc: PAnsiChar absolute errText;

  SEInfo: TShellExecuteInfoA;

begin
  FUnitTests := TList.Create;

  RootDir := ExtractFilePath(Application.ExeName);
  LogsDir := RootDir + 'Logs';
  TempDir := RootDir + 'Temp';

  FTempDir := TempDir + '\';
  FErrorLogFileName := LogsDir + '\error_log.txt';
  FProcessLogFileName := LogsDir + '\process_log.txt';

  // Clear logs
  if (not DirectoryExists(LogsDir)) then
    CreateDir(LogsDir);
//  ForceDirectories(LogsDir);
  DeleteFile(FErrorLogFileName);
  DeleteFile(FProcessLogFileName);

  // Empty TempDir
  FillChar(SEInfo, SizeOf(SEInfo), 0);
  SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  with SEInfo do begin
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd := Application.Handle;
    lpFile := PAnsiChar('cmd');
    lpParameters := PAnsiChar('/c rmdir /s /q ' + TempDir);
    nShow := SW_HIDE;
  end;
  if ShellExecuteEx(@SEInfo) then
    WaitForSingleObject(SEInfo.hProcess, INFINITE);

  // Create TempDir
  ForceDirectories(TempDir);

  if not DirectoryExists(TempDir) then
   raise Exception.Create('Can''t create TempDir: ' + TempDir);
end;

destructor TTestList.destroy;
begin
  FUnitTests.Free;
end;

procedure TTestList.TestAll;
var i: integer;
begin
{$IFDEF CONSOLE}
  Writeln(#13#10#13#10'=== TestAll ==='#13#10);
{$ELSE}
  Form1.MainLog.Lines.Add(#13#10#13#10'=== TestAll ==='#13#10);
{$ENDIF}
  for i:=0 to FUnitTests.Count-1 do
    begin
{$IFDEF CONSOLE}
      Write('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
      TUnitTest(FUnitTests[i]).TestAll;
      Writeln('ok.');
{$ELSE}
      Form1.MainLog.Lines.Add('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
      Application.ProcessMessages;
      TUnitTest(FUnitTests[i]).TestAll;
      Form1.MainLog.Lines.Add('ok.');
      Application.ProcessMessages;
{$ENDIF}
    end;
end;

procedure TTestList.TestShort;
var i: integer;
begin
{$IFDEF CONSOLE}
  Writeln(#13#10#13#10'=== TestShort ==='#13#10);
{$ELSE}
  Form1.MainLog.Lines.Add(#13#10#13#10'=== TestShort ==='#13#10);
  Application.ProcessMessages;
{$ENDIF}
  for i:=0 to FUnitTests.Count-1 do
    begin
{$IFDEF CONSOLE}
      Write('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
{$ELSE}
      Form1.MainLog.Lines.Add('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
      Application.ProcessMessages;
{$ENDIF}
      TUnitTest(FUnitTests[i]).TestShort;
{$IFDEF CONSOLE}
      Writeln('ok.');
{$ELSE}
      Form1.MainLog.Lines.Add('ok.');
      Application.ProcessMessages;
{$ENDIF}
    end;
end;

procedure TTestList.TestLong;
var i: integer;
begin
{$IFDEF CONSOLE}
  Writeln(#13#10#13#10'=== TestLong ==='#13#10);
{$ELSE}
  Form1.MainLog.Lines.Add(#13#10#13#10'=== TestLong ==='#13#10);
  Application.ProcessMessages;
{$ENDIF}
  for i:=0 to FUnitTests.Count-1 do
    begin
{$IFDEF CONSOLE}
      Write('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
{$ELSE}
  Form1.MainLog.Lines.Add('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
  Application.ProcessMessages;
{$ENDIF}
      TUnitTest(FUnitTests[i]).TestLong;
{$IFDEF CONSOLE}
      Writeln('ok.');
{$ELSE}
      Form1.MainLog.Lines.Add('ok.');
      Application.ProcessMessages;
{$ENDIF}
    end;
end;


procedure TTestList.TestExceptions;
var i: integer;
begin
{$IFDEF CONSOLE}
  Writeln(#13#10#13#10'=== TestExceptions ==='#13#10);
{$ELSE}
  Form1.MainLog.Lines.Add(#13#10#13#10'=== TestExceptions ==='#13#10);
  Application.ProcessMessages;
{$ENDIF}
  for i:=0 to FUnitTests.Count-1 do
    begin
{$IFDEF CONSOLE}
      Write('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
{$ELSE}
      Form1.MainLog.Lines.Add('UnitTest: ' + TUnitTest(FUnitTests[i]).ClassName + '...');
      Application.ProcessMessages;
{$ENDIF}
      TUnitTest(FUnitTests[i]).TestExceptions;
{$IFDEF CONSOLE}
      Writeln('ok.');
{$ELSE}
      Form1.MainLog.Lines.Add('ok.');
      Application.ProcessMessages;
{$ENDIF}
    end;
end;


procedure TTestList.WriteToLog(const LogFileName, Text: AnsiString);
var fs: TFileStream;
    s: AnsiString;
begin
  s := '[' + FormatDateTime('dd.mm.yyyy hh:nn:ss', now) + ']: ' + #9 + Text + #13#10;
  if FileExists(LogFileName) then
    fs := TFileStream.Create(LogFileName, fmOpenReadWrite or fmShareDenyWrite)
  else
    fs := TFileStream.Create(LogFileName, fmCreate);
  fs.Seek(0, soFromEnd);
  try
    fs.WriteBuffer(s[1],length(s));
  finally
    fs.Free;
  end
end;

procedure TTestList.WriteToProcessLog(Text: AnsiString);
begin
  WriteToLog(FProcessLogFileName, Text);
{$IFNDEF CONSOLE}
  Form1.ProcessLog.Lines.Add(Text);
  Application.ProcessMessages;
{$ENDIF}
end;

procedure TTestList.WriteToErrorLog(Text: AnsiString);
begin
  WriteToLog(FErrorLogFileName, Text);
{$IFNDEF CONSOLE}
  Form1.ErrorLog.Lines.Add(Text);
  Application.ProcessMessages;
{$ENDIF}
end;


{ TUnitTest }


procedure TUnitTest.CheckAction(test: TestAction; const TestName: AnsiString);
begin
  WriteToProcessLog('(' + TestName + ')'#9 + 'start');
  try
    test;
  except
    on e: Exception do
     begin
      WriteToErrorLog('(' + TestName + ')'#9 + 'Error:'#13#10 + e.Message);
      WriteToProcessLog(#13#10+'!!!!!!!'+#13#10+'(' + TestName + ')'#9 + 'Error:'#13#10 + e.Message+#13#10+'!!!!!!!');
      exit;
     end;
  end;
  WriteToProcessLog('(' + TestName + ')'#9 + 'finish');
end;

constructor TUnitTest.Create(UnitTestList: TTestList);
begin
  UnitTestList.AddUnitTestToList(self);
  FUTList := UnitTestList;
  FAppDir := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
end;

procedure TUnitTest.TestAll;
begin
 TestShort;
 TestLong;
 TestExceptions;
end;

procedure TUnitTest.TestShort;
begin
end;

procedure TUnitTest.TestLong;
begin
end;

procedure TUnitTest.TestExceptions;
begin
end;

procedure TUnitTest.WriteToErrorLog(Text: AnsiString);
begin
  FUTList.WriteToErrorLog('<' + Self.ClassName + '> ' + Text);
end;

procedure TUnitTest.WriteToProcessLog(text: AnsiString);
begin
  FUTList.WriteToProcessLog('<' + Self.ClassName + '> ' + Text);
end;

function TUnitTest.GetTempDir: AnsiString;
begin
  Result := FUTList.TempDir;
end;

initialization
  UnitTestList := TTestList.Create;

finalization
  UnitTestList.Free;

end.
