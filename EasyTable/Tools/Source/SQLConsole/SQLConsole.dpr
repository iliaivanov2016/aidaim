program SQLConsole;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  AboutUnit in 'AboutUnit.pas' {SQLConsoleAbout};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TSQLConsoleAbout, SQLConsoleAbout);
  Application.Run;
end.
