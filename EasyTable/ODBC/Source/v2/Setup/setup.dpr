program setup;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
//  ODBCAPI in 'ODBCAPI.pas',
  constSQL in 'constSQL.pas',
  constODBC in 'constODBC.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
