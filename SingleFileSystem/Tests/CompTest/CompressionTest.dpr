program CompressionTest;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  aaDebug in '..\..\EasyTable\Current\aaDebug.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
