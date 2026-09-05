unit Unit1;

interface

{$I ..\..\Ver.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, MsgClient, MsgComBase, MsgServer,
  MsgConst, MsgConnection;

type
  TForm1 = class(TForm)
    gbSendClient: TGroupBox;
    gbRecvClient: TGroupBox;
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
    lbFileName: TLabel;
    lbFileSize: TLabel;
    lbBlocks: TLabel;
    lbBlockSize: TLabel;
    btnConnect2: TButton;
    btnDisconnect2: TButton;
    btnAllowDirect: TButton;
    rbDirectly: TRadioButton;
    rbThruServer: TRadioButton;
    ProgressBar1: TProgressBar;
    Speed: TLabel;
    lbRecvBytes: TLabel;
    lbSpeed: TLabel;
    ProgressBar2: TProgressBar;
    btnConnectDirectly: TButton;
    btnConnect1: TButton;
    btnDisconnect1: TButton;
    btnDiconnectDirectly: TButton;
    FileName: TEdit;
    btnBrowse: TButton;
    MsgServer1: TMsgServer;
    MsgClient1: TMsgClient;
    MsgClient2: TMsgClient;
    btnForbidRecv: TButton;
    btnAllowRecv: TButton;
    btnForbidDirect: TButton;
    btnForbidFiles: TButton;
    SendPercent: TLabel;
    RecvPercent: TLabel;
    lbDirectly: TLabel;
    lbBlockNo: TLabel;
    btnSaveFile: TButton;
    btnReceiveFile: TButton;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnConnect1Click(Sender: TObject);
    procedure btnDisconnect1Click(Sender: TObject);
    procedure btnConnectDirectlyClick(Sender: TObject);
    procedure btnDiconnectDirectlyClick(Sender: TObject);
    procedure rbDirectlyClick(Sender: TObject);
    procedure rbThruServerClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnAllowDirectClick(Sender: TObject);
    procedure btnAllowFilesClick(Sender: TObject);
    procedure btnAllowRecvClick(Sender: TObject);
    procedure btnConnect2Click(Sender: TObject);
    procedure btnDisconnect2Click(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnForbidDirectClick(Sender: TObject);
    procedure MsgClient1SendFile(const ToUserID, FileID: Cardinal;
      const FileName: AnsiString; FullSize: Int64;
      BlockSize, BlockNo, Blocks: Integer);
    procedure MsgClient2ReceiveFile(const FromUserID, FileID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const FileName: AnsiString;
      FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
    procedure btnReceiveFileClick(Sender: TObject);
    procedure btnForbidFilesClick(Sender: TObject);
    procedure btnForbidRecvClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


  TSendDisplayThread = class (TThread)
   protected
     FProgressBar1Position: Integer;
     FSendPercentCaption:   AnsiString;
     FSpeedCaption:         AnsiString;
   public
     procedure DisplayMessage;
     procedure Execute; override;
  end;

  TReceiveDisplayThread = class (TThread)
   protected
     FlbDirectlyCaption:     AnsiString;
     FlbFileNameCaption:     AnsiString;
     FlbFileSizeCaption:     AnsiString;
     FlbBlocksCaption:       AnsiString;
     FlbBlockSizeCaption:    AnsiString;
     FlbBlockNoCaption:      AnsiString;
     FlbRecvBytesCaption:    AnsiString;
     FProgressBar2Position:  Integer;
     FRecvPercentCaption:    AnsiString;
     FlbSpeedCaption:        AnsiString;
   public
     procedure DisplayMessage;
     procedure Execute; override;
  end;

var
  Form1:            TForm1;
  SendStartTime:    Integer;
  aaFileID:         Cardinal;
  aaFileName:       AnsiString;
  RecvBlocks:       Integer;
  StartDate:        TDateTime;

implementation

{$R *.dfm}

procedure TSendDisplayThread.DisplayMessage;
begin
  Form1.ProgressBar1.Position := FProgressBar1Position;
  Form1.SendPercent.Caption := FSendPercentCaption;
  Form1.Speed.Caption := FSpeedCaption;
end;

procedure TSendDisplayThread.Execute;
begin
  Synchronize(DisplayMessage);
end;


procedure TReceiveDisplayThread.DisplayMessage;
begin
  Form1.lbDirectly.Caption := FlbDirectlyCaption;
  Form1.lbFileName.Caption := FlbFileNameCaption;
  Form1.lbFileSize.Caption := FlbFileSizeCaption;
  Form1.lbBlocks.Caption := FlbBlocksCaption;
  Form1.lbBlockNo.Caption := FlbBlockNoCaption;
  Form1.lbBlockSize.Caption := FlbBlockSizeCaption;
  Form1.lbRecvBytes.Caption := FlbRecvBytesCaption;
  Form1.ProgressBar2.Position := FProgressBar2Position;
  Form1.RecvPercent.Caption := FRecvPercentCaption;
  Form1.lbSpeed.Caption := FlbSpeedCaption;
end;

procedure TReceiveDisplayThread.Execute;
begin
  Synchronize(DisplayMessage);
end;


procedure TForm1.btnBrowseClick(Sender: TObject);
var
  fs:    TFileStream;
begin
  if not OpenDialog1.Execute then
    Exit;
  FileName.Text := OpenDialog1.FileName;
  fs := TFileStream.Create(FileName.Text,fmOpenRead or fmShareDenyWrite);
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

procedure TForm1.btnConnectDirectlyClick(Sender: TObject);
begin
  if btnConnectDirectly.Enabled then
   begin
    MsgClient1.ConnectDirectly(MsgClient2.UserID);
    btnConnectDirectly.Enabled := False;
    btnDiconnectDirectly.Enabled := True;
   end;
end;

procedure TForm1.btnDiconnectDirectlyClick(Sender: TObject);
begin
  MsgClient1.DisconnectAll;
  btnConnectDirectly.Enabled := True;
  btnDiconnectDirectly.Enabled := False;
end;

procedure TForm1.rbDirectlyClick(Sender: TObject);
begin
  if rbThruServer.Checked then
    rbThruServer.Checked := False;
end;

procedure TForm1.rbThruServerClick(Sender: TObject);
begin
  if rbDirectly.Checked then
    rbDirectly.Checked := False;
end;

procedure TForm1.btnSendClick(Sender: TObject);
var
  Directly:     Boolean;
begin
  if rbDirectly.Checked then
   begin
    btnConnectDirectlyClick(self);
    Directly := True;
   end
  else
    Directly := False;
  ProgressBar1.Position := 0;
  SendPercent.Caption := '';
  RecvPercent.Caption := '';
  lbDirectly.Caption := '';
  lbFileName.Caption := 'File: ';
  lbFileSize.Caption := 'Size: ';
  lbBlocks.Caption := 'Blocks: ';
  lbBlockSize.Caption := 'Block Size: ';
  lbBlockNo.Caption := 'Block No: ';
  lbRecvBytes.Caption := 'Saved: ';
  aaFileID := MSG_INVALID_ID;
  aaFileName := '';
  RecvBlocks := 0;
  MsgClient1.SendFile(MsgClient2.UserID,AnsiString(FileName.Text),StrToIntDef(Blocks.Text,0),StrToIntDef(BlockSize.Text,0),Directly);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  UserInfo:     TMsgUserInfo;
  fs:           TFileStream;
begin
 try
  FileName.Text := ParamStr(0);
  fs := TFileStream.Create(FileName.Text,fmOpenRead or fmShareDenyWrite);
  try
   FileSize.Caption := 'Size: ' + IntToStr(fs.Size)+ ' bytes';
  finally
   fs.Free;
  end;
  aaFileID := MSG_INVALID_ID;
  aaFileName := '';
  btnStartClick(self);
  btnAllowFilesClick(self);
  btnAllowDirectClick(self);
  btnAllowRecvClick(self);
  btnConnect1Click(self);
  UserInfo.UserID := MSG_INVALID_USER_ID;
  UserInfo.UserName := 'User1';
  MsgClient1.RegisterNewUser(UserInfo);
  btnConnect2Click(self);
  UserInfo.UserName := 'User2';
  MsgClient2.RegisterNewUser(UserInfo);
  btnConnectDirectlyClick(self);
  StartDate := 0;
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_NETWORK_ONDISCONNECT}
aaWriteToLog('Main Thread Error: '+E.Message);
{$ENDIF}
    raise;
   end;
 end;
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  MsgServer1.ClearAll;
  MsgServer1.Active := True;
  btnStart.Enabled := False;
  btnStop.Enabled := True;
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  MsgServer1.Active := False;
  btnStart.Enabled := True;
  btnStop.Enabled := False;
  btnConnect1.Enabled := True;
  btnDisconnect1.Enabled := False;
  btnConnect2.Enabled := True;
  btnDisconnect2.Enabled := False;
end;

procedure TForm1.btnAllowDirectClick(Sender: TObject);
begin
  MsgClient2.AllowDirectly := True;
  btnAllowDirect.Enabled := False;
  btnForbidDirect.Enabled := True;
end;

procedure TForm1.btnForbidDirectClick(Sender: TObject);
begin
  MsgClient2.AllowDirectly := True;
  btnAllowDirect.Enabled := True;
  btnForbidDirect.Enabled := False;
end;

procedure TForm1.btnAllowFilesClick(Sender: TObject);
begin
  MsgServer1.AllowFiles := True;
  btnAllowFiles.Enabled := False;
  btnForbidFiles.Enabled := True;
end;

procedure TForm1.btnAllowRecvClick(Sender: TObject);
begin
  MsgClient2.AllowFiles := True;
  btnAllowRecv.Enabled := False;
  btnForbidRecv.Enabled := True;
end;

procedure TForm1.btnConnect2Click(Sender: TObject);
begin
  MsgClient2.Connect;
  if MsgClient2.Connected then
   begin
    btnConnect2.Enabled := False;
    btnDisconnect2.Enabled := True;
   end;
end;

procedure TForm1.btnDisconnect2Click(Sender: TObject);
begin
  MsgClient2.Disconnect;
  MsgClient2.Active := False;
  MsgClient2.UserID := 2; // fix if previously not logged
  if not MsgClient2.Connected then
   begin
    btnConnect2.Enabled := True;
    btnDisconnect2.Enabled := False;
   end;
end;

procedure TForm1.MsgClient1SendFile(const ToUserID, FileID: Cardinal;
  const FileName: AnsiString; FullSize: Int64;
   BlockSize, BlockNo, Blocks: Integer);
var
  Percent:     Integer;
  n:           Cardinal;
  x,x1,x2:     Extended;
  spd:         Int64;
  dispThread:  TSendDisplayThread;
begin
  dispThread := TSendDisplayThread.Create(true);
  dispThread.FSpeedCaption := '';
  if (BlockNo < 0) then
   begin
    SendStartTime := GetTickCount;
    StartDate := 0;
    if (FullSize <= 0) then
     begin
      Percent := 100;
      dispThread.FProgressBar1Position := 100;
     end
    else
     begin
      Percent := 0;
      dispThread.FProgressBar1Position := 1;
     end;
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
    dispThread.FSpeedCaption := 'Speed: '+ IntToStr(spd)+ ' bytes per sec';
{
    Speed.Caption := 'Speed: '
      + IntToStr(Trunc(0.5+((BlockSize*(BlockNo+1))/((GetTickCount-SendStartTime)/1000))))
      +' bytes per sec';
}
    if (BlockNo = (Blocks-1)) then
      Percent := 100
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
//      Percent := Trunc((BlockNo+1) * BlockSize / FullSize * 100 + 0.5);
     end;
    dispThread.FProgressBar1Position := Percent;
   end;
  dispThread.FSendPercentCaption := IntToStr(Percent)+'%';
  dispThread.Resume;
end;


procedure TForm1.MsgClient2ReceiveFile(const FromUserID, FileID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const FileName: AnsiString;
  FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
var
  BytesSaved,
  Time:       Extended;
  Percent:    Integer;
  dispThread: TReceiveDisplayThread;
begin
  inc(RecvBlocks);
  dispThread := TReceiveDisplayThread.Create(True);
  dispThread.FlbDirectlyCaption := '';
  dispThread.FlbFileNameCaption := '';
  dispThread.FlbFileSizeCaption := '';
  dispThread.FlbBlocksCaption := '';
  dispThread.FlbBlockSizeCaption := '';
  dispThread.FlbBlockNoCaption := '';
  dispThread.FlbRecvBytesCaption := '';
  dispThread.FProgressBar2Position := 0;
  dispThread.FRecvPercentCaption := '';
  dispThread.FlbSpeedCaption := '';
  if aaFileID = MSG_INVALID_ID then
    aaFileID := FileID;
  if aaFileName = '' then
    aaFileName := FileName;
  if StartDate = 0 then
    StartDate := DeliveryDate;

  if Directly then
    dispThread.FlbDirectlyCaption := 'Directly'
  else
    dispThread.FlbDirectlyCaption := 'Thru Server';
  dispThread.FlbFileNameCaption := 'File: '+FileName;
  if FullSize >= 0 then
    dispThread.FlbFileSizeCaption := 'Size: '+IntToStr(FullSize)+' bytes';
  if Blocks >= 0 then
    dispThread.FlbBlocksCaption := 'Blocks: '+IntToStr(Blocks);
  if BlockSize >= 0 then
    dispThread.FlbBlockSizeCaption := 'Block Size: '+IntToStr(BlockSize)+' bytes';
  if BlockNo >= 0 then
    dispThread.FlbBlockNoCaption := 'Block No: '+IntToStr(BlockNo);
  BytesSaved := Int64(RecvBlocks * BlockSize);
  if BytesSaved > FullSize then
    BytesSaved := FullSize;
  if BytesSaved >= 0 then
    dispThread.FlbRecvBytesCaption := 'Saved: '+IntToStr(Round(BytesSaved))+' bytes';

  Time := Trunc((DeliveryDate - StartDate)*24*60*60*1000 + 0.5); // msec
  if Time = 0 then
    Time := 1;
  if (BlockNo < 0)
  or (FullSize < 0)
  or (Blocks < 0)
  then
   begin
    if FullSize > 0 then
     begin
      Percent := 0;
      dispThread.FProgressBar2Position := 1;
     end
    else
     begin
      Percent := 100;
      dispThread.FProgressBar2Position := 100;
     end;
   end
  else
   begin
    dispThread.FlbSpeedCaption := 'Speed: '
      + IntToStr(Trunc(0.5+((BytesSaved)/(Time/1000))))
      +' bytes per sec';
    if FullSize > 0 then
      Percent := Trunc(BytesSaved / FullSize * 100 + 0.5)
    else
      Percent := 100;
    dispThread.FProgressBar2Position := Percent;
   end;
  dispThread.FRecvPercentCaption := IntToStr(Percent)+'%';
  dispThread.Resume;
end;

procedure TForm1.btnReceiveFileClick(Sender: TObject);
var
  str,
  PathName:     AnsiString;
  Received:     Integer;
  msgType:      TMsgDlgType;
  TimeOut:      Integer;
begin
  TimeOut := 60000; // 1 minute
  PathName := MsgClient2.IncomingPath+aaFileName;
  Received := MsgClient2.ReceiveFile(aaFileID, PathName, TimeOut);
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
    if Received >= 0 then
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

procedure TForm1.btnForbidRecvClick(Sender: TObject);
begin
  MsgClient2.AllowFiles := False;
  btnAllowRecv.Enabled := True;
  btnForbidRecv.Enabled := False;
end;

end.
