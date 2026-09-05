program Client;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  uStart in 'uStart.pas' {fmStart},
  uRegister in 'uRegister.pas' {fmRegister},
  uLogin in 'uLogin.pas' {fmLogin},
  uFind in 'uFind.pas' {fmFind},
  uHistory in 'uHistory.pas' {fmHistory};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Client with MySQL: MsgCommunicator Demo. (c) 2004-2008 AidAim Software';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmStart, fmStart);
  Application.CreateForm(TfmRegister, fmRegister);
  Application.CreateForm(TfmLogin, fmLogin);
  Application.CreateForm(TfmFind, fmFind);
  Application.CreateForm(TfmHistory, fmHistory);
  Application.Run;
end.
