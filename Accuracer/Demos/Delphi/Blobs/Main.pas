unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, Db, ComCtrls,
  DBCtrls, ACRMain;

type
  TMainForm = class(TForm)
    DataSource1: TDataSource;
    Panel1: TPanel;
    NewCustBtn: TBitBtn;
    EditCustBtn: TBitBtn;
    DeleteCustBtn: TBitBtn;
    Panel2: TPanel;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    DBImage1: TDBImage;
    DBRichEdit1: TDBRichEdit;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    procedure FormCreate(Sender: TObject);
    procedure NewCustBtnClick(Sender: TObject);
    procedure EditCustBtnClick(Sender: TObject);
    procedure DeleteCustBtnClick(Sender: TObject);
  private
    { Private declarations }
    procedure UpdateButtons;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses Client;

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  with ACRTable1 do
  {if table doesn't exist}
  if not Exists then
   begin
      {set table structure}
			with FieldDefs do
				begin
 			   Clear;
         Add('ID',ftAutoInc,0,False);
         Add('Name',ftString,30,False);
         Add('Photo',ftGraphic,0,False);
         Add('Journal',ftFmtMemo,0,False);
         Add('Comments',ftMemo,0,False);
         Add('File',ftBlob,0,False);
 				end;
			with IndexDefs do
				begin
				 Clear;
         Add('PrimaryKey','ID',[ixPrimary]);
         Add('ByName','Name',[ixCaseInsensitive]);
				end;
      {and create the table}
	 	  CreateTable;
   end;
 // open table
 ACRTable1.Active := true;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.NewCustBtnClick(Sender: TObject);
begin
 ACRTable1.Insert;
 ClientForm.ShowModal;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.EditCustBtnClick(Sender: TObject);
begin
 if (EditCustBtn.Enabled) then
  begin
   ACRTable1.Edit;
   ClientForm.ShowModal;
   // update buttons
   UpdateButtons;
  end;
end;

procedure TMainForm.DeleteCustBtnClick(Sender: TObject);
begin
 if MessageDlg('Do you really want to delete client '+
               QuotedStr(ACRTable1.FieldByName('Name').AsString)+
               '?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
  ACRTable1.Delete;
 // update buttons
 UpdateButtons;
end;

procedure TMainForm.UpdateButtons;
begin
 if (ACRTable1.RecordCount > 0) then
  begin
   EditCustBtn.Enabled := true;
   DeleteCustBtn.Enabled := true;
  end
 else
  begin
   EditCustBtn.Enabled := false;
   DeleteCustBtn.Enabled := false;
  end
end;

end.
