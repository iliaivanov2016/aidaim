//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"

#undef D6H
#ifdef VER120
  #ifndef VER125
    #ifndef VER130
      #ifndef VER135
        #define D6H
      #endif
    #endif
  #endif
#endif

//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "MsgClient"
#pragma link "MsgComBase"
#pragma resource "*.dfm"
const AnsiString NoExistingUser = " - NO USER - ";

TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
  clbContactList->Color = clMenu;

// for debugging ///////////////////////////////////////////////////////////////
//  MsgClient1.UserID = 1;
// for debugging ///////////////////////////////////////////////////////////////

  MsgClient1ServerShutdown(Owner);
  SetConnectParams();
  VisualizeLogged();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::U1ConnectClick(TObject *Sender)
{
 int i;
 TMsgUserInfo UserInfo;
 GetConnectParams();
 try
 {
   MsgClient1->Connect();
 }
 __finally
 {
  VisualizeLogged();
  if (MsgClient1->Connected)
   {
    SetConnectParams();
    Connected();
    U1To->Clear();
    for (i=0; i < MsgClient1->ContactCount; i++)
      U1To->Items->Add(MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]));
    U1To->Items->Add("Server");
	RegUserID->Text = IntToStr((int)MsgClient1->UserID);
    if (MsgClient1->GetUserInfo(MsgClient1->UserID,UserInfo) != MSG_COMMAND_OK)
     {
      RegUserName->Text = "User" + RegUserID->Text;
      RegUserFirstName->Text = "";
      RegUserLastName->Text = "";
      RegUserDepartment->Text = "";
      RegUserCompany->Text = "";
     }
    else
     {
	  RegUserName->Text = (AnsiString)UserInfo.UserName;
	  RegUserFirstName->Text = (AnsiString)UserInfo.FirstName;
	  RegUserLastName->Text = (AnsiString)UserInfo.LastName;
	  RegUserDepartment->Text = (AnsiString)UserInfo.Department;
	  RegUserCompany->Text = (AnsiString)UserInfo.Organization;
     }
    if (MsgClient1->UserID != MSG_INVALID_USER_ID)
      btnGetContactListClick(Sender);
   }
  else // not Connected
   {
	UserID->Text = IntToStr((int)MsgClient1->UserID);
    MsgClient1ServerShutdown(Sender);
   }
 } // finally
}
//---------------------------------------------------------------------------
void __fastcall TForm1::U1DisconnectClick(TObject *Sender)
{
// disconnect from server
  MsgClient1->Disconnect();
// update form
  VisualizeLogged();
  MsgClient1ServerShutdown(Sender);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient1ServerShutdown(TObject *Sender)
{
  ServerHost->Enabled = true;
  ServerPort->Enabled = true;
  ClientPort->Enabled = true;
  ServerID->Enabled = true;
  UserID->Enabled = true;
// disable/enable buttons
  U1Connect->Enabled = true;
  U1Disconnect->Enabled = false;
  VisualizeLogged();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient1ReceiveTextMessage(
      const DWORD FromUserID, const TDateTime SendingDate,
      const TDateTime DeliveryDate, const AnsiString Text)
{
 while (! Canvas->TryLock())
  Application->ProcessMessages();
 try
 {
  AddMessage(FromUserID, Text, SendingDate);
 }
 __finally
 {
  Canvas->Unlock();
 }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient1UserOffLine(const DWORD UserID)
{
  int i;
  for (i = 0; i < MsgClient1->ContactCount; i++)
  {
    if (MsgClient1->Contacts[i].UserInfo.UserID == UserID)
     clbContactList->Checked[i] = false;
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::MsgClient1UserOnLine(const DWORD UserID)
{
  int i;
  for (i = 0; i < MsgClient1->ContactCount; i++)
   {
    if (MsgClient1->Contacts[i].UserInfo.UserID == UserID)
     clbContactList->Checked[i] = true;
   }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnLogonClick(TObject *Sender)
{
  int res = MsgClient1->Logon();
  switch (res)
  {
   MSG_Error_Logon_NotConnected:
      MessageDlg("Logon failed. You should connect to the server before logon. Error code = "
        +IntToStr(res),mtWarning,TMsgDlgButtons()<<mbOK, 0); break;
   MSG_Error_Logon_SendCommandFailed:
      MessageDlg("Logon failed. Cannot send request to server. Error code = "
        +IntToStr(res),mtWarning,TMsgDlgButtons()<<mbOK, 0); break;
   MSG_Error_Logon_ReceiveResultFailed:
      MessageDlg("Logon failed. Cannot get reply from server. Error code = "
        +IntToStr(res),mtWarning,TMsgDlgButtons()<<mbOK, 0); break;
   MSG_Error_Logon_InvalidServerReply:
      MessageDlg("Logon failed. Invalid reply received from server. Please, check the versions of MsgCommunicator on both client and server sides and contact AidAim software if they are the same. Error code = "
        +IntToStr(res),mtWarning,TMsgDlgButtons()<<mbOK, 0); break;
   MSG_Error_Logon_MaxConnectionsExceeded:
      MessageDlg("Logon failed. Maximum number of allowed connections exceeded. Error code = "
        +IntToStr(res),mtWarning,TMsgDlgButtons()<<mbOK, 0); break;
  default:
   VisualizeLogged();
  };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnLogoffClick(TObject *Sender)
{
  MsgClient1->Logoff();
  VisualizeLogged();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnRegisterClick(TObject *Sender)
{

  TMsgUserInfo UserInfo;
  int          res;
  AnsiString   oper;

  char b = 0x00;
  for (int i = 0; i < sizeof(UserInfo); i++)
   Move(&b,(char *)(&UserInfo)+i,1);
  UserInfo.UserID = MsgClient1->UserID;
  UserInfo.UserName = (AnsiString)RegUserName->Text;
  UserInfo.FirstName = (AnsiString)RegUserFirstName->Text;
  UserInfo.LastName = (AnsiString)RegUserLastName->Text;
  UserInfo.Organization = (AnsiString)RegUserCompany->Text;
  UserInfo.Department = (AnsiString)RegUserDepartment->Text;
  if (MsgClient1->IsUserExisting(MsgClient1->UserID) == MSG_COMMAND_RESULT_TRUE)
   {
    res = MsgClient1->UpdateUserInfo(UserInfo,true,RegPassword->Text);
    oper = "UpdateUserInfo";
   }
  else
   {
    MsgClient1->Password = RegPassword->Text;
    res = MsgClient1->RegisterNewUser(UserInfo,MsgClient1->Password);
    oper = "RegisterNewUser";
    VisualizeLogged();
    // Save UserID
	UserID->Text = IntToStr((int)MsgClient1->UserID);
	RegUserID->Text = IntToStr((int)MsgClient1->UserID);
   }
  if (res != MSG_COMMAND_OK) 
    ShowError(oper,res);
        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnGetContactListClick(TObject *Sender)
{

  int res,i;
  res = MsgClient1->GetContacts();
  if (res != MSG_COMMAND_OK)
    ShowError("GetContacts",res);
  clbContactList->Clear();
  for (i = 0; i < MsgClient1->ContactCount; i++)
   {
    clbContactList->Items->Add(MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]));
    if (MsgClient1->Contacts[i].UserInfo.Status != msgOffLine)
      clbContactList->Checked[clbContactList->Items->Count-1] = true;
   }
        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnAddUserToContactsClick(TObject *Sender)
{

  int res;

  // show user as FirstName + LastName
  res = MsgClient1->AddUserToContacts(GetUserID(UserID2Add->Text),mcnsFullName,"");
  if (res != MSG_COMMAND_OK)
    ShowError("AddUserToContacts",res);
  btnGetContactListClick(Sender);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnRemoveUserFromContactsClick(TObject *Sender)
{
  int res;
  res = MsgClient1->RemoveUserFromContacts(GetUserID(UserID2Add->Text));
  if (res != MSG_COMMAND_OK)
    ShowError("RemoveUserFromContacts",res);
  btnGetContactListClick(Sender);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnGetUserInfoClick(TObject *Sender)
{
  TMsgUserInfo UserInfo;
  int res;

  res = MsgClient1->GetUserInfo(GetUserID(UserID2GetInfo->Text),UserInfo);
  if (res != MSG_COMMAND_OK)
   {
    if (res == MSG_Error_GetUserInfo_UserDoesNotExist)
      InfoUserName->Text = NoExistingUser;
    else
      InfoUserName->Text = "";
    InfoUserFirstName->Text = "";
    InfoUserLastName->Text = "";
    InfoUserCompany->Text = "";
    InfoUserDepartment->Text = "";
    ShowError("GetUserInfo",res);
   }
  else
   {
	InfoUserName->Text = (AnsiString)UserInfo.UserName;
	InfoUserFirstName->Text = (AnsiString)UserInfo.FirstName;
	InfoUserLastName->Text = (AnsiString)UserInfo.LastName;
	InfoUserCompany->Text = (AnsiString)UserInfo.Organization;
	InfoUserDepartment->Text = (AnsiString)UserInfo.Department;
   }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::U1SendClick(TObject *Sender)
{
  unsigned int UserID;
  int res;
  UserID = GetUserID(U1ToID->Text);
  if (UserID == MSG_INVALID_USER_ID)
    return;
  res = MsgClient1->SendMessage(UserID, U1Msg->Text,true);
  if (res == MSG_COMMAND_OK)
   {
    AddMessage(GetUserID(U1ToID->Text), U1Msg->Text, Now());
    U1Msg->Text = "";
   }
  else
    ShowError("SendMessage", res);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::U1ToChange(TObject *Sender)
{
  if ((U1To->ItemIndex >= 0) &&
      (U1To->ItemIndex < MsgClient1->ContactCount))
   {
	U1ToID->Text = IntToStr((int)MsgClient1->Contacts[U1To->ItemIndex].UserInfo.UserID);
   }
  else
   {
    U1ToID->Text = ServerID->Text;
    U1To->ItemIndex = MsgClient1->ContactCount;
   }
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
void __fastcall TForm1::ShowError(AnsiString Operation, int ErrorCode)
{
  MessageDlg(Operation+" failed. Error code = "+(AnsiString)(ErrorCode),mtWarning,TMsgDlgButtons()<<mbOK, 0);
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
void __fastcall TForm1::VisualizeLogged()
{
  if (MsgClient1->Logged) 
   {
    btnLogon->Enabled = false;
    btnLogoff->Enabled = true;
   }
  else
   {
    btnLogon->Enabled = true;
    btnLogoff->Enabled = false;
   }

}
//---------------------------------------------------------------------------

void __fastcall TForm1::U1ToIDChange(TObject *Sender)
{
  int i;
  for (i = 0; i < MsgClient1->ContactCount; i++)
   {
    if (MsgClient1->Contacts[i].UserInfo.UserID == GetUserID(U1ToID->Text)) 
     {
      U1To->ItemIndex = i;
      return;
     }
   }
  U1To->ItemIndex = MsgClient1->ContactCount;
  U1ToID->Text = ServerID->Text;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::AddMessage(const unsigned int FromUserID, const AnsiString Text, const
                        TDateTime MsgDate)
{
  AnsiString str, str2;
  int i;
  str = "#" + IntToStr((int)FromUserID) + ", " + DateTimeToStr(MsgDate) + ":";
  for (i = 0; i < MsgClient1->ContactCount; i++)
   {
    if (MsgClient1->Contacts[i].UserInfo.UserID == FromUserID)
     {
      str2 = MsgClient1->GetContactDisplayName(MsgClient1->Contacts[i]);
      str = str2 + " " + str;
      break;
     }
   }
  if (U1Msg->Text == Text)
    str = ">>> " + str;
  else
    str = "<<< " + str;
  U1Incoming->Lines->Add(str);
  U1Incoming->Lines->Add(Text);
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
void __fastcall TForm1::SetConnectParams()
{
  ServerHost->Text = MsgClient1->ConnectionParams->RemoteHost;
  ServerPort->Text = IntToStr((int)MsgClient1->ConnectionParams->RemotePort);
  ClientPort->Text = IntToStr((int)MsgClient1->ConnectionParams->LocalPort);
  ServerID->Text = IntToStr((int)MsgClient1->ConnectionParams->ServerID);
  UserID->Text = Format("%u",ARRAYOFCONST(((int)MsgClient1->UserID)));
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
void __fastcall TForm1::GetConnectParams()
{
	__int64 UID;
	MsgClient1->ConnectionParams->RemoteHost = (AnsiString)ServerHost->Text;
	MsgClient1->ConnectionParams->RemotePort = StrToIntDef(ServerPort->Text,MsgDefaultServerPort);
  MsgClient1->ConnectionParams->LocalPort = StrToIntDef(ClientPort->Text,MsgDefaultClientPort);
  MsgClient1->ConnectionParams->ServerID = StrToIntDef(ServerID->Text,MsgDefaultServerID);
  UID = StrToInt64Def(UserID->Text,MSG_INVALID_USER_ID);
  if (UID > MSG_INVALID_USER_ID)
    UID = MSG_INVALID_USER_ID;
  MsgClient1->Password = Password->Text;
  MsgClient1->Active = false;
  MsgClient1->Connected = false;
  MsgClient1->UserID = (unsigned int)UID;
  MsgClient1->Active = true;
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
void __fastcall TForm1::Connected()
{
  ServerHost->Enabled = false;
  ServerPort->Enabled = false;
  ClientPort->Enabled = false;
  ServerID->Enabled = false;
  UserID->Enabled = false;
// disable/enable buttons
  U1Connect->Enabled = false;
  U1Disconnect->Enabled = true;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::UserIDChange(TObject *Sender)
{
  TEdit(Sender).Text = IntToStr((int)GetUserID(TEdit(Sender).Text));
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
unsigned int __fastcall TForm1::GetUserID(AnsiString Str)
{
  __int64 UID;
  UID = StrToInt64Def(Str,MSG_INVALID_USER_ID);
  if (UID > MSG_INVALID_USER_ID)
    UID = MSG_INVALID_USER_ID;
  return (unsigned int)UID;
}
//---------------------------------------------------------------------------


