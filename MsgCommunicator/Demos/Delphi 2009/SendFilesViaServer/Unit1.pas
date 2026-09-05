unit Unit1;

interface

uses

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, MsgClient, MsgComBase,
  MsgConst, MsgConnection, Grids, DBGrids, StrUtils;

const
  TimeOut = 1800000; // 30 minutes
  Blocks = -1;
  BlockSize = 11647; //  8 packets in a block
           // 14565; // 10 packets in a block
  Directly = False;

type
  TForm1 = class(TForm)
    gbSendClient: TGroupBox;
    gbServer: TGroupBox;
    btnAllowFiles: TButton;
    OpenDialog1: TOpenDialog;
    Label1: TLabel;
    btnSend: TButton;
    btnBrowse: TButton;
    MsgClient1: TMsgClient;
    btnForbidFiles: TButton;
    btnSaveFile: TButton;
    btnReceiveFile: TButton;
    fFileName: TEdit;
    btnAddFile: TButton;
    Label2: TLabel;
    Label3: TLabel;
    FilesToSend: TStringGrid;
    FilesToReceive: TStringGrid;
    GroupBox1: TGroupBox;
    btnConnect1: TButton;
    btnDisconnect1: TButton;
    Label4: TLabel;
    Label5: TLabel;
    edRemoteHost: TEdit;
    edRemotePort: TEdit;
    Label6: TLabel;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnConnect1Click(Sender: TObject);
    procedure btnDisconnect1Click(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAllowFilesClick(Sender: TObject);
    procedure btnForbidFilesClick(Sender: TObject);
    procedure MsgClient1SendFile(const ToUserID, FileID: Cardinal;
      const FileName: String; FullSize: Int64;
      BlockSize, BlockNo, Blocks: Integer);
    procedure MsgClient1ReceiveFile(const FromUserID, FileID: Cardinal;
      const SendingDate, DeliveryDate: TDateTime; const FileName: String;
      FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
    procedure btnReceiveFileClick(Sender: TObject);
    procedure btnAddFileClick(Sender: TObject);
    procedure AddRow(Grid: TStringGrid; Str: String; FileID: Cardinal = MSG_INVALID_ID);
    function GetPercent(BlockSize,BlockNo,FullSize: Integer): String;
    function CheckPercent(str1,str2:String): Boolean;
    procedure MsgClient1SendFileFailed(const ToUserID, FileID: Cardinal;
      const FileName: String; FullSize: Int64; BlockSize, BlockNo,
      Blocks: Integer);
  private
    { Private declarations }
  public
    Received: array of  Integer;
    Receiving: array of Boolean;
  end;

  TSendFileThread = class(TThread)
  private
      FileName: String;
      FileID: Cardinal;
      FullSize: Int64;
      BlockSize, BlockNo, Blocks: Integer;
  protected
    procedure DisplaySending;
    procedure Execute; override;
  public
    constructor Create(
      aFileName: String;
      aFileID: Cardinal;
      aFullSize: Int64;
      aBlockSize, aBlockNo, aBlocks: Integer
                       );
  end;

  TReceiveFileThread = class(TThread)
  private
      FileName: String;
      FileID: Cardinal;
      FullSize: Int64;
      BlockSize, BlockNo, Blocks,
      i: Integer;
  protected
    procedure DisplayReceiving;
    procedure Execute; override;
  public
    constructor Create(
      aFileName: String;
      aFileID: Cardinal;
      aFullSize: Int64;
      aBlockSize, aBlockNo, aBlocks: Integer
                       );
  end;

var
  Form1:              TForm1;

implementation

{$R *.dfm}

constructor TSendFileThread.Create(
      aFileName: String;
      aFileID: Cardinal;
      aFullSize: Int64;
      aBlockSize, aBlockNo, aBlocks: Integer
                                      );
begin
  FileName := aFileName;
  FileID := aFileID;
  FullSize := aFullSize;
  BlockSize := aBlockSize;
  BlockNo := aBlockNo;
  Blocks := aBlocks;
  inherited Create(False);
end;

procedure TSendFileThread.Execute;
begin
  Synchronize(DisplaySending);
end;

procedure TSendFileThread.DisplaySending;
var
  i:        Integer;
  percent:  String;
begin
  for i:=1 to Form1.FilesToSend.RowCount-1 do
   if (Pos(FileName,Form1.FilesToSend.Cells[1,i]) > 0) then
    begin
      if (FileName <> Form1.FilesToSend.Cells[1,i]) then
        Form1.FilesToSend.Cells[1,i] := FileName;
      if (BlockNo < 0) then
        Form1.FilesToSend.Cells[3,i] := '0%'
      else
        if (BlockNo = (Blocks-1)) then
          Form1.FilesToSend.Cells[3,i] := '100%'
        else
         begin
          percent := Form1.GetPercent(BlockSize,BlockNo,FullSize);
          if Form1.CheckPercent(Form1.FilesToSend.Cells[3,i],percent) then
            Form1.FilesToSend.Cells[3,i] := percent;
         end;
    end;
end;

constructor TReceiveFileThread.Create(
      aFileName: String;
      aFileID: Cardinal;
      aFullSize: Int64;
      aBlockSize, aBlockNo, aBlocks: Integer
                                      );
begin
  FileName := aFileName;
  FileID := aFileID;
  FullSize := aFullSize;
  BlockSize := aBlockSize;
  BlockNo := aBlockNo;
  Blocks := aBlocks;
  inherited Create(False);
end;

procedure TReceiveFileThread.Execute;
begin
  Synchronize(DisplayReceiving);
  if not Form1.Receiving[i-1] then
   begin
    Form1.Receiving[i-1] := True;
    if (FileName <> '') then
      Form1.Received[i-1] := Form1.MsgClient1.ReceiveFile(FileID,Form1.MsgClient1.IncomingPath+FileName,TimeOut)
    else
      Form1.Received[i-1] := Form1.MsgClient1.ReceiveFile(FileID,Form1.MsgClient1.IncomingPath+Form1.FilesToReceive.Cells[1,i],TimeOut);
   end
end;

procedure TReceiveFileThread.DisplayReceiving;
var
  found:    Boolean;
  j:        Integer;
  percent:  String;
begin
  if (BlockNo = -1) then // init event
   begin
    Form1.AddRow(Form1.FilesToReceive, FileName, FileID);
    i := Form1.FilesToReceive.RowCount-1;
    found := true;
   end
  else
   begin
    found := false;
    for j:=1 to Form1.FilesToReceive.RowCount-1 do
     begin
      if (StrToInt64(Form1.FilesToReceive.Cells[1,j]) = Int64(FileID)) then
       begin
        found := true;
        i := j;
        break;
       end;
     end;
    if not found then // error - strange file arrives
     begin
      Form1.AddRow(Form1.FilesToReceive, FileName, FileID);
      found := true;
      i := Form1.FilesToReceive.RowCount-1;
     end;
   end;
  if found then
   begin
    if FullSize >= 0 then
     if BlockNo < 0 then
      begin
       Form1.FilesToReceive.Cells[3,i] := IntToStr(Round(FullSize/1024));
       Form1.FilesToReceive.Cells[4,i] := '0%';
      end;
    if BlockNo >= 0 then
     begin
      percent := Form1.GetPercent(BlockSize,BlockNo,FullSize);
      if Form1.CheckPercent(Form1.FilesToReceive.Cells[4,i],percent) then
        Form1.FilesToReceive.Cells[4,i] := percent;
     end;
   end;
end;

procedure TForm1.btnBrowseClick(Sender: TObject);
begin
  if not OpenDialog1.Execute then
    Exit;
  fFileName.Text := OpenDialog1.FileName;
end;

procedure TForm1.btnConnect1Click(Sender: TObject);
var
  UserInfo:     TMsgUserInfo;
begin
  MsgClient1.ConnectionParams.RemoteHost := edRemoteHost.Text;
  MsgClient1.ConnectionParams.RemotePort := StrToInt(edRemotePort.Text);
  MsgClient1.Connect;
  UserInfo.UserID := MSG_INVALID_USER_ID;
  UserInfo.UserName := 'User1';
  MsgClient1.RegisterNewUser(UserInfo);
  btnConnect1.Enabled := False;
  btnDisconnect1.Enabled := True;
  btnSend.Enabled := True;
  FilesToSend.RowCount := 1;
end;

procedure TForm1.btnDisconnect1Click(Sender: TObject);
begin
  MsgClient1.Disconnect;
  btnConnect1.Enabled := True;
  btnDisconnect1.Enabled := False;
  btnSend.Enabled := False;
end;

procedure TForm1.btnSendClick(Sender: TObject);
var
  I:      Integer;
begin
  SetLength(Received, FilesToSend.RowCount-1);
  for i:=0 to Length(Received)-1 do
    Received[i] := 0;
  SetLength(Receiving, FilesToSend.RowCount-1);
  for i:=0 to Length(Receiving)-1 do
    Receiving[i] := False;
  for i:=1 to FilesToSend.RowCount-1 do
    MsgClient1.SendFile(MsgClient1.UserID,FilesToSend.Cells[1,i],Blocks,BlockSize,Directly);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MsgClient1.IncomingPath := '.\Incoming\';
  DeleteFileA(PAnsiChar(MsgClient1.IncomingPath+'*.*'));
  btnAllowFilesClick(self);
  MsgClient1.ConnectionParams.NetworkSettings.UseServerSettings := false;
  btnSend.Enabled := False;
  try
   btnConnect1Click(self);
  except
  end;
  FilesToSend.ColWidths[0] := 18;
  FilesToSend.ColWidths[1] := 145;
  FilesToSend.ColWidths[2] := 45;
  FilesToSend.ColWidths[3] := 30;
  FilesToReceive.ColWidths[0] := 18;
  FilesToReceive.ColWidths[1] := 65;
  FilesToReceive.ColWidths[2] := 100;
  FilesToReceive.ColWidths[3] := 45;
  FilesToReceive.ColWidths[4] := 30;
  FilesToSend.Cells[0,0] := '#';
  FilesToSend.Cells[1,0] := 'Name';
  FilesToSend.Cells[2,0] := 'Size, KB';
  FilesToSend.Cells[3,0] := 'Sent';
  FilesToReceive.Cells[0,0] := '#';
  FilesToReceive.Cells[1,0] := 'FileID';
  FilesToReceive.Cells[2,0] := 'Name';
  FilesToReceive.Cells[3,0] := 'Size, KB';
  FilesToReceive.Cells[4,0] := 'Got';
end;

procedure TForm1.btnAllowFilesClick(Sender: TObject);
begin
  MsgClient1.AllowFiles := True;
  btnAllowFiles.Enabled := False;
  btnForbidFiles.Enabled := True;
  FilesToReceive.RowCount := 1;
end;

procedure TForm1.MsgClient1SendFile(const ToUserID, FileID: Cardinal;
  const FileName: String; FullSize: Int64;
   BlockSize, BlockNo, Blocks: Integer);
var
  i,
  percent:    Integer;
begin
  TSendFileThread.Create(FileName,FileID,FullSize,BlockSize,BlockNo,Blocks);
end;

procedure TForm1.MsgClient1ReceiveFile(const FromUserID, FileID: Cardinal;
  const SendingDate, DeliveryDate: TDateTime; const FileName: String;
  FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean);
begin
{$IFDEF DEBUG_LOG}
aaWriteToLog('FileName = '+FileName);
aaWriteToLog('FileID = '+IntToStr(FileID));
aaWriteToLog('FullSize = '+IntToStr(FullSize));
aaWriteToLog('BlockSize = '+IntToStr(BlockSize));
aaWriteToLog('BlockNo = '+IntToStr(BlockNo));
aaWriteToLog('Blocks = '+IntToStr(Blocks));
{$ENDIF}
  TReceiveFileThread.Create(FileName,FileID,FullSize,BlockSize,BlockNo,Blocks);
end;

procedure TForm1.btnReceiveFileClick(Sender: TObject);
var
  str:      String;
  msgType:  TMsgDlgType;
  i:        Integer;
begin
  for i:=0 to length(Received)-1 do
   begin
    str := 'File "'+MsgClient1.IncomingPath+FilesToReceive.Cells[2,i+1]+'"';
    msgType := mtError;
    case Received[i] of
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
      if Received[i] > 0 then
       begin
        msgType := mtInformation;
        str := str+' is successfully received! Size = '+IntToStr(Received[i])+' bytes.';
       end
      else
        str := str+' is not received! Error: Unknown error code = '+IntToStr(Received[i]);
    end;
    MessageDlg(str,msgType,[mbOK],0);
   end;
  FilesToReceive.RowCount := 1;
end;

procedure TForm1.btnForbidFilesClick(Sender: TObject);
begin
  MsgClient1.AllowFiles := False;
  btnAllowFiles.Enabled := True;
  btnForbidFiles.Enabled := False;
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

procedure TForm1.AddRow(Grid: TStringGrid; Str: String; FileID: Cardinal = MSG_INVALID_ID);
begin
  Grid.RowCount := Grid.RowCount + 1;
  if (Grid.RowCount = 2) then
    Grid.FixedRows := 1;
  Grid.Cells[0,Grid.RowCount-1] := IntToStr(Grid.RowCount-1);
  if FileID = MSG_INVALID_ID then
    Grid.Cells[1,Grid.RowCount-1] := Str
  else
   begin
    Grid.Cells[1,Grid.RowCount-1] := IntToStr(FileID);
    Grid.Cells[2,Grid.RowCount-1] := Str;
   end;
end;

function TForm1.GetPercent(BlockSize,BlockNo,FullSize: Integer): String;
var
  percent:    Integer;
begin
  if (BlockSize > 0) and
     (BlockNo >= 0) and
     (FullSize > 0) then
    percent := Round(BlockSize*(BlockNo+1)/FullSize*100)
  else
    percent := 0;
{$IFDEF DEBUG_LOG}
aaWriteToLog('percent = '+IntToStr(percent));
{$ENDIF}
  if percent > 100 then percent := 100;
  Result := IntToStr(percent)+'%';
{$IFDEF DEBUG_LOG}
aaWriteToLog('percent = '+Result);
{$ENDIF}
end;

function TForm1.CheckPercent(str1,str2:String): Boolean;
begin
{$IFDEF DEBUG_LOG}
aaWriteToLog('str1 = '+str1);
aaWriteToLog('str2 = '+str2);
aaWriteToLog('1='+copy(str1,0,length(str1)-1));
aaWriteToLog('2='+copy(str2,0,length(str2)-1));
{$ENDIF}
  if StrToInt(copy(str1,0,length(str1)-1)) < StrToInt(copy(str2,0,length(str2)-1)) then
    Result := true
  else
    Result := false;
end;

procedure TForm1.MsgClient1SendFileFailed(const ToUserID, FileID: Cardinal;
  const FileName: String; FullSize: Int64; BlockSize, BlockNo,
  Blocks: Integer);
begin
  MessageDlg('File "'+FileName+'" of '+IntToStr(FullSize)+' bytes size '+#13#10+
             'sending to user ID = '+IntToStr(ToUserID)+#13#10+
             'is failed on block # '+IntToStr(BlockNo)+
             'of size of '+IntToStr(BlockSize)+' bytes!'+#13#10+
             IntToStr(Blocks-BlockNo)+' blocks of total '+
             IntToStr(Blocks)+' blocks is not sending!'
             ,mtError,[mbOK],0);
end;

end.
