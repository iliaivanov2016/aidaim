program TestBatch;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Unit2 in 'Unit2.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
