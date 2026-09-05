unit CryptoUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TFormCrypto = class(TForm)
    Label2: TLabel;
    UserFileName: TEdit;
    bnOk: TBitBtn;
    bnCancel: TBitBtn;
    Label1: TLabel;
    Password: TEdit;
    Label3: TLabel;
    ControlQuestion: TMemo;
    Label5: TLabel;
    Answer: TEdit;
    Encrypted: TCheckBox;
    procedure EncryptedClick(Sender: TObject);
    procedure bnOkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormCrypto: TFormCrypto;

implementation

{$R *.DFM}

procedure TFormCrypto.EncryptedClick(Sender: TObject);
begin
 if (Encrypted.Checked) then
  begin
   Password.Color := clWindow;
   ControlQuestion.Color := clWindow;
   Answer.Color := clWindow;
   Password.Enabled := true;
   ControlQuestion.Enabled := true;
   Answer.Enabled := true;
  end
 else
  begin
   Password.Color := clSilver;
   ControlQuestion.Color := clSilver;
   Answer.Color := clSilver;
   Password.Enabled := false;
   ControlQuestion.Enabled := false;
   Answer.Enabled := false;
  end;
end;

procedure TFormCrypto.bnOkClick(Sender: TObject);
begin
  if not Encrypted.Checked then
   begin
     Password.Text:='';
     ControlQuestion.Text:='';
     Answer.Text:='';
   end;
end;

end.
