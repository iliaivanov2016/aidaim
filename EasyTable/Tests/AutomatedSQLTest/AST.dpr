program AST;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
