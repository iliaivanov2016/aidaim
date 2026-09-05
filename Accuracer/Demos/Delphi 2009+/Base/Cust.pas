unit Cust;

interface

{$I ..\..\Ver.Inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, DBCtrls, Db;

type
  TCustForm = class(TForm)
    Label1: TLabel;
    CompanyDBEd: TDBEdit;
    Button1: TButton;
    Button2: TButton;
    Label2: TLabel;
    DBEdit1: TDBEdit;
    Label3: TLabel;
    DBEdit2: TDBEdit;
    Label4: TLabel;
    DBEdit3: TDBEdit;
    Label5: TLabel;
    DBEdit4: TDBEdit;
    Label6: TLabel;
    DBEdit5: TDBEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CustForm: TCustForm;

implementation

uses Main;

{$R *.DFM}

procedure TCustForm.Button1Click(Sender: TObject);
begin
 MainForm.ACRTable1.Post;
end;

procedure TCustForm.Button2Click(Sender: TObject);
begin
 MainForm.ACRTable1.Cancel;
end;

procedure TCustForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (MainForm.ACRTable1.State = dsInsert) or
    (MainForm.ACRTable1.State = dsEdit) then
  MainForm.ACRTable1.Cancel;
end;

procedure TCustForm.FormShow(Sender: TObject);
begin
 ActiveControl := CompanyDBEd;
end;

end.
