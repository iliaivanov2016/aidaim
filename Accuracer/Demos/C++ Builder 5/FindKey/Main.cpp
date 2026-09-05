//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
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
  if (!ACRTable1->Exists)
  {
   //set table structure
   ACRTable1->FieldDefs->Clear();
   ACRTable1->FieldDefs->Add("CustNo",ftAutoInc,0,False);
   ACRTable1->FieldDefs->Add("Company",ftString,30,False);
   ACRTable1->FieldDefs->Add("Address",ftString,30,False);
   ACRTable1->FieldDefs->Add("Phone",ftString,15,False);
   ACRTable1->FieldDefs->Add("FAX",ftString,15,False);
   ACRTable1->FieldDefs->Add("TaxRate",ftFloat,0,False);
   ACRTable1->FieldDefs->Add("LastInvoiceDate",ftDateTime,0,False);

   ACRTable1->IndexDefs->Clear();
   ACRTable1->IndexDefs->Add("PrimaryKey","CustNo",TIndexOptions()<<ixPrimary);
   ACRTable1->IndexDefs->Add("ByCompany","Company",TIndexOptions()<<ixCaseInsensitive);
   ACRTable1->CreateTable();
  }
  // open table
  ACRTable1->Active = true;
  // update buttons
  UpdateButtons();
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::NewCustBtnClick(TObject *Sender)
{
 ACRTable1->Insert();
 CustForm->ShowModal();
 // update buttons
 UpdateButtons();

}
//---------------------------------------------------------------------------

void __fastcall TMainForm::EditCustBtnClick(TObject *Sender)
{
 if (EditCustBtn->Enabled)
 {
   ACRTable1->Edit();
   CustForm->ShowModal();
   // update buttons
   UpdateButtons();
 }
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::DeleteCustBtnClick(TObject *Sender)
{
 if (MessageDlg("Do you really want to delete "+
               QuotedStr(ACRTable1->FieldByName("Company")->AsString)+
               " company?",mtConfirmation,TMsgDlgButtons()<<mbYes<<mbNo,0) == mrYes)
  ACRTable1->Delete();
 // update buttons
 UpdateButtons();
}

void __fastcall TMainForm::UpdateButtons()
{
 // New / Edit / Delete buttons
 if (ACRTable1->RecordCount > 0)
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



void __fastcall TMainForm::btFindKeyClick(TObject *Sender)
{
 ACRTable1->IndexName = "ByCompany";
 if (!ACRTable1->FindKey((&TVarRec(SearchCondition->Text)),0))
    MessageDlg("Record not found.",mtInformation,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFindNearestClick(TObject *Sender)
{
  ACRTable1->IndexName = "ByCompany";
  ACRTable1->FindNearest(&TVarRec(SearchCondition->Text),0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btGotoKeyClick(TObject *Sender)
{
  ACRTable1->IndexName = "ByCompany";
  ACRTable1->SetKey();
  ACRTable1->FieldByName("Company")->AsString = SearchCondition->Text;
  if (!ACRTable1->GotoKey())
    MessageDlg("Record not found.",mtInformation,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btGotoNearestClick(TObject *Sender)
{
  ACRTable1->IndexName = "ByCompany";
  ACRTable1->SetKey();
  ACRTable1->FieldByName("Company")->AsString = SearchCondition->Text;
  ACRTable1->GotoNearest();
}
//---------------------------------------------------------------------------

