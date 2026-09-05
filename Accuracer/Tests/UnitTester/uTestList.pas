unit uTestList;

{$I ACRVER.inc}
{$I UTConfig.inc}

interface

uses
  ACRTypes,
  ACRMain,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
  ACRConverts,
  ACRConst,
{$IFNDEF CONSOLE}
  MainForm,
{$ENDIF}
{$IFDEF DEBUG_LOG}
ACRDebug,
{$ENDIF}
  classes, forms, shellapi, windows, sysutils, DB, DBTables
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
   private
    function GetTempDir: String;
    function GetSQLDir: String;
   protected
    procedure WriteToProcessLog(Text: String);
    procedure WriteToErrorLog(Text: String);
    procedure CheckQuery(q: TQuery; aq: TACRQuery; Caption: String);
   public
    procedure CheckAction(test: TestAction; const TestName: String);
    constructor Create(UnitTestList: TTestList);
    procedure TestAll;
    procedure TestShort; virtual;
    procedure TestLong; virtual;
    procedure TestExceptions; virtual;
   public
    property TempDir: String read GetTempDir;
    property SQLDir: String read GetSQLDir;
  end;


  TTestList = class(TObject)
   private
    FTempDir:             String;
    FSQLDir:              String;
    FErrorLogFileName:    String;
    FProcessLogFileName:  String;
    FUnitTests:           TList;
   private
    procedure WriteToLog(const LogFileName: String; const Text: String);
   public
    constructor Create;
    destructor destroy; override;
    procedure TestAll;
    procedure TestShort;
    procedure TestLong;
    procedure TestExceptions;
    procedure AddUnitTestToList(Test: TUnitTest);
    procedure WriteToProcessLog(Text: String);
    procedure WriteToErrorLog(Text: String);
   public
    property TempDir: String read FTempDir;
    property SQLDir: String read FSQLDir;
    property ErrorLogFileName: String read FErrorLogFileName;
    property ProcessLogFileName: String read FProcessLogFileName;
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
   RootDir: String;
   LogsDir: String;
   TempDir: String;
   errText: array [1..255] of byte;
   pc: Pchar absolute errText;

  SEInfo: TShellExecuteInfo;

begin
  FUnitTests := TList.Create;

  RootDir := ExtractFilePath(Application.ExeName);
  LogsDir := RootDir + 'Logs';
  TempDir := RootDir + 'Temp';
  FSQLDir := RootDir + 'SQL';

  FTempDir := TempDir + '\';
  FSQLDir := SQLDir + '\';
  FErrorLogFileName := LogsDir + '\error_log.txt';
  FProcessLogFileName := LogsDir + '\process_log.txt';

  if (not DirectoryExists(FSQLDir)) then
   WriteToErrorLog('TTestList.Create error - SQL directory does not exis. SQLDir = '+FSQLDir);
  // Clear logs
  if (not DirectoryExists(LogsDir)) then
    CreateDir(LogsDir);
//  ForceDirectories(LogsDir);
  DeleteFile(FErrorLogFileName);
  DeleteFile(FProcessLogFileName);

  // Empty TempDir
{$IFDEF DELETE_TEMP_DIR}
  FillChar(SEInfo, SizeOf(SEInfo), 0);
  SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  with SEInfo do begin
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd := Application.Handle;
    lpFile := PChar('cmd');
    lpParameters := PChar('/c rmdir /s /q "' + TempDir+'"');
    nShow := SW_HIDE;
  end;
  if ShellExecuteEx(@SEInfo) then
    WaitForSingleObject(SEInfo.hProcess, INFINITE);
{$ENDIF}
  // Create TempDir
  if (not DirectoryExists(TempDir)) then
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


procedure TTestList.WriteToLog(const LogFileName, Text: String);
var fs:   TFileStream;
    s:    String;
    bOk:  Boolean;
begin
  {$IFDEF DEBUG_LOG}

  if (LogFileName = FProcessLogFileName) then
   s := 'UT Process Log, GetTickCount = ' + IntToStr(GetTickCount) + ' : ' + #9 + Text + #13#10
  else
   s := 'UT Error Log , GetTickCount =  ' + IntToStr(GetTickCount) + ' : ' + #9 + Text + #13#10;
{$IFDEF WRITE_TO_ACR_LOG}
  aaWriteToLog(s);
{$ENDIF}
  {$ELSE}
  s := '[' + FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', now) + ']: ' + #9 + Text + #13#10;
  {$ENDIF}
  bOK := False;
  while (not bOK) do
  try
    if FileExists(LogFileName) then
      fs := TFileStream.Create(LogFileName, fmOpenReadWrite or fmShareDenyWrite)
    else
      fs := TFileStream.Create(LogFileName, fmCreate);
    bOK := True;
  except
  end;
  try
    fs.Seek(0, soFromEnd);
    fs.WriteBuffer(s[1],length(s));
  finally
    fs.Free;
  end
end;

procedure TTestList.WriteToProcessLog(Text: String);
begin
  WriteToLog(FProcessLogFileName, Text);
{$IFNDEF CONSOLE}
  Form1.ProcessLog.Lines.Add(Text);
  Application.ProcessMessages;
{$ENDIF}
end;

procedure TTestList.WriteToErrorLog(Text: String);
begin
  WriteToLog(FErrorLogFileName, Text);
{$IFNDEF CONSOLE}
  Form1.ErrorLog.Lines.Add(Text);
  Application.ProcessMessages;
{$ENDIF}
end;


{ TUnitTest }


procedure TUnitTest.CheckAction(test: TestAction; const TestName: String);
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

procedure TUnitTest.WriteToErrorLog(Text: String);
begin
  FUTList.WriteToErrorLog('<' + Self.ClassName + '> ' + Text);
end;

procedure TUnitTest.WriteToProcessLog(text: String);
begin
  FUTList.WriteToProcessLog('<' + Self.ClassName + '> ' + Text);
end;

procedure TUnitTest.CheckQuery(q: TQuery; aq: TACRQuery; Caption: String);
var i,n: Integer;
begin
 if (aq.BOF <> q.BOF) then
  WriteToErrorLog(Caption+' failed #1, BOF = '
    +IntToStr(Word(aq.BOF))+', BDE BOF = '+IntToStr(Word(q.BOF)));
 if (aq.EOF <> q.EOF) then
  WriteToErrorLog(Caption+' failed #2, EOF = '
    +IntToStr(Word(aq.EOF))+', BDE EOF = '+IntToStr(Word(q.EOF)));
 if (aq.CanModify <> q.CanModify) then
  WriteToErrorLog(Caption+' failed #2, CanModify = '
    +IntToStr(Word(aq.CanModify))+', BDE CanModify = '+IntToStr(Word(q.CanModify)));
 if (aq.RecordCount <> q.RecordCount) then
  WriteToErrorLog(Caption+' failed #3, record count = '
    +IntToStr(aq.RecordCount)+', BDE record count = '+IntToStr(q.RecordCount));
 if (aq.FieldDefs.Count <> q.FieldDefs.Count) then
  WriteToErrorLog(Caption+' failed #4, fielddefs count = '
    +IntToStr(aq.FieldDefs.Count)+', BDE fielddefs count = '+IntToStr(q.FieldDefs.Count));
 if (aq.FieldCount <> q.FieldCount) then
  WriteToErrorLog(Caption+' failed #5, field count = '
    +IntToStr(aq.FieldCount)+', BDE field count = '+IntToStr(q.FieldCount))
 else
  begin
   for i := 0 to aq.FieldDefs.Count - 1 do
    begin
     if (aq.FieldDefs[i].Name <> q.FieldDefs[i].Name) then
      WriteToErrorLog(Caption+' failed #6, field name = ' +
        aq.FieldDefs[i].Name + ', BDE field name = '+q.FieldDefs[i].Name);

     if (
         (aq.FieldDefs[i].DataType <> q.FieldDefs[i].DataType)
         and
         (aq.FieldDefs[i].DataType <> ftWideString)
         and
         (aq.FieldDefs[i].DataType <> ftFixedChar)
         and
         (aq.FieldDefs[i].DataType <> ftAutoInc)
        ) or
        (
         (aq.FieldDefs[i].DataType = ftAutoInc) and
         (q.FieldDefs[i].DataType <> ftInteger) and
         (q.FieldDefs[i].DataType <> ftAutoInc)
        )
         then
      WriteToErrorLog(Caption+' failed #7, field type = ' +
        IntToStr(Integer(aq.FieldDefs[i].DataType)) + ', BDE field type = '+
        IntToStr(Integer(q.FieldDefs[i].DataType)));

     if (aq.FieldDefs[i].Size <> q.FieldDefs[i].Size) then
      WriteToErrorLog(Caption+' failed #8, field size = ' +
        IntToStr(Integer(aq.FieldDefs[i].Size)) + ', BDE field size = '+
        IntToStr(Integer(q.FieldDefs[i].Size)));

     if (aq.FieldDefs[i].Required <> q.FieldDefs[i].Required) then
      WriteToErrorLog(Caption+' failed #9, field required = ' +
        IntToStr(Integer(aq.FieldDefs[i].Required)) + ', BDE field required = '+
        IntToStr(Integer(q.FieldDefs[i].Required)));

    end;
  end;
 aq.First;
 q.First;
 n := 0;
 while (not q.Eof) do
  begin
   for i := 0 to aq.FieldCount - 1 do
    if (aq.Fields[i].Value <> q.Fields[i].Value) then
      WriteToErrorLog(Caption+' failed #10, field  value = ' +
        aq.Fields[i].AsString + ', BDE field value = '+
        q.Fields[i].AsString);
   aq.Next;
   q.Next;
   Inc(n);
  end;
 if (aq.EOF <> q.EOF) then
  WriteToErrorLog(Caption+' failed #11, EOF = '
    +IntToStr(Word(aq.EOF))+', BDE EOF = '+IntToStr(Word(q.EOF)));
 if (n <> aq.RecordCount) then
  WriteToErrorLog(Caption+' failed #12, Accuracer RecordCount = '
    +IntToStr(aq.RecordCount)+', BDE RecordCount = '+IntToStr(n));
end;

function TUnitTest.GetTempDir: String;
begin
  Result := FUTList.TempDir;
end;

function TUnitTest.GetSQLDir: String;
begin
  Result := FUTList.SQLDir;
end;

initialization
  UnitTestList := TTestList.Create;

finalization
  UnitTestList.Free;

end.
