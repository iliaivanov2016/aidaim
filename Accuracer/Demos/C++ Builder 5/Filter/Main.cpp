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
  // add filter condition (it is locale dependent, so we should generate this)
  FilterCondition->Items->Add("LastInvoiceDate <= "+QuotedStr(DateToStr(Now())));
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

 // Filter On, Off buttons
 if (ACRTable1->Filtered)
 {
   btFilterOn->Enabled = false;
   btFilterOff->Enabled = true;
 }
 else
 {
   btFilterOn->Enabled = true;
   btFilterOff->Enabled = false;
 }
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFilterOnClick(TObject *Sender)
{
TFilterOptions fo;

  ACRTable1->Filter = FilterCondition->Text;
  if (!cbCaseSensitive->Checked)
    fo << foCaseInsensitive;
  if (cbNoPartialCompare->Checked)
    fo << foNoPartialCompare;
  ACRTable1->FilterOptions = fo;
  ACRTable1->Filtered = true;
  UpdateButtons();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFilterOffClick(TObject *Sender)
{
  ACRTable1->Filtered = false;
  UpdateButtons();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFindFirstClick(TObject *Sender)
{
TFilterOptions fo;

  ACRTable1->Filter = FilterCondition->Text;
  if (!cbCaseSensitive->Checked)
    fo << foCaseInsensitive;
  if (cbNoPartialCompare->Checked)
    fo << foNoPartialCompare;
  ACRTable1->FilterOptions = fo;
  if (!ACRTable1->FindFirst())
    MessageDlg("Record not found.", mtInformation, TMsgDlgButtons()<<mbOK, 0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFindNextClick(TObject *Sender)
{
 if (!ACRTable1->FindNext())
  MessageDlg("Record not found.", mtInformation, TMsgDlgButtons()<<mbOK, 0);
}
//---------------------------------------------------------------------------


