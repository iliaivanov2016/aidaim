//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "MsgClient"
#pragma link "MsgComBase"
#pragma link "MsgServer"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}

__int64 round(long double x)
{
 return (__int64)(x+0.5);
}

//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
  TMsgUserInfo UserInfo;

  aaFileID = MSG_INVALID_ID;
  aaFileName = "";
  btnStartClick(this);
  btnAllowFilesClick(this);
  btnAllowDirectClick(this);
  btnAllowRecvClick(this);
  btnConnect1Click(this);
  UserInfo.UserID = MSG_INVALID_USER_ID;
  UserInfo.UserName = "User1";
  MsgClient1->RegisterNewUser(UserInfo,"",true);
  btnConnect2Click(this);
  UserInfo.UserName = "User2";
  MsgClient2->RegisterNewUser(UserInfo,"",true);
  btnConnectDirectlyClick(this);
  StartDate = 0;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient1SendFile(const DWORD ToUserID,
      const DWORD FileID, const AnsiString FileName, Int64 FullSize,
      int BlockSize, int BlockNo, int Blocks)
{

  int Percent;
  unsigned int n;
  long double x,x1,x2;
  __int64 spd;

  if (BlockNo < 0)
   {
    SendStartTime = Msglinux::GetTickCount();
    StartDate = 0;
    ProgressBar1->Position = 1;
    SendPercent->Caption = "0%";
   }
  else
   {
    n = Msglinux::GetTickCount()-SendStartTime;
    x = __int64(BlockSize)*__int64(BlockNo+1);
    if (n <= 0)
     spd = 0;
    else
     {
      x1 = n;
      x2 = 1000.0;
      spd = (__int64)round(x/(x1/x2));
     };
    Speed->Caption = "Speed: "+ IntToStr(spd)+ " bytes per sec";

    if (BlockNo == (Blocks-1))
     {
      ProgressBar1->Position = 100;
      SendPercent->Caption = "100%";
     }
    else
     {
      if (FullSize <= 0) 
       Percent = 100;
      else
       {
        x1 = FullSize;
        x2 = 100.0;
        Percent = (int)round(x/x1*x2);
       };

      SendPercent->Caption = IntToStr(Percent)+"%";
      ProgressBar1->Position = Percent;
     };
   };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient2ReceiveFile(const DWORD FromUserID,
      const DWORD FileID, const TDateTime SendingDate,
      const TDateTime DeliveryDate, const AnsiString FileName,
      Int64 FullSize, int BlockSize, int BlockNo, int Blocks, bool Directly)
{
  long double BytesSaved, Time;
  int Percent;

  if (aaFileID == MSG_INVALID_ID)
    aaFileID = FileID;
  if (aaFileName == "")
    aaFileName = FileName;
  if (StartDate == (TDateTime)0)
    StartDate = DeliveryDate;

  if (Directly)
    lbDirectly->Caption = "Directly";
  else
    lbDirectly->Caption = "Thru Server";
  lbFileName->Caption = "File: "+FileName;
  if (FullSize >= 0)
    lbFileSize->Caption = "Size: "+IntToStr(FullSize)+" bytes";
  if (Blocks >= 0)
    lbBlocks->Caption = "Blocks: "+IntToStr(Blocks);
  if (BlockSize >= 0)
    lbBlockSize->Caption = "Block Size: "+IntToStr(BlockSize)+" bytes";
  if (BlockNo >= 0)
    lbBlockNo->Caption = "Block No: "+IntToStr(BlockNo);
  BytesSaved = __int64(BlockNo + 1) * __int64(BlockSize);
  if (BytesSaved > FullSize)
    BytesSaved = FullSize;
  if (BytesSaved >= 0)
    lbRecvBytes->Caption = "Saved: "+IntToStr((__int64)BytesSaved)+" bytes";

  Time = round((long double)(DeliveryDate - StartDate)*24*60*60*1000); // msec
  if (Time == 0)
    Time = 1;
  if ((BlockNo < 0) || (FullSize < 0) || (Blocks < 0))
   {
    ProgressBar2->Position = 1;
    RecvPercent->Caption = "0%";
   }
  else
   {
    lbSpeed->Caption = "Speed: "
      + IntToStr(round((BytesSaved)/(Time/1000)))
      +" bytes per sec";
    Percent = (int)round(BytesSaved / FullSize * 100);
    if (ProgressBar2->Position < Percent)  // to avoid reducing when logon during Sending
     {
      RecvPercent->Caption = IntToStr(Percent)+"%";
      ProgressBar2->Position = Percent;
     };
   };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnBrowseClick(TObject *Sender)
{
  TFileStream *fs;

  if (!OpenDialog1->Execute())
    return;
  FileName->Text = OpenDialog1->FileName;
  fs = new TFileStream(FileName->Text,fmOpenRead || fmShareDenyWrite);
  try
  {
   FileSize->Caption = "Size: " + IntToStr(fs->Size)+ " bytes";
  }
  __finally
  {
   delete fs;
  };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnConnect1Click(TObject *Sender)
{
  MsgClient1->Connect();
  btnConnect1->Enabled = false;
  btnDisconnect1->Enabled = true;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnConnectDirectlyClick(TObject *Sender)
{
  if (btnConnectDirectly->Enabled) 
   {
    MsgClient1->ConnectDirectly(MsgClient2->UserID,"",0);
    btnConnectDirectly->Enabled = false;
    btnDiconnectDirectly->Enabled = true;
   };        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnDisconnect1Click(TObject *Sender)
{
  MsgClient1->Disconnect();
  btnConnect1->Enabled = true;
  btnDisconnect1->Enabled = false;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnDiconnectDirectlyClick(TObject *Sender)
{
  MsgClient1->DisconnectAll();
  btnConnectDirectly->Enabled = true;
  btnDiconnectDirectly->Enabled = false;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnSendClick(TObject *Sender)
{
  bool Directly;

  if (rbDirectly->Checked)
   {
    btnConnectDirectlyClick(this);
    Directly = true;
   }
  else
    Directly = false;
  ProgressBar1->Position = 0;
  SendPercent->Caption = "";
  RecvPercent->Caption = "";
  lbDirectly->Caption = "";
  lbFileName->Caption = "File: ";
  lbFileSize->Caption = "Size: ";
  lbBlocks->Caption = "Blocks: ";
  lbBlockSize->Caption = "Block Size: ";
  lbBlockNo->Caption = "Block No: ";
  lbRecvBytes->Caption = "Saved: ";
  aaFileID = MSG_INVALID_ID;
  aaFileName = "";
  MsgClient1->SendFile(MsgClient2->UserID,FileName->Text,StrToIntDef(Blocks->Text,0),StrToIntDef(BlockSize->Text,0),Directly);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnAllowFilesClick(TObject *Sender)
{
  MsgServer1->AllowFiles = true;
  btnAllowFiles->Enabled = false;
  btnForbidFiles->Enabled = true;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnForbidFilesClick(TObject *Sender)
{
  MsgServer1->AllowFiles = false;
  btnAllowFiles->Enabled = true;
  btnForbidFiles->Enabled = false;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnAllowRecvClick(TObject *Sender)
{
  MsgClient2->AllowFiles = true;
  btnAllowRecv->Enabled = false;
  btnForbidRecv->Enabled = true;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnForbidRecvClick(TObject *Sender)
{
  MsgClient2->AllowFiles = false;
  btnAllowRecv->Enabled = true;
  btnForbidRecv->Enabled = false;
        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnConnect2Click(TObject *Sender)
{
  MsgClient2->Connect();
  if (MsgClient2->Connected) 
   {
    btnConnect2->Enabled = false;
    btnDisconnect2->Enabled = true;
   };        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnAllowDirectClick(TObject *Sender)
{
  MsgClient2->AllowDirectly = true;
  btnAllowDirect->Enabled = false;
  btnForbidDirect->Enabled = true;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnDisconnect2Click(TObject *Sender)
{
  MsgClient2->Disconnect();
  MsgClient2->Active = false;
  MsgClient2->UserID = 2; // fix if previously not logged
  if (!MsgClient2->Connected)
   {
    btnConnect2->Enabled = true;
    btnDisconnect2->Enabled = false;
   };        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnForbidDirectClick(TObject *Sender)
{
  MsgClient2->AllowDirectly = true;
  btnAllowDirect->Enabled = true;
  btnForbidDirect->Enabled = false;        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnReceiveFileClick(TObject *Sender)
{
  AnsiString str, PathName;
  int Received;
  TMsgDlgType msgType;
  int TimeOut = 60000; // 1 minute

  PathName = MsgClient2->IncomingPath+aaFileName;
  Received = MsgClient2->ReceiveFile(aaFileID, PathName, TimeOut);
  str = "File "+PathName;
  msgType = mtError;
  switch (Received)
  {
   case MSG_Error_ReceiveFile_NotExists:
    str = str+" is not received! Error: File never came or is already received.";
    break;
   case MSG_Error_ReceiveFile_DiskFull:
    str = str+" is not received! Error: Not enough room on the target drive.";
    break;
   case MSG_Error_ReceiveFile_FileExists:
    str = str+" is not received! Error: File with the same name is already existing.";
    break;
   case MSG_Error_ReceiveFile_CannotCreateFile:
    str = str+" is not received! Error: Cannot create file with this name.";
    break;
   case MSG_Error_ReceiveFile_TimeOut:
    str = str+" is not received! Error: ReceiveFile exceeds TimeOut = "+IntToStr(TimeOut);
    break;
   case MSG_Error_ReceiveFile_BlockSize:
    str = str+" is not received! Error: Received block has the wrong size.";
    break;
   default:
    if (Received > 0)
     {
      msgType = mtInformation;
      str = str+" is successfully received! Size = "+IntToStr(Received)+" bytes.";
     }
    else
      str = str+" is not received! Error: Unknown error code = "+IntToStr(Received);
    break;
  };
  MessageDlg(str,msgType,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnStartClick(TObject *Sender)
{
  MsgServer1->ClearAll();
  MsgServer1->Active = true;
  btnStart->Enabled = false;
  btnStop->Enabled = true;

}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnStopClick(TObject *Sender)
{
  MsgServer1->Active = false;
  btnStart->Enabled = true;
  btnStop->Enabled = false;
  btnConnect1->Enabled = true;
  btnDisconnect1->Enabled = false;
  btnConnect2->Enabled = true;
  btnDisconnect2->Enabled = false;
}
//---------------------------------------------------------------------------






