program RestructureTableMultiThread;

uses
  Forms,
  uMain in 'uMain.pas' {Form1},
  uBkThread in 'uBkThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
