//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnCreateClick(TObject *Sender)
{
 AnsiString pass;
 EasyDatabase1->Connected = false;
 if (! InputQuery("Database \""+EasyDatabase1->DatabaseName+"\" autification","Enter password for new database: ", pass))
	 return;
 EasyDatabase1->Password = pass;
 EasyDatabase1->CreateDatabase();
 lbPass->Caption = pass;

 EasyTable1->FieldDefs->Clear();
 EasyTable1->FieldDefs->Add("ID",ftAutoInc,0,false);
 EasyTable1->FieldDefs->Add("Name",ftString,100,false);
 EasyTable1->FieldDefs->Add("Surname",ftString,100,false);
 EasyTable1->FieldDefs->Add("Comments",ftMemo,0,false);
 EasyTable1->IndexDefs->Clear();
 EasyTable1->CreateTable();

 EasyTable1->Active = true;

}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnOpenClick(TObject *Sender)
{
 AnsiString pass;
 BOOL f;

 EasyDatabase1->Connected = false;
 pass = lbPass->Caption;
 f = false;
 if (EasyDatabase1->Encrypted)
  do
  {
   if (! InputQuery("Database \""+EasyDatabase1->DatabaseName+
          "\" autification","Enter current password: ", pass))
   		 break;
   lbPass->Caption = pass;
   EasyDatabase1->Password = pass;
   try
   {
    EasyDatabase1->Connected = true;
    f = true;
   }
   catch (...)
   {
    f = false;
    if (MessageDlg("Invalid password. Do you want to try again?",mtConfirmation,
      TMsgDlgButtons()<<mbYes<<mbNo,0) != mrYes)
     {
      EasyDatabase1->Connected = false;
      return;
     }
   } // try
  }  while (! f);
 else
  {
    EasyDatabase1->Connected = true;
    f = true;
  }
 EasyTable1->Active = f;

}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnCloseClick(TObject *Sender)
{
 EasyDatabase1->Connected = False;

}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnSetPwdClick(TObject *Sender)
{
 AnsiString pass;
 if (! EasyDatabase1->Connected)
  btnOpenClick(this);
 if (! EasyDatabase1->Connected)
  return;
 pass = EasyDatabase1->Password;
 if (InputQuery("Set new password for database \""+EasyDatabase1->DatabaseName+"\" autification","Enter new password: ", pass))
 {
  try
  {
   EasyDatabase1->Connected = false;
	 EasyDatabase1->ChangeEncryption(pass);
   EasyTable1->Active = true;
   lbPass->Caption = EasyDatabase1->Password;
	 MessageDlg("New password was set successfully. Password = \""+pass+"\"",
	  mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
  catch (...)
  {
	 MessageDlg("Error on changing password \""+EasyDatabase1->DatabaseName+"\". Origninal database restored.",
	  mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
 }

}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnDecryptClick(TObject *Sender)
{
 AnsiString pass;

 if (! EasyDatabase1->Connected)
  btnOpenClick(this);
 if (! EasyDatabase1->Connected)
  return;
 pass = EasyDatabase1->Password;
 try
  {
   EasyDatabase1->Connected = false;
	 EasyDatabase1->ChangeEncryption("");
   EasyTable1->Active = true;
   lbPass->Caption = EasyDatabase1->Password;
  }
  catch (...)
  {
	 MessageDlg("Error on decrypting \""+EasyDatabase1->DatabaseName+"\". Origninal database restored.",
	  mtInformation,TMsgDlgButtons()<<mbOK,0);
  }

}
//---------------------------------------------------------------------------
