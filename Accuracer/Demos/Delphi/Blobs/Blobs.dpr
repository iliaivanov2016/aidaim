program Blobs;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Client in 'Client.pas' {ClientForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TClientForm, ClientForm);
  Application.Run;
end.
