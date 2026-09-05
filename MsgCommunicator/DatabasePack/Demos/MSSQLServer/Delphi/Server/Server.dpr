program Server;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Server with MS SQL Server: MsgCommunicator Demo. (c) 2004-2010 AidAim Software';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
