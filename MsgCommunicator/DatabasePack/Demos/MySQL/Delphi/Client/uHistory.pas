unit uHistory;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Db,
  MsgComBase, MsgTypes, MsgConst, MsgClient, Grids;

type
  TfmHistory = class(TForm)
    Panel1: TPanel;
    bnShowHistory: TButton;
    bnCancel: TButton;
    GroupBox1: TGroupBox;
    gbMessages: TGroupBox;
    dtpFrom: TDateTimePicker;
    dtpTo: TDateTimePicker;
    cbLocal: TCheckBox;
    rgMessageType: TRadioGroup;
    cbFrom: TCheckBox;
    cbTo: TCheckBox;
    cbMessage: TComboBox;
    Label1: TLabel;
    chbIgnoreCase: TCheckBox;
    eMessage: TEdit;
    sgHistory: TStringGrid;
    procedure FormShow(Sender: TObject);
    procedure bnCancelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cbFromClick(Sender: TObject);
    procedure cbToClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnShowHistoryClick(Sender: TObject);
    procedure sgHistoryMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
    FClose: Boolean;
  public
    { Public declarations }
    procedure ShowHistory(ds: TDataset);
  end;

var
  fmHistory: TfmHistory;

implementation

uses uMain;

{$R *.dfm}

procedure TfmHistory.FormShow(Sender: TObject);
begin
 FClose := False;
 gbMessages.Caption := ' Messages found: 0 ';
end;

procedure TfmHistory.bnCancelClick(Sender: TObject);
begin
 FClose := True;
end;

procedure TfmHistory.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (not FClose) then
  Action := TCloseAction(caNone);
end;

procedure TfmHistory.cbFromClick(Sender: TObject);
begin
  dtpFrom.Enabled := cbFrom.Checked;
end;

procedure TfmHistory.cbToClick(Sender: TObject);
begin
  dtpTo.Enabled := cbTo.Checked;
end;

procedure TfmHistory.FormCreate(Sender: TObject);
begin
  dtpFrom.Date := Now;
  dtpTo.Date := Now;
  sgHistory.ColCount := 4;
  sgHistory.RowCount := 2;
  sgHistory.FixedRows := 1;
  sgHistory.Cells[0,0] := 'Date';
  sgHistory.Cells[1,0] := 'Time';
  sgHistory.Cells[2,0] := 'Sender';
  sgHistory.Cells[3,0] := 'Message';
  sgHistory.ColWidths[0] := 70;
  sgHistory.ColWidths[1] := 70;
  sgHistory.ColWidths[2] := 100;
  sgHistory.ColWidths[3] := 200;
  cbMessage.ItemIndex := 0;
end;

procedure TfmHistory.bnShowHistoryClick(Sender: TObject);
var mc,mc1:       TMsgTextComparison;
    sd,dd:        TMsgDateComparison;
    ds:           TDataset;
    code:         Integer;
    SenderID:     Cardinal;
    RecipientID:  Cardinal;
begin
 FillChar(mc,SizeOf(mc),$00);
 FillChar(mc1,SizeOf(mc1),$00);
 FillChar(sd,SizeOf(sd),$00);
 FillChar(dd,SizeOf(dd),$00);
 if (rgMessageType.ItemIndex = 1) then
  begin
   SenderID := MSG_INVALID_USER_ID;
   RecipientID := fmMain.MsgClient1.UserID;
  end
 else
 if (rgMessageType.ItemIndex = 2) then
  begin
   SenderID := fmMain.MsgClient1.UserID;
   RecipientID := MSG_INVALID_USER_ID;
  end
 else
  begin
   SenderID := fmMain.MsgClient1.UserID;
   RecipientID := fmMain.MsgClient1.UserID;
  end;
 if (eMessage.Text <> '') then
  begin
   case (cbMessage.ItemIndex) of
    1: mc.Comparison := mscmpStarts;
    2: mc.Comparison := mscmpContains
   else
    mc.Comparison := mscmpExact;
   end;
   mc.CaseInsensitive := chbIgnoreCase.Checked;
  end;
 if (cbFrom.Checked) then
   begin
    sd.DateTime1 := dtpFrom.Date;
    sd.Comparison1 := mcmpopGreaterEqual;
   end;
 if (cbTo.Checked) then
   begin
    sd.DateTime2 := dtpTo.Date+1;
    sd.Comparison2 := mcmpopLower;
   end;
 code := fmMain.MsgClient1.FindMessages(ds,cbLocal.Checked,
                        mc,mc1,sd,dd,False,True,
                        eMessage.Text,'',
                        SenderID,RecipientID,aamtText
                          );
 if (code = MSG_COMMAND_OK) then
  try
    if (rgMessageType.ItemIndex = 2) then
     sgHistory.Cells[2,1] := 'Sender'
    else
     sgHistory.Cells[2,1] := 'Recipient';
    ShowHistory(ds);
  finally
    ds.Free;
  end
 else
   ShowMessage('Cannot find messages. Error code = '+IntToStr(code));
end;

procedure TfmHistory.ShowHistory(ds: TDataset);
var i,row: Integer;
begin
  gbMessages.Caption := ' Messages found: '+IntToStr(ds.RecordCount)+' ';
  ds.First();
  row := 1;
  sgHistory.RowCount := 2;
  sgHistory.FixedRows := 1;
  for i := 0 to sgHistory.ColCount-1 do
   sgHistory.Cells[i,1] := '';
  while (not ds.Eof) do
   begin
    if (row >= sgHistory.RowCount) then
     sgHistory.RowCount := sgHistory.RowCount+1;
    sgHistory.Cells[0,row] := DateToStr(ds.FieldByName('SendingDate').AsDateTime);
    sgHistory.Cells[1,row] := TimeToStr(ds.FieldByName('SendingDate').AsDateTime);
    if (rgMessageType.ItemIndex = 2) then
     sgHistory.Cells[2,row] := IntToStr(ds.FieldByName('RecipientID').AsInteger)
    else
     sgHistory.Cells[2,row] := IntToStr(ds.FieldByName('SenderID').AsInteger);
    sgHistory.Cells[3,row] := ds.FieldByName('MessageText').AsString;
    ds.Next();
    Inc(row);
   end;
end;

procedure TfmHistory.sgHistoryMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var ARow, ACol: Integer;
begin
  sgHistory.ShowHint := False;
  sgHistory.MouseToCell(X,Y,ACol,ARow);
  if (ACol >= 0) and (ARow >= 0) and
     (ACol < sgHistory.ColCount) and
     (ARow < sgHistory.RowCount) then
   begin
    sgHistory.Hint := sgHistory.Cells[ACol,ARow];
    sgHistory.ShowHint := True;
   end;
end;

end.
