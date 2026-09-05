program QuickReport;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Cust in 'Cust.pas' {CustForm},
  Report in 'Report.pas' {frmReport};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TCustForm, CustForm);
  Application.CreateForm(TfrmReport, frmReport);
  Application.Run;
end.
