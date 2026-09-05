//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
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
   EasyTable1->FieldDefs->Add("CustNo",ftAutoInc,0,False);
   EasyTable1->FieldDefs->Add("Company",ftString,30,False);
   EasyTable1->FieldDefs->Add("Address",ftString,30,False);
   EasyTable1->FieldDefs->Add("Phone",ftString,15,False);
   EasyTable1->FieldDefs->Add("FAX",ftString,15,False);
   EasyTable1->FieldDefs->Add("TaxRate",ftFloat,0,False);
   EasyTable1->FieldDefs->Add("LastInvoiceDate",ftDateTime,0,False);

   EasyTable1->IndexDefs->Clear();
   EasyTable1->IndexDefs->Add("PrimaryKey","CustNo",TIndexOptions()<<ixPrimary);
   EasyTable1->IndexDefs->Add("ByCompany","Company",TIndexOptions()<<ixCaseInsensitive);
   EasyTable1->CreateTable();
  }
  // open table
  EasyTable1->Active = true;
  EasyTable1->IndexName = "ByCompany";
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
 if (MessageDlg("Do you really want to delete "+
               QuotedStr(EasyTable1->FieldByName("Company")->AsString)+
               " company?",mtConfirmation,TMsgDlgButtons()<<mbYes<<mbNo,0) == mrYes)
  EasyTable1->Delete();
 // update buttons
 UpdateButtons();
}

void __fastcall TMainForm::UpdateButtons()
{
 // New / Edit / Delete buttons
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






void __fastcall TMainForm::btApplyClick(TObject *Sender)
{
 EasyTable1->IndexName = "ByCompany";
 EasyTable1->SetRangeStart();
 EasyTable1->FieldByName("Company")->AsString = cmbStartRange->Text;
 EasyTable1->KeyExclusive = cbStartKeyExclusive->Checked;
 EasyTable1->SetRangeEnd();
 EasyTable1->FieldByName("Company")->AsString = cmbEndRange->Text;
 EasyTable1->KeyExclusive = cbEndKeyExclusive->Checked;
 EasyTable1->ApplyRange();
 btApply->Enabled = false;
 btCancel->Enabled = true;
 UpdateButtons();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btCancelClick(TObject *Sender)
{
 EasyTable1->CancelRange();
 btApply->Enabled = true;
 btCancel->Enabled = false;
 UpdateButtons();
}
//---------------------------------------------------------------------------

