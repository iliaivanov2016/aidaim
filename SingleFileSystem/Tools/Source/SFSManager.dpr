program SFSManager;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  AboutUnit in 'AboutUnit.pas' {SFSManagerAbout},
  ProgressIndicator in 'ProgressIndicator.pas' {FormProgress},
  PassUnit in 'PassUnit.pas' {FormPass},
  QuestUnit in 'QuestUnit.pas' {FormQuest},
  ProgressCancel in 'ProgressCancel.pas' {FormProgressCancel},
  CompLevel in 'CompLevel.pas' {FormCompLevel},
  CryptoUnit in 'CryptoUnit.pas' {FormCrypto},
  ProgressCancel2 in 'ProgressCancel2.pas' {FormProgressCancel2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFormQuest, FormQuest);
  Application.CreateForm(TFormPass, FormPass);
  Application.CreateForm(TSFSManagerAbout, SFSManagerAbout);
  Application.CreateForm(TFormProgress, FormProgress);
  Application.CreateForm(TFormProgressCancel, FormProgressCancel);
  Application.CreateForm(TFormCompLevel, FormCompLevel);
  Application.CreateForm(TFormCrypto, FormCrypto);
  Application.CreateForm(TFormProgressCancel2, FormProgressCancel2);
  Application.Run;
end.
 
