program Autoinc;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Cust in 'Cust.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
