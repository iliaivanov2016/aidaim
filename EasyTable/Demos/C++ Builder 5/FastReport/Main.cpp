//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma link "FR_PTabl"
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
  // add filter condition (it is locale dependent, so we should generate this)
  FilterCondition->Items->Add("LastInvoiceDate <= "+QuotedStr(DateToStr(Now())));
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

 // Filter On, Off buttons
 if (EasyTable1->Filtered)
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

  EasyTable1->Filter = FilterCondition->Text;
  if (!cbCaseSensitive->Checked)
    fo << foCaseInsensitive;
  if (cbNoPartialCompare->Checked)
    fo << foNoPartialCompare;
  EasyTable1->FilterOptions = fo;
  EasyTable1->Filtered = true;
  UpdateButtons();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFilterOffClick(TObject *Sender)
{
  EasyTable1->Filtered = false;
  UpdateButtons();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFindFirstClick(TObject *Sender)
{
TFilterOptions fo;

  EasyTable1->Filter = FilterCondition->Text;
  if (!cbCaseSensitive->Checked)
    fo << foCaseInsensitive;
  if (cbNoPartialCompare->Checked)
    fo << foNoPartialCompare;
  EasyTable1->FilterOptions = fo;
  if (!EasyTable1->FindFirst())
    MessageDlg("Record not found.", mtInformation, TMsgDlgButtons()<<mbOK, 0);
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::btFindNextClick(TObject *Sender)
{
 if (!EasyTable1->FindNext())
  MessageDlg("Record not found.", mtInformation, TMsgDlgButtons()<<mbOK, 0);
}
//---------------------------------------------------------------------------



void __fastcall TMainForm::bnReportClick(TObject *Sender)
{
 frPrintTable1->ShowReport();        
}
//---------------------------------------------------------------------------

