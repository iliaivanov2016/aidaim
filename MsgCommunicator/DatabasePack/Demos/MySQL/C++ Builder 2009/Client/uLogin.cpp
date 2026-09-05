//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uLogin.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TfmLogin *fmLogin;
//---------------------------------------------------------------------------
__fastcall TfmLogin::TfmLogin(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmLogin::FormClose(TObject *Sender, TCloseAction &Action)
{
  if (!FClose)
   Action = Forms::caNone;
}
//---------------------------------------------------------------------------
void __fastcall TfmLogin::FormShow(TObject *Sender)
{
  if (fmMain->MsgClient1->UserID != MSG_INVALID_USER_ID) 
   RegUserID->Text = IntToStr((int)fmMain->MsgClient1->UserID);
  edHost->Text = fmMain->MsgClient1->ConnectionParams->RemoteHost;
  edPort->Text = IntToStr((int)fmMain->MsgClient1->ConnectionParams->RemotePort);
  FClose = false;
  ModalResult = mrCancel;  
}
//---------------------------------------------------------------------------
void __fastcall TfmLogin::bnCancelClick(TObject *Sender)
{
  ModalResult = mrCancel;
  FClose = true;  
}
//---------------------------------------------------------------------------
void __fastcall TfmLogin::bnLoginClick(TObject *Sender)
{
  ModalResult = mrOk;
  fmMain->MsgClient1->ConnectionParams->RemoteHost = edHost->Text;
  try
  {
    fmMain->MsgClient1->UserID = StrToInt(RegUserID->Text);
  }
  catch (...)
  {
    ShowMessage("Invalid UserID");
    return;
  };
  try
  {
    fmMain->MsgClient1->ConnectionParams->RemotePort = StrToInt(edPort->Text);
  }
  catch (...)
  {
    ShowMessage("Invalid Port");
    return;
  }
  fmMain->MsgClient1->Password = edPassword->Text;
  bnLogin->Enabled = false;
  if (fmMain->Login())
    FClose = true;
  else
   ShowMessage("Login failed. Check parameters and ensure that server is started.");
  bnLogin->Enabled = true;
}
//---------------------------------------------------------------------------
