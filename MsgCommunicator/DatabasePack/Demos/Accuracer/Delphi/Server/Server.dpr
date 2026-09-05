program Server;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Server with Accuracer: MsgCommunicator Demo. (c) 2004-2010 AidAim Software';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
