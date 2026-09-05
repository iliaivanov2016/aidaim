unit DSNsetup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons;

type
  TDSNsetupForm = class(TForm)
    OK: TBitBtn;
    Cancel: TBitBtn;
    Help: TBitBtn;
    DSN: TEdit;
    Description: TEdit;
    Dir: TBitBtn;
    DatabaseFile: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SelectDatabase: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure DirClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure OKClick(Sender: TObject);
    procedure HelpClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Button: (btnOK, btnCancel);
  end;

var
  DSNsetupForm: TDSNsetupForm;

implementation
{$R *.DFM}

procedure TDSNsetupForm.FormCreate(Sender: TObject);
begin
  Button:=BtnCancel;
end;

procedure TDSNsetupForm.DirClick(Sender: TObject);
begin
  if SelectDatabase.Execute then DatabaseFile.Text:=SelectDatabase.FileName;
end;

procedure TDSNsetupForm.CancelClick(Sender: TObject);
begin
  DSNsetupForm.Close;
end;

procedure TDSNsetupForm.OKClick(Sender: TObject);
begin
  if (DatabaseFile.Text='') or (DSN.Text='')
  then  MessageDlg('You must enter Data Source Name and select Datasource Path!', mtWarning,[mbOk],0)
  else
    begin
      Button:=btnOK;
      DSNsetupForm.Close;
    end;
end;

procedure TDSNsetupForm.HelpClick(Sender: TObject);
begin
  MessageDlg('Enter your Data Source Name and select your database file to specify Datasource Path.'+#10+#13+
  'Also you may edit a Description.', mtInformation,[mbOk],0)
end;

end.
