//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uRegister.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TfmRegister *fmRegister;
//---------------------------------------------------------------------------
__fastcall TfmRegister::TfmRegister(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmRegister::FormClose(TObject *Sender,
      TCloseAction &Action)
{
  if (!FClose)
   Action = Forms::caNone;
}
//---------------------------------------------------------------------------
void __fastcall TfmRegister::FormShow(TObject *Sender)
{
  edHost->Text = fmMain->MsgClient1->ConnectionParams->RemoteHost;
  edPort->Text = IntToStr((int)fmMain->MsgClient1->ConnectionParams->RemotePort);
  FClose = false;
  ModalResult = mrCancel;  
}
//---------------------------------------------------------------------------
void __fastcall TfmRegister::bnCancelClick(TObject *Sender)
{
  ModalResult = mrCancel;
  FClose = true;  
}
//---------------------------------------------------------------------------
void __fastcall TfmRegister::bnRegisterClick(TObject *Sender)
{
  TMsgUserInfo UserInfo;
  int res;
  // clear UserInfo
  memset(&UserInfo,0x00,sizeof(UserInfo));
  ModalResult = mrOk;
  fmMain->MsgClient1->ConnectionParams->RemoteHost = edHost->Text;
  // if UserID empty  UserID will be assigned by the server
  if (RegUserID->Text == "")
   UserInfo.UserID = MSG_INVALID_USER_ID;
  else
   try
   {
    UserInfo.UserID = StrToIntDef(RegUserID->Text,MSG_INVALID_USER_ID);
   }
   catch (...)
   {
    ShowMessage("Invalid UserID");
    return;
   }
  try
  {
    fmMain->MsgClient1->ConnectionParams->RemotePort = StrToInt(edPort->Text);
  }
  catch(...)
  {
    ShowMessage("Invalid Port");
    return;
  }
  bnRegister->Enabled = false;
  fmMain->MsgClient1->UserID = MSG_INVALID_USER_ID;
//  fmMain->MsgClient1->UserID = UserInfo->UserID;
  // fill UserInfo
	UserInfo.UserName = (AnsiString)RegUserName->Text;
	UserInfo.FirstName = (AnsiString)RegUserFirstName->Text;
	UserInfo.LastName = (AnsiString)RegUserLastName->Text;
	UserInfo.Organization = (AnsiString)RegUserCompany->Text;
  UserInfo.Department = (AnsiString)RegUserDepartment->Text;
  try
  {
    fmMain->MsgClient1->Connected = true;
  }
  catch (...)
  {
    ShowMessage("Registration failed. Cannot connect to server. Check parameters and ensure that server is started.");
  }
  res = fmMain->MsgClient1->RegisterNewUser(UserInfo,edPassword->Text,true);
  if (res != MSG_COMMAND_OK)
   {
    fmMain->MsgClient1->Connected = false;
    ShowMessage("Registration failed. Error code #"+IntToStr(res)+". Check parameters.");
   }
  else
   {
    fmMain->MsgClient1->Connected = false;
    fmMain->MsgClient1->Active = false;
    fmMain->MsgClient1->UserID = UserInfo.UserID;
    fmMain->MsgClient1->Password = edPassword->Text;
    if (fmMain->Login())
      FClose = true;
    else
      ShowMessage("Login failed. Check parameters and ensure that server is started.");
   }
  bnRegister->Enabled = true;
}
//---------------------------------------------------------------------------
