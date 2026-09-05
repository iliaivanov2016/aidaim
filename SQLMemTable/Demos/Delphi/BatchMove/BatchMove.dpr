program BatchMove;

uses
  Forms,
  Batmove in 'Batmove.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
