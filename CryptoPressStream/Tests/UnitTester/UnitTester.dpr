{$DEFINE CONSOLE}

program UnitTester;

{$IFDEF CONSOLE}
{$APPTYPE CONSOLE}
{$ENDIF}

{$I CPSVer.inc}
{$O-}
{$R+}
{$Q+}

uses
  Forms,
  MainForm in 'MainForm.pas' {Form1},
  MemCheck,
  SysUtils,
  CPSConst,
  uTestList in 'uTestList.pas',
  utStreams in 'utStreams.pas',
  utEncryption in 'utEncryption.pas';

{$IFNDEF CONSOLE}
{$R *.res}
{$ENDIF}

begin
  {$IFDEF DEBUG_MEMCHECK}
  MemChk;
  {$ENDIF}
{$IFNDEF CONSOLE}
  Application.Initialize;
  Form1 := TForm1.Create(Nil);
  Form1.Show;
  Application.Run;
{$ENDIF}

{$IFDEF CONSOLE}
  writeln('Unit Tester - CryptoPressStream version: '+FloatToStrF(CPSVersion,ffFixed,3,2) + ' ' + CPSVersionText);
  writeln('Run Tests.');
{$ELSE}
  Form1.MainLog.Lines.Add('Unit Tester - CryptoPressStream version: '+FloatToStrF(CPSVersion,ffFixed,3,2) + ' ' + CPSVersionText);
  Form1.MainLog.Lines.Add('Run Tests.');
{$ENDIF}
  try

   UnitTestList.TestShort;
   UnitTestList.TestExceptions;

  except
    on e:Exception do
{$IFDEF CONSOLE}
      writeln(#13#10'Error: ' + e.Message);
{$ELSE}
      Form1.MainLog.Lines.Add(#13#10'Error: ' + e.Message);
{$ENDIF}
  end;
{$IFDEF CONSOLE}
  writeln('All Done.');
{$ELSE}
  Form1.MainLog.Lines.Add('All Done.');
  repeat
    Application.ProcessMessages;
  until not Form1.Visible;
{$ENDIF}
end.
