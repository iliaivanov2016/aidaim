program FastReport;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Cust in 'Cust.pas' {CustForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TCustForm, CustForm);
  Application.Run;
end.
