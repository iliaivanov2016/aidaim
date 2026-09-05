program ACR4Convert;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  Security in 'Security.pas' {FormSecurity};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TFormSecurity, FormSecurity);
  Application.Run;
end.
