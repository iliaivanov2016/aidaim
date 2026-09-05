//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
#include "Client.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma resource "*.dfm"
TMainForm *MainForm;
//---------------------------------------------------------------------------
__fastcall TMainForm::TMainForm(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::FormCreate(TObject *Sender)
{
  //if table doesn't exist
  if (!EasyTable1->Exists)
  {
   //set table structure
   EasyTable1->FieldDefs->Clear();
   EasyTable1->FieldDefs->Add("ID",ftAutoInc,0,False);
   EasyTable1->FieldDefs->Add("Name",ftString,30,False);
   EasyTable1->FieldDefs->Add("Photo",ftGraphic,0,False);
   EasyTable1->FieldDefs->Add("Journal",ftFmtMemo,0,False);
   EasyTable1->FieldDefs->Add("Comments",ftMemo,0,False);
   EasyTable1->FieldDefs->Add("File",ftBlob,0,False);

   EasyTable1->IndexDefs->Clear();
   EasyTable1->IndexDefs->Add("PrimaryKey","ID",TIndexOptions()<<ixPrimary);
   EasyTable1->IndexDefs->Add("ByName","Name",TIndexOptions()<<ixCaseInsensitive);
   EasyTable1->CreateTable();
  }
  // open table
  EasyTable1->Active = true;
  // update buttons
  UpdateButtons();
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::NewCustBtnClick(TObject *Sender)
{
 EasyTable1->Insert();
 CustForm->ShowModal();
 // update buttons
 UpdateButtons();

}
//---------------------------------------------------------------------------

void __fastcall TMainForm::EditCustBtnClick(TObject *Sender)
{
 if (EditCustBtn->Enabled)
 {
   EasyTable1->Edit();
   CustForm->ShowModal();
   // update buttons
   UpdateButtons();
 }
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::DeleteCustBtnClick(TObject *Sender)
{
 if (MessageDlg("Do you really want to delete client "+
               QuotedStr(EasyTable1->FieldByName("Name")->AsString)+
               " ?",mtConfirmation,TMsgDlgButtons()<<mbYes<<mbNo,0) == mrYes)
  EasyTable1->Delete();
 // update buttons
 UpdateButtons();
}

void __fastcall TMainForm::UpdateButtons()
{
 if (EasyTable1->RecordCount > 0)
 {
   EditCustBtn->Enabled = true;
   DeleteCustBtn->Enabled = true;
 }
 else
  {
   EditCustBtn->Enabled = false;
   DeleteCustBtn->Enabled = false;
  }
}
//---------------------------------------------------------------------------


