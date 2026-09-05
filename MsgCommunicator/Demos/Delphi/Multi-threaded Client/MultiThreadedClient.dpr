program MultiThreadedClient;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  uClientThread in 'uClientThread.pas',
  uDisplayThread in 'uDisplayThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Multi-Treaded Client: MsgCommunicator Demo. (c) 2007 AidAim Software';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
