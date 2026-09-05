//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma link "MsgClient"
#pragma link "MsgComBase"
#pragma link "MsgDatabase"
#pragma link "MsgDatabaseAccuracer"
#pragma resource "*.dfm"
TfmMain *fmMain;
//---------------------------------------------------------------------------
__fastcall TfmMain::TfmMain(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormCreate(TObject *Sender)
{
  InitializeCriticalSection(FCSect);
  FTemp = new TStringList();
  FStarting = true;
#ifdef VER130
	FConfigFileName = IncludeTrailingBackslash(
                      ExtractFilePath(Application->ExeName))+"Client.ini";
#else
  FConfigFileName = ExtractFilePath(Application->ExeName)+"Client.ini";
#endif
  MsgClient1->UserID = MSG_INVALID_USER_ID;
  if (FileExists(FConfigFileName))
   LoadSettings();
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::LoadSettings()
{
 TIniFile *IniFile;
 IniFile = new TIniFile(FConfigFileName);
 try
 {
   MsgClient1->UserID = Cardinal(IniFile->ReadInteger("Client Settings","UserID",Integer(MsgClient1->UserID)));
   MsgClient1->Password = IniFile->ReadString("Client Settings","Password",MsgClient1->Password);
   MsgClient1->ConnectionParams->LocalPort = IniFile->ReadInteger("Client Settings","Port",MsgClient1->ConnectionParams->LocalPort);
   MsgClient1->ConnectionParams->RemoteHost = IniFile->ReadString("Server Settings","Host",MsgClient1->ConnectionParams->RemoteHost);
   MsgClient1->ConnectionParams->RemotePort = IniFile->ReadInteger("Server Settings","Port",MsgClient1->ConnectionParams->RemotePort);
 }
 __finally
 {
   delete IniFile;
 }
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::SaveSettings()
{
 TIniFile *IniFile;
 IniFile = new TIniFile(FConfigFileName);
 try
 {
   IniFile->WriteInteger("Client Settings","UserID",MsgClient1->UserID);
   IniFile->WriteString("Client Settings","Password",MsgClient1->Password);
   IniFile->WriteInteger("Client Settings","Port",MsgClient1->ConnectionParams->LocalPort);
   IniFile->WriteString("Server Settings","Host",MsgClient1->ConnectionParams->RemoteHost);
   IniFile->WriteInteger("Server Settings","Port",MsgClient1->ConnectionParams->RemotePort);
 }
 __finally
 {
   delete IniFile;
 }
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::DoLogin()
{
  fmLogin->ShowModal();
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::DoRegister()
{
  fmRegister->ShowModal();
}
//---------------------------------------------------------------------------
bool TfmMain::Login()
{
  bool res;
  try
  {
    MsgClient1->Connected = true;
    MsgClient1->GetUserInfo(MsgClient1->UserID,FUserInfo);
  }
  catch (Exception &e)
  {
     res = false;
     MsgClient1->Disconnect();
     if (e.Message.Pos("60095") > 0)
      ShowMessage("Error - user does not exists");
     else
     if (e.Message.Pos("60096") > 0)
      ShowMessage("Error - invalid password");
     else
      ShowMessage("Error - "+e.Message);
     return res;
  }
  res = MsgClient1->Connected;
	if (res)
   {
    SaveSettings();
    gbContacts->Caption = " UserID #"+IntToStr(Integer(MsgClient1->UserID))+" Contacts: ";
    FillContacts();
   }
 return res;
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::FillContacts()
{
  int i;
  ClearContacts();
  Lock();
  try
  {
   bnSend->Enabled = false;
   for (i = 0; i < MsgClient1->ContactCount; i++)
     lbContacts->Items->Add(
      MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]));
   lbContacts->Repaint();
  }
  __finally
  {
   Unlock();
  }
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::ClearContacts()
{
  Lock();
  try
  {
    lbContacts->Clear();
  }
  __finally
  {
    Unlock();
  }
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::Lock()
{
  EnterCriticalSection(FCSect);
}
//---------------------------------------------------------------------------
void __fastcall  TfmMain::Unlock()
{
  LeaveCriticalSection(FCSect);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnFindClick(TObject *Sender)
{
  if (fmFind->ShowModal() != mrCancel)
   {
    // add to contacts
    FillContacts();
   }
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::lbContactsDrawItem(TWinControl *Control,
      int Index, TRect &Rect, TOwnerDrawState State)
{
  TColor col;
  col = clRed;
  if (Index < MsgClient1->ContactCount)
   if (MsgClient1->Contacts[Index].UserInfo.Status == msgOnLine)
     col = clGreen;
  lbContacts->Canvas->Font->Color = col;
  lbContacts->Canvas->Brush->Color = clWindow;
  lbContacts->Canvas->FillRect(Rect);
  lbContacts->Canvas->TextOut(Rect.Left+1,
    Rect.Top+1,lbContacts->Items->Strings[Index]);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::lbContactsClick(TObject *Sender)
{
  int i;
  bnSend->Enabled = false;
  for (i = 0; i < lbContacts->Items->Count; i++)
   if (lbContacts->Checked[i])
    {
     bnSend->Enabled = true;
     break;
    }
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgClient1ReceiveTextMessage(
			const DWORD FromUserID, const TDateTime SendingDate,
			const TDateTime DeliveryDate, const AnsiString Text)
{
	AnsiString Capt;
	int i;
	Lock();
	try
	{
		Capt = "User #"+IntToStr((int)FromUserID);
		for (i = 0; i < MsgClient1->ContactCount; i++)
		 if (MsgClient1->Contacts[i].UserInfo.UserID == FromUserID)
			{
			 Capt = MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]);
			 break;
			}
    Capt = Capt+" "+TimeToStr(SendingDate)+" : ";
    if (FStarting)
     {
      // store messages to temp string list to avoid hanging of the reView
      FTemp->Add(Capt);
      FTemp->Add(Text);
     }
    else
		 {
			Capt = Capt+(AnsiString)"\r\n"+Text;
			TClientDisplayThread *cdt = new TClientDisplayThread(Capt);
			cdt->Resume();
//      reView->Lines->Add(Capt);
//      reView->Lines->Add(Text);
		 }
	}
	__finally
	{
		Unlock();
	}
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnSendClick(TObject *Sender)
{
  int Code,i;
  unsigned int UserID;
	WideString Capt,s;
  TDateTime dt;

  dt = Now();
  bnSend->Enabled = false;
  Lock();
  try
  {
   s = reSend->Text;
   for (i = 0; i < lbContacts->Items->Count; i++)
    if (lbContacts->Checked[i])
     {
      UserID = MsgClient1->Contacts[i].UserInfo.UserID;
      Code = MsgClient1->SendMessage(UserID,s,true);
      if (i == 0)
       dt = Now();
      if (Code != MSG_COMMAND_OK)
       ShowMessage("Cannot send message to user # "+
         IntToStr((int)UserID)+"-> Error code = "+IntToStr((int)Code));
     }
    reSend->Clear();
    Capt = (WideString)(AnsiString)FUserInfo.UserName+(WideString)(" "+TimeToStr(dt)+" : \r\n")+s;
		TClientDisplayThread *cdt = new TClientDisplayThread(Capt);
		cdt->Resume();
//    reView->Lines->Add(Capt);
//    reView->Lines->Add(s);
	}
  __finally
  {
    bnSend->Enabled = true;
		Unlock();
  }
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormClose(TObject *Sender, TCloseAction &Action)
{
  DeleteCriticalSection(FCSect);
  delete FTemp;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormActivate(TObject *Sender)
{
 if (MsgClient1->Connected) return;
 while (! MsgClient1->Connected)
 {
   if (MsgClient1->UserID != MSG_INVALID_USER_ID)
     {
       if (Login())
        break;
       else
        DoLogin();
       if (! MsgClient1->Connected)
        MsgClient1->UserID = MSG_INVALID_USER_ID;
       continue;
     }
   if (fmStart->ShowModal() != mrOk)
		{
     Application->Terminate();
     break;
    }
   else
    {
     if (fmStart->rgAction->ItemIndex == 0)
      DoRegister();
     else
      DoLogin();
     if (! MsgClient1->Connected)
      MsgClient1->UserID = MSG_INVALID_USER_ID;
    }
 }
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Timer1Timer(TObject *Sender)
{
 int i;
 WideString Capt;
 if (FTemp->Count > 0)
	{
	 // copy messages from temp string list to reView
//	 for (i = 0; i < FTemp->Count; i++)
//	reView->Lines->Add(FTemp->Strings[i]);
	 Capt = FTemp->Text;
	 TClientDisplayThread *cdt = new TClientDisplayThread(Capt);
	 cdt->Resume();

	 FTemp->Clear();
	 Timer1->Enabled = false;
	 FStarting = false;
	}
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgClient1UserOffLine(const DWORD UserID)
{
   FillContacts();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgClient1UserOnLine(const DWORD UserID)
{
   FillContacts();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnHistoryClick(TObject *Sender)
{
  fmHistory->ShowModal();
}

//---------------------------------------------------------------------------
__fastcall TClientDisplayThread::TClientDisplayThread(AnsiString text) : TThread(true)
{
  FText = text;
  FUnicodeText = "";
}
//---------------------------------------------------------------------------
__fastcall TClientDisplayThread::TClientDisplayThread(WideString text) : TThread(true)
{
  FText = "";
  FUnicodeText = text;
}
//---------------------------------------------------------------------------
void __fastcall TClientDisplayThread::DisplayMessage()
{
  if (FText == "")
   fmMain->reView->Lines->Add(FUnicodeText);
  else
   fmMain->reView->Lines->Add(FText);
}
//---------------------------------------------------------------------------
void __fastcall TClientDisplayThread::Execute()
{
  TThreadMethod tm = &DisplayMessage;
  Synchronize(tm);
  //Synchronize(DisplayMessage);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::MsgClient1ReceiveUnicodeTextMessage(const DWORD FromUserID,
          const TDateTime SendingDate, const TDateTime DeliveryDate,
          const WideString Text)
{
	WideString Capt;
	int i;
	Lock();
	try
	{
		Capt = "User #"+IntToStr((int)FromUserID);
		for (i = 0; i < MsgClient1->ContactCount; i++)
		 if (MsgClient1->Contacts[i].UserInfo.UserID == FromUserID)
			{
			 Capt = MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]);
			 break;
			}
    Capt = Capt+" "+TimeToStr(SendingDate)+" : ";
    if (FStarting)
     {
      // store messages to temp string list to avoid hanging of the reView
      FTemp->Add(Capt);
      FTemp->Add(Text);
     }
    else
		 {
			Capt = Capt+(WideString)"\r\n"+Text;
			TClientDisplayThread *cdt = new TClientDisplayThread(Capt);
			cdt->Resume();
//      reView->Lines->Add(Capt);
//      reView->Lines->Add(Text);
		 }
	}
	__finally
	{
		Unlock();
	}
}
//---------------------------------------------------------------------------

