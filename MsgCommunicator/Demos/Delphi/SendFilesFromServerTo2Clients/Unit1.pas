unit Unit1;

interface

uses

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, MsgClient, MsgComBase, MsgServer,
  MsgConst, MsgConnection, Grids, DBGrids, StrUtils, MsgDebug;

 {$DEFINE DEBUG_LOG_SEND_FILE}

const
  TimeOut = 60000; // 1 minute
  Blocks = 10;

type

  TRecParams = record
    FileSize1,
    FileSize2,
    Received1,
    Received2:    Integer;
    Receiving1,
    Receiving2:   Boolean;
    FileName1,
    FileName2:    String;
  end;
  PRecParams = ^TRecParams;

  TForm1 = class(TForm)
    gbSendClient: TGroupBox;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    btnSend: TButton;
    btnBrowse: TButton;
    MsgServer1: TMsgServer;
    MsgClient1: TMsgClient;
    fFileName: TEdit;
    btnAddFile: TButton;
    Label3: TLabel;
    FilesToSend: TStringGrid;
    MsgClient2: TMsgClient;
    pLog: TGroupBox;
    Log: TMemo;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnAddFileClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MsgServer1SendFile(const ToUserID, FileID: Cardinal;
      const FileName: String; FullSize: Int64;
      BlockSize, BlockNo, Blocks: Integer);
    procedure MsgClient1ReceiveFile(const FromUserID, FileID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const FileName: String;
      FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
    procedure MsgClient2ReceiveFile(const FromUserID, FileID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const FileName: String;
      FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
    procedure AddRow(Grid: TStringGrid; Str: String);
    function GetPercent(BlockSize,BlockNo,FullSize: Integer): String;
    procedure CheckReceivedFile(i,client: Integer);
    function FileIndex(const FileName: AnsiString): Integer;
    procedure MsgServer1Error(Sender: TComponent; const ErrorCode,
      NativeError: Integer; const ErrorMessage: String);
    procedure MsgClient2Error(Sender: TComponent; const ErrorCode,
      NativeError: Integer; const ErrorMessage: String);
    procedure MsgClient1Error(Sender: TComponent; const ErrorCode,
      NativeError: Integer; const ErrorMessage: String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    Rec: array of PRecParams;
  end;

var
  Form1:              TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnBrowseClick(Sender: TObject);
begin
  if not OpenDialog1.Execute then
    Exit;
  fFileName.Text := OpenDialog1.FileName;
end;

procedure TForm1.btnSendClick(Sender: TObject);
var
  i:          Integer;
  RecParams:  PRecParams;
begin
  SetLength(Rec, FilesToSend.RowCount-1);
  for i:=0 to Length(Rec)-1 do
   begin
    new(RecParams);
    RecParams.Receiving1 := False;
    RecParams.Received1 := 0;
    RecParams.FileSize1 := -2;
    RecParams.Receiving2 := False;
    RecParams.Received2 := 0;
    RecParams.FileSize2 := -2;
    RecParams.FileName1 := '';
    RecParams.FileName2 := '';
    Rec[i] := RecParams;
   end;
  for i:=1 to FilesToSend.RowCount-1 do
   begin
    MsgServer1.SendFile(MsgClient1.UserID,FilesToSend.Cells[1,i],Blocks);
    MsgServer1.SendFile(MsgClient2.UserID,FilesToSend.Cells[1,i],Blocks);
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  UserInfo:     TMsgUserInfo;
begin
  MsgServer1.IncomingPath := '.\Incoming1\';
  MsgClient1.IncomingPath := '.\Incoming1\';
  MsgClient2.IncomingPath := '.\Incoming2\';
  MsgServer1.ClearAll;
  MsgServer1.Active := True;
  MsgClient1.ConnectionParams.NetworkSettings.UseServerSettings := false;
  MsgClient2.ConnectionParams.NetworkSettings.UseServerSettings := false;
  MsgClient1.Connect;
  MsgClient2.Connect;
  UserInfo.UserID := MSG_INVALID_USER_ID;
  UserInfo.UserName := 'User1';
  MsgClient1.RegisterNewUser(UserInfo);
  UserInfo.UserName := 'User2';
  MsgClient2.RegisterNewUser(UserInfo);
  FilesToSend.ColWidths[0] := 18;
  FilesToSend.ColWidths[1] := 145;
  FilesToSend.ColWidths[2] := 45;
  FilesToSend.ColWidths[3] := 30;
  FilesToSend.Cells[0,0] := '#';
  FilesToSend.Cells[1,0] := 'Name';
  FilesToSend.Cells[2,0] := 'Size, KB';
  FilesToSend.Cells[3,0] := 'Sent';
end;

procedure TForm1.MsgServer1SendFile(const ToUserID, FileID: Cardinal;
  const FileName: AnsiString; FullSize: Int64;
   BlockSize, BlockNo, Blocks: Integer);
var
  i,
  percent:    Integer;
begin
  for i:=1 to FilesToSend.RowCount-1 do
   if (Pos(FileName,FilesToSend.Cells[1,i]) > 0) then
    begin
      if (FileName <> FilesToSend.Cells[1,i]) then
        FilesToSend.Cells[1,i] := FileName;
      if (BlockNo < 0) then
        FilesToSend.Cells[3,i] := '0%'
      else
        if (BlockNo = (Blocks-1)) then
          FilesToSend.Cells[3,i] := '100%'
        else
          FilesToSend.Cells[3,i] := GetPercent(BlockSize,BlockNo,FullSize);
    end;
end;

function TForm1.FileIndex(const FileName: AnsiString): Integer;
var
  i:          Integer;
begin
  Result := 0;
  for i:=1 to FilesToSend.RowCount-1 do
    if AnsiEndsStr(FileName,FilesToSend.Cells[1,i]) then
     begin
      Result := i;
      break;
     end;
end;

procedure TForm1.MsgClient1ReceiveFile(const FromUserID, FileID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const FileName: AnsiString;
  FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
var
  i:          Integer;
  RecParams:  PRecParams;
begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - STARTED');
aaWriteToLog('TMsgClient2ReceiveMessage - BlockNo='+IntToStr(BlockNo));
aaWriteToLog('TMsgClient2ReceiveMessage - FileName="'+FileName+'"');
{$ENDIF}
  if FileName = '' then
    Exit;
  i := FileIndex(FileName);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - FileIndexed');
{$ENDIF}
  if i<=0 then
   begin
    Log.Lines.Add('ERROR: Client1 received file "'+FileName+
                '" size of '+IntToStr(FullSize)+' that has not been sent.');
    Exit;
   end;
  if i>Length(Rec) then
   begin
    Log.Lines.Add('ERROR: Client1: i = '+IntToStr(i)+
                ' > files count = '+IntToStr(Length(Rec))+'!');
    Exit;
   end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - exceptions tested');
{$ENDIF}
  RecParams := Rec[i-1];
  if not RecParams.Receiving1 then
   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - true...');
{$ENDIF}
    RecParams.Receiving1 := True;
    RecParams.FileSize1 := FullSize;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - ReceiveFile...');
{$ENDIF}
    RecParams.Received1 := MsgClient1.ReceiveFile(FileID,MsgClient1.IncomingPath+FileName,TimeOut);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - CheckFile...');
{$ENDIF}
    CheckReceivedFile(i,1);
   end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient1ReceiveMessage - FINISHED');
{$ENDIF}
end;

procedure TForm1.MsgClient2ReceiveFile(const FromUserID, FileID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const FileName: AnsiString;
  FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
var
  found:      Boolean;
  i,j:        Integer;
  RecParams:  PRecParams;
begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - STARTED');
aaWriteToLog('TMsgClient2ReceiveMessage - BlockNo='+IntToStr(BlockNo));
aaWriteToLog('TMsgClient2ReceiveMessage - FileName="'+FileName+'"');
{$ENDIF}
  if FileName = '' then
    Exit;
  i := FileIndex(FileName);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - FileIndexed');
{$ENDIF}
  if i<=0 then
   begin
    Log.Lines.Add('ERROR: Client2 received file "'+FileName+
                '" size of '+IntToStr(FullSize)+' that has not been sent.');
    Exit;
   end;
  if i>Length(Rec) then
   begin
    Log.Lines.Add('ERROR: Client2: i = '+IntToStr(i)+
                ' > files count = '+IntToStr(Length(Rec))+'!');
    Exit;
   end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - exceptions tested');
{$ENDIF}
  RecParams := Rec[i-1];
  if not RecParams.Receiving2 then
   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - true...');
{$ENDIF}
    RecParams.Receiving2 := True;
    RecParams.FileSize2 := FullSize;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - ReceiveFile...');
{$ENDIF}
    RecParams.Received2 := MsgClient2.ReceiveFile(FileID,MsgClient2.IncomingPath+FileName,TimeOut);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - CheckFile...');
{$ENDIF}
    CheckReceivedFile(i,2);
   end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgClient2ReceiveMessage - FINISHED');
{$ENDIF}
end;

procedure TForm1.CheckReceivedFile(i, client: Integer);
var
  str:        String;
  msgType:    TMsgDlgType;
  FileSize,
  Received:   Integer;
  RecParams:  PRecParams;
begin
  RecParams := Rec[i-1];
  if client = 1 then
   begin
    FileSize := RecParams.FileSize1;
    Received := RecParams.Received1;
   end
  else
   begin
    FileSize := RecParams.FileSize2;
    Received := RecParams.Received2;
   end;
  str := 'CLIENT # '+IntToStr(client)+'> File "'+MsgServer1.IncomingPath+FilesToSend.Cells[1,i]+'"';
  msgType := mtError;
  case Received of
   MSG_Error_ReceiveFile_NotExists  :
    str := str+' is not received! Error: File never came or is already received.';
   MSG_Error_ReceiveFile_DiskFull   :
    str := str+' is not received! Error: Not enough room on the target drive.';
   MSG_Error_ReceiveFile_FileExists :
    str := str+' is not received! Error: File with the same name is already existing.';
   MSG_Error_ReceiveFile_CannotCreateFile :
    str := str+' is not received! Error: Cannot create file with this name.';
   MSG_Error_ReceiveFile_TimeOut    :
    str := str+' is not received! Error: ReceiveFile exceeds TimeOut = '+IntToStr(TimeOut);
   MSG_Error_ReceiveFile_BlockSize  :
    str := str+' is not received! Error: Received block has the wrong size.';
  else
    if Received < 0 then
      str := str+' is not received! Error: Unknown error code = '+IntToStr(Received)
    else
    if Received <> FileSize then
      str := str+' received with wrong size = '+IntToStr(Received)+' bytes instead of orginal file size = '+IntToStr(FileSize)+' bytes.'
    else
     begin
      msgType := mtInformation;
      str := str+' is received! Size = '+IntToStr(Received)+' bytes.';
     end;
  end;
  Log.Lines.Add(str);
//  MessageDlg(str,msgType,[mbOK],0); // does not work in not main thread -- synchronization needed
end;

procedure TForm1.btnAddFileClick(Sender: TObject);
var
  fs:    TFileStream;
begin
  AddRow(FilesToSend,fFileName.Text);
  fs := TFileStream.Create(fFileName.Text,fmOpenRead or fmShareDenyWrite);
  try
   FilesToSend.Cells[2,FilesToSend.RowCount-1] := IntToStr(Round(fs.Size/1024));
  finally
   fs.Free;
  end;
  FilesToSend.Cells[3,FilesToSend.RowCount-1] := '0%';
end;

procedure TForm1.AddRow(Grid: TStringGrid; Str: String);
begin
  Grid.RowCount := Grid.RowCount + 1;
  if (Grid.RowCount = 2) then
    Grid.FixedRows := 1;
  Grid.Cells[0,Grid.RowCount-1] := IntToStr(Grid.RowCount-1);
  Grid.Cells[1,Grid.RowCount-1] := Str;
end;

function TForm1.GetPercent(BlockSize,BlockNo,FullSize: Integer): String;
var
  percent:    Integer;
begin
  percent := Round(BlockSize*(BlockNo+1)/FullSize*100);
  if percent > 100 then percent := 100;
  Result := IntToStr(percent)+'%';
end;

procedure TForm1.MsgServer1Error(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
  Log.Lines.Add(ErrorMessage);
end;

procedure TForm1.MsgClient2Error(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
  Log.Lines.Add(ErrorMessage);
end;

procedure TForm1.MsgClient1Error(Sender: TComponent; const ErrorCode,
  NativeError: Integer; const ErrorMessage: String);
begin
  Log.Lines.Add(ErrorMessage);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i:          Integer;
  RecParams:  PRecParams;
begin
  for i:=0 to Length(Rec)-1 do
   begin
    RecParams := Rec[i];
    Dispose(RecParams);
   end;
end;

end.
