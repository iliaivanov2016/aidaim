unit Unit1;

interface

uses

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, MsgClient, MsgComBase, MsgServer,
  MsgConst, MsgConnection;

type
  TForm1 = class(TForm)
    gbSendClient: TGroupBox;
    gbServer: TGroupBox;
    btnStart: TButton;
    btnStop: TButton;
    btnAllowFiles: TButton;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    label3: TLabel;
    FileSize: TLabel;
    llabel4: TLabel;
    Blocks: TEdit;
    BlockSize: TEdit;
    btnSend: TButton;
    ProgressBar1: TProgressBar;
    Speed: TLabel;
    btnConnect1: TButton;
    btnDisconnect1: TButton;
    btnBrowse: TButton;
    MsgServer1: TMsgServer;
    MsgClient1: TMsgClient;
    btnForbidFiles: TButton;
    SendPercent: TLabel;
    lbFileName: TLabel;
    lbFileSize: TLabel;
    lbBlocks: TLabel;
    lbBlockSize: TLabel;
    lbBlockNo: TLabel;
    lbRecvBytes: TLabel;
    lbSpeed: TLabel;
    btnSaveFile: TButton;
    btnReceiveFile: TButton;
    ProgressBar2: TProgressBar;
    RecvPercent: TLabel;
    fFileName: TEdit;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnConnect1Click(Sender: TObject);
    procedure btnDisconnect1Click(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnAllowFilesClick(Sender: TObject);
    procedure btnForbidFilesClick(Sender: TObject);
    procedure MsgClient1SendFile(const ToUserID, FileID: Cardinal;
      const FileName: String; FullSize: Int64;
      BlockSize, BlockNo, Blocks: Integer);
    procedure MsgServer1ReceiveFile(const FromUserID, FileID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const FileName: String;
      FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
    procedure btnReceiveFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1:            TForm1;
  SendStartTime:    Integer;
  aaFileID:         Cardinal;
  aaFileName:       String;
  StartDate:        TDateTime;
  ReceivedBlocks:   Integer;

implementation

{$R *.dfm}

procedure TForm1.btnBrowseClick(Sender: TObject);
var
  fs:    TFileStream;
begin
  if not OpenDialog1.Execute then
    Exit;
  fFileName.Text := OpenDialog1.FileName;
  fs := TFileStream.Create(fFileName.Text,fmOpenRead or fmShareDenyWrite);
  try
   FileSize.Caption := 'Size: ' + IntToStr(fs.Size)+ ' bytes';
  finally
   fs.Free;
  end;
end;

procedure TForm1.btnConnect1Click(Sender: TObject);
begin
  MsgClient1.Connect;
  btnConnect1.Enabled := False;
  btnDisconnect1.Enabled := True;
end;

procedure TForm1.btnDisconnect1Click(Sender: TObject);
begin
  MsgClient1.Disconnect;
  btnConnect1.Enabled := True;
  btnDisconnect1.Enabled := False;
end;

procedure TForm1.btnSendClick(Sender: TObject);
begin
  ReceivedBlocks := -1; 
  ProgressBar1.Position := 0;
  SendPercent.Caption := '';
  RecvPercent.Caption := '';
  lbFileName.Caption := 'File: ';
  lbFileSize.Caption := 'Size: ';
  lbBlocks.Caption := 'Blocks: ';
  lbBlockSize.Caption := 'Block Size: ';
  lbBlockNo.Caption := 'Block No: ';
  lbRecvBytes.Caption := 'Saved: ';
  aaFileID := MSG_INVALID_ID;
  aaFileName := '';
  MsgClient1.SendFile(MsgServer1.ServerID,fFileName.Text,StrToIntDef(Blocks.Text,0),StrToIntDef(BlockSize.Text,0),false);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  UserInfo:     TMsgUserInfo;
begin
  aaFileID := MSG_INVALID_ID;
  aaFileName := '';
  ReceivedBlocks := -1;
  MsgServer1.IncomingPath := '.\Incoming\';
  DeleteFileA(PAnsiChar(MsgServer1.IncomingPath+'*.*'));
  btnStartClick(self);
  btnAllowFilesClick(self);
  MsgClient1.ConnectionParams.NetworkSettings.UseServerSettings := false;
  btnConnect1Click(self);
  UserInfo.UserID := MSG_INVALID_USER_ID;
  UserInfo.UserName := 'User1';
  MsgClient1.RegisterNewUser(UserInfo);
  StartDate := 0;
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  MsgServer1.ClearAll;
  MsgServer1.Active := True;
  btnStart.Enabled := False;
  btnStop.Enabled := True;
  ReceivedBlocks := -1;
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  MsgServer1.Active := False;
  btnStart.Enabled := True;
  btnStop.Enabled := False;
  btnConnect1.Enabled := True;
  btnDisconnect1.Enabled := False;
end;

procedure TForm1.btnAllowFilesClick(Sender: TObject);
begin
  MsgServer1.AllowFiles := True;
  btnAllowFiles.Enabled := False;
  btnForbidFiles.Enabled := True;
end;

procedure TForm1.MsgClient1SendFile(const ToUserID, FileID: Cardinal;
  const FileName: AnsiString; FullSize: Int64;
   BlockSize, BlockNo, Blocks: Integer);
var
  Percent:     Integer;
  n:           Cardinal;
  x,x1,x2:     Extended;
  spd:         Int64;
begin
  if (BlockNo < 0) then
   begin
    SendStartTime := GetTickCount;
    StartDate := 0;
    ProgressBar1.Position := 1;
    SendPercent.Caption := '0%'
   end
  else
   begin
    n := GetTickCount-Cardinal(SendStartTime);
    x := Int64(BlockSize)*Int64(BlockNo+1);
    if (n <= 0) then
     spd := 0
    else
     begin
      x1 := n;
      x2 := 1000.0;
      spd := Round(x/(x1/x2));
     end;
    Speed.Caption := 'Speed: '+ IntToStr(spd)+ ' bytes per sec';
{
    Speed.Caption := 'Speed: '
      + IntToStr(Trunc(0.5+((BlockSize*(BlockNo+1))/((GetTickCount-SendStartTime)/1000))))
      +' bytes per sec';
}
    if (BlockNo = (Blocks-1)) then
     begin
      ProgressBar1.Position := 100;
      SendPercent.Caption := '100%'
     end
    else
     begin
      if (FullSize <= 0) then
       Percent := 100
      else
       begin
        x1 := FullSize;
        x2 := 100.0;
        Percent := Round(x/x1*x2);
       end;
      SendPercent.Caption := IntToStr(Percent)+'%';
      ProgressBar1.Position := Percent;
     end;
   end;
end;

procedure TForm1.MsgServer1ReceiveFile(const FromUserID, FileID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const FileName: AnsiString;
  FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
var
  BytesSaved,
  Time:       Extended;
  Percent:    Integer;
begin
  inc(ReceivedBlocks);
  if (aaFileID = MSG_INVALID_ID)
  and (FileName <> '')
  then
    aaFileID := FileID;
  if (aaFileName = '')
  and (FileName <> '')
  then
    aaFileName := FileName;
  if StartDate = 0 then
    StartDate := DeliveryDate;
  Form1.lbFileName.Caption := 'File: '+aaFileName;
  if FullSize >= 0 then
    Form1.lbFileSize.Caption := 'Size: '+IntToStr(FullSize)+' bytes';
  if Blocks >= 0 then
    Form1.lbBlocks.Caption := 'Blocks: '+IntToStr(Blocks);
  if BlockSize >= 0 then
    Form1.lbBlockSize.Caption := 'Block Size: '+IntToStr(BlockSize)+' bytes';
  if BlockNo >= 0 then
    Form1.lbBlockNo.Caption := 'Block No: '+IntToStr(BlockNo);
  BytesSaved := Int64(ReceivedBlocks) * Int64(BlockSize);
  if BytesSaved > FullSize then
  if FullSize > 0 then
    BytesSaved := FullSize;
  if BytesSaved >= 0 then
    Form1.lbRecvBytes.Caption := 'Saved: '+IntToStr(Round(BytesSaved))+' bytes';
  Time := Trunc((DeliveryDate - StartDate)*24*60*60*1000 + 0.5); // msec
  if Time <= 0 then
    Time := 1;
  if FullSize <= 0 then
    FullSize := 1;
  if (BlockNo < 0)
  or (FullSize < 0)
  or (Blocks < 0)
  then
   begin
    Form1.ProgressBar2.Position := 1;
    Form1.RecvPercent.Caption := '0%'
   end
  else
   begin
    Form1.lbSpeed.Caption := 'Speed: '
      + IntToStr(Trunc(0.5+((BytesSaved)/(Time/1000))))
      +' bytes per sec';
    if (BytesSaved > 0) then
      Percent := Trunc(BytesSaved / FullSize * 100 + 0.5)
    else
      Percent := 0;
    if Form1.ProgressBar2.Position < Percent then // to avoid reducing when logon during sending
     begin
      Form1.RecvPercent.Caption := IntToStr(Percent)+'%';
      Form1.ProgressBar2.Position := Percent;
     end;
   end;
end;

procedure TForm1.btnReceiveFileClick(Sender: TObject);
var
  str,
  PathName:     String;
  Received:     Integer;
  msgType:      TMsgDlgType;
  TimeOut:      Integer;
begin
  TimeOut := 60000; // 1 minute
  PathName := MsgServer1.IncomingPath+aaFileName;
  Received := MsgServer1.ReceiveFile(aaFileID, PathName, TimeOut);
  str := 'File '+PathName;
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
    if Received > 0 then
     begin
      msgType := mtInformation;
      str := str+' is successfully received! Size = '+IntToStr(Received)+' bytes.';
     end
    else
      str := str+' is not received! Error: Unknown error code = '+IntToStr(Received);
  end;
  MessageDlg(str,msgType,[mbOK],0);
end;

procedure TForm1.btnForbidFilesClick(Sender: TObject);
begin
  MsgServer1.AllowFiles := False;
  btnAllowFiles.Enabled := True;
  btnForbidFiles.Enabled := False;
end;

end.
