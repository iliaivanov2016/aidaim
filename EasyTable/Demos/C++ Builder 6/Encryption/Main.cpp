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
 EasyTable1->FieldDefs->Clear();
 EasyTable1->FieldDefs->Add("ID",ftAutoInc, 0, false);
 EasyTable1->FieldDefs->Add("Name",ftString,100, false);
 EasyTable1->FieldDefs->Add("Surname",ftString,100, false);
 EasyTable1->FieldDefs->Add("Comments",ftMemo, 0, false);
 EasyTable1->IndexDefs->Clear();
 EasyTable1->Password = edPass->Text;
 EasyTable1->Encrypted = true;
 EasyTable1->CreateTable();
 EasyTable1->Active = true;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::btnOpenClick(TObject *Sender)
{
String pass;
Boolean f;

 EasyTable1->Active = false;
 if (!EasyTable1->IsTableEncrypted())
 {
   try
   {
    EasyTable1->Active = true;
   }
   catch(...)
   {
    EasyTable1->Active = false;
    return;
   }
   return;
 }
 pass = edPass->Text;
 f = false;
 do
 {
  if (!InputQuery("Table '"+EasyTable1->TableName+"' autification","Enter password: ", pass))
     break;
  EasyTable1->Password = pass;
  try
  {
   EasyTable1->Active = true;
   f = true;
  }
  catch(...)
  {
   f = false;
   if (MessageDlg("Invalid password-> Do you want to try again?", mtConfirmation, TMsgDlgButtons()<<mbYes<<mbNo,0) != mrYes)
   {
     EasyTable1->Active = false;
     return;
   }
  }
 } while (!f);
}

//---------------------------------------------------------------------------
void __fastcall TForm1::btnCloseClick(TObject *Sender)
{
 EasyTable1->Active = False;
}

//---------------------------------------------------------------------------
void __fastcall TForm1::btnSetPwdClick(TObject *Sender)
{
String pass;

 btnOpenClick(this);
 if (!EasyTable1->Active)
  return;
 pass = EasyTable1->Password;
 if (InputQuery("Set new password for table '"+EasyTable1->TableName+"' autification","Enter new password: ", pass))
 {
  try
  {
   EasyTable1->Active = false;
   // disable dbgrid drwaing while restructure table being processed
   EasyTable1->DisableControls();
	 EasyTable1->RestructureTable(true, pass, EasyTable1->BLOBBlockSize, EasyTable1->BLOBCompression);
   EasyTable1->Active = true;
   EasyTable1->EnableControls();
	 MessageDlg("New password was set successfully-> Password = '"+pass+"'",
	  mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
  catch(...)
  {
   MessageDlg("Error restructuring table ""+EasyTable1->TableName+""-> Origninal table restored->",
              mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
 }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnDecryptClick(TObject *Sender)
{
 btnOpenClick(this);
 if (!EasyTable1->Active)
  return;
 try
 {
   EasyTable1->Active = false;
   // disable dbgrid drwaing while restructure table being processed
   EasyTable1->DisableControls();
	 EasyTable1->RestructureTable(false, "", EasyTable1->BLOBBlockSize, EasyTable1->BLOBCompression);
   EasyTable1->Active = true;
   EasyTable1->EnableControls();
	 MessageDlg("Password was removed successfully->", mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
  catch(...)
  {
	 MessageDlg("Error restructuring table '"+EasyTable1->TableName+"'. Origninal table restored.",
	  mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
}
//---------------------------------------------------------------------------
