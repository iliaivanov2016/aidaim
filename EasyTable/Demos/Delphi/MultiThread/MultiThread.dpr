program MultiThread;

uses
  Forms,
  uMain in 'uMain.pas' {fMain},
  BkThread in 'BkThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
