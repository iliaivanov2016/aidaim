unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus, SFSEngine, SFSPassword, SFSDecUtil, ExtCtrls;

type
  TfrmMain = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Label1: TLabel;
    btOpen: TButton;
    GroupBox1: TGroupBox;
    lbPages: TListBox;
    btSavePage: TButton;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lbNextPageNo: TLabel;
    lbPageType: TLabel;
    lbEncType: TLabel;
    cbDecrypt: TCheckBox;
    edPass: TEdit;
    memHex: TMemo;
    btRefresh: TButton;
    GroupBox3: TGroupBox;
    lbDirectory: TListBox;
    GroupBox4: TGroupBox;
    Label5: TLabel;
    lbFirstMapPageNo: TLabel;
    procedure btOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbPagesClick(Sender: TObject);
    procedure btSavePageClick(Sender: TObject);
    procedure btRefreshClick(Sender: TObject);
    procedure lbDirectoryClick(Sender: TObject);
  private
    { Private declarations }
    PFMHandle: TPageFileManager;
    DIRHandle: TDIRManager;

    procedure LoadData;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

  PageTypeStr: array [0..6] of string = ('FREE','DIR','GAM','SGAM','PFS','UFPM','UF');

implementation

{$R *.DFM}

procedure TfrmMain.LoadData;
var
  i: integer;
  FKey: string;
begin
    if (PFMHandle <> nil) then
     PFMHandle.Free;
    lbPages.Clear;
    lbDirectory.Clear;
    PFMHandle := TPageFileManager.Create(OpenDialog1.FileName, fmOpenRead, edPass.Text);
    if (PFMHandle.FHeader.EncMethod <> 0) then
     if (not CheckPassword(PFMHandle.FHeader.PasswordHeader,edPass.Text, FKey)) then
      begin
       PFMHandle.Free;
       MessageDlg('Invalid password', mtError, [mbOK], 0);
       exit;
      end;
    for i := 0 to PFMHandle.FHeader.TotalPageCount-1 do
      lbPages.Items.Add(IntToStr(i));

    if (DIRHandle <> nil) then
     DIRHandle.Free;
    DIRHandle := TDIRManager.Create(PFMHandle, nil);
    for i := 0 to DIRHandle.FDir.ItemCount-1 do
      lbDirectory.Items.Add(DIRHandle.FDir.Items[i].FileName);
end;


procedure TfrmMain.btOpenClick(Sender: TObject);
var
  i: integer;
  FKey: string;
begin
 if (OpenDialog1.Execute) then
  begin
   LoadData;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
 PFMHandle := nil;
end;

procedure TfrmMain.lbPagesClick(Sender: TObject);
var
  page: TFFPage;
  s,s1,s2: string;
  i,j: integer;
  c: char;
begin
 if (PFMHandle <> nil) then
  begin
    PFMHandle.AllocPageBuffer(page);
    PFMHandle.ReadPage(page, StrToInt(lbPages.Items[lbPages.ItemIndex]),
                        -1, '', false);
    // not decrypt?
    if (page.PageHeader.EncType <> 1) then
     PFMHandle.ReadPage(page, StrToInt(lbPages.Items[lbPages.ItemIndex]),
                         -1, '', true);

    s := StrtoFormat(pChar(page.pData),PFMHandle.PageDataSize,fmtHEX);
    memHex.Text := '';
    memHex.Visible := false;
    for i := 0 to (Length(s) div 32)-1 do
     begin
      FmtStr(s1,'%5.0d',[i*16]);
      s2 := '';
      for j:=0 to 16-1 do
       begin
        c := PChar(pChar(page.pData)+i*16+j)^;
        if (c < '0') or (c > 'z') then
         s2 := s2+ 'Ú'
        else
         s2 := s2+ c;
       end;
      memHex.Lines.Add(s1+': '+Copy(s, i*32+1, 32)+'  |  '+s2);
     end;
    memHex.Visible := true;

    lbNextPageNo.Caption := IntToStr(page.PageHeader.NextPageNo);
    if (page.PageHeader.PageType > 6) then
     lbPageType.Caption := '???'
    else
     lbPageType.Caption := PageTypeStr[page.PageHeader.PageType];
    lbEncType.Caption := IntToStr(page.PageHeader.EncType);
    PFMHandle.FreePageBuffer(page);
  end;
end;

procedure TfrmMain.btSavePageClick(Sender: TObject);
var
  page: TFFPage;
  fs: TFileStream;
begin
 if (PFMHandle <> nil) then
  begin
   SaveDialog1.FileName := IntToStr(lbPages.ItemIndex)+'.dat';
   if (SaveDialog1.Execute) then
    begin
     PFMHandle.AllocPageBuffer(page);
     PFMHandle.ReadPage(page, StrToInt(lbPages.Items[lbPages.ItemIndex]),
                        -1, '', not cbDecrypt.Checked);
     fs := TFileStream.Create(SaveDialog1.FileName, fmCreate);
     fs.Write(page.PageHeader, PageHeaderSize);
     fs.Write(page.pData^, PFMHandle.PageDataSize);
     fs.Free;
     PFMHandle.FreePageBuffer(page);
    end;
  end;
end;

procedure TfrmMain.btRefreshClick(Sender: TObject);
var
  PagesIndex, DirIndex: integer;
begin
    PagesIndex := lbPages.ItemIndex;
    DirIndex := lbDirectory.ItemIndex;
    if (PFMHandle <> nil) then
     LoadData;
    lbPages.ItemIndex := PagesIndex;
    lbDirectory.ItemIndex := DirIndex;
    if (lbPages.ItemIndex > -1) then
     lbPagesClick(self);
    if (lbDirectory.ItemIndex > -1) then
     lbDirectoryClick(self);
end;

procedure TfrmMain.lbDirectoryClick(Sender: TObject);
begin
 if (PFMHandle <> nil) and (lbDirectory.ItemIndex >= 0) then
  begin
    lbFirstMapPageNo.Caption := IntToStr(DIRHandle.FDIR.Items[lbDirectory.ItemIndex].FirstMapPageNo);
  end;
end;

end.
