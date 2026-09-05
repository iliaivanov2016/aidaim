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

void __fastcall TMainForm::btLocateClick(TObject *Sender)
{
TLocateOptions Options;
   if (!cbCaseSensitive->Checked)
    Options<<loCaseInsensitive;
   if (cbPartialKey->Checked)
    Options<<loPartialKey;
   if (!ACRTable1->Locate("Company",SearchCondition->Text,Options))
    MessageDlg("Record not found.",mtInformation,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btLookupClick(TObject *Sender)
{
 Variant V;
 String Msg;

  V = ACRTable1->Lookup("Company",SearchCondition->Text,"Company;Address;Phone");
  if (VarIsNull(V))
    MessageDlg("Record not found.",mtInformation,TMsgDlgButtons()<<mbOK,0);
  else
  {
    Msg = "Record found: Company=";
    if (!VarIsNull(V.GetElement(0)))
     Msg += QuotedStr(String(V.GetElement(0)));
    else
     Msg += QuotedStr("null");
    Msg += ", Address=";
    if (!VarIsNull(V.GetElement(1)))
     Msg += QuotedStr(String(V.GetElement(1)));
    else
     Msg += QuotedStr("null");
    Msg += ", Phone=";
    if (!VarIsNull(V.GetElement(2)))
     Msg += QuotedStr(String(V.GetElement(2)));
    else
     Msg += QuotedStr("null");
    MessageDlg(Msg,mtInformation,TMsgDlgButtons()<<mbOK,0);
  }
}
//---------------------------------------------------------------------------

