program SQLConsole;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  AboutUnit in 'AboutUnit.pas' {SQLConsoleAbout},
  ExportToSQL in 'ExportToSQL.pas' {fmExportToSQL};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TSQLConsoleAbout, SQLConsoleAbout);
  Application.CreateForm(TfmExportToSQL, fmExportToSQL);
  Application.Run;
end.
