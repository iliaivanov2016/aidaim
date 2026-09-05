//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "SQLMemMain"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 tSource->Close();

 // field definitions were filled using design-time FieldDefs editor
 tSource->CreateTable();
 tSource->Open();
 tSource->Insert();
 tSource->FieldByName("Company")->AsString = "AidAim Software LLC";
 tSource->FieldByName("Address")->AsString = "555 Vine Ave., Suite 110, Highland Park, IL 60035, USA";
 tSource->FieldByName("TaxRate")->AsFloat = 20.5;
 tSource->FieldByName("LastInvoiceDate")->AsDateTime = Now();
 tSource->Post();
 tSource->Insert();
 tSource->FieldByName("Company")->AsString = "Borland Software Corporation";
 tSource->Post();
 tSource->Insert();
 tSource->FieldByName("Company")->AsString = "Oracle Corporation";
 tSource->Post();
 tSource->Insert();
 tSource->FieldByName("Company")->AsString = "Microsoft Corporation";
 tSource->Post();
 tSource->Insert();
 tSource->FieldByName("Company")->AsString = "IBM Corporation";
 tSource->Post();
 tSource->GetIndexNames(cmbxSourceIndex->Items);
 cmbxMode->ItemIndex = 2;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxSourceIndexChange(TObject *Sender)
{
  if (cmbxSourceIndex->ItemIndex != -1)
   tSource->IndexName = cmbxSourceIndex->Items->Strings[cmbxSourceIndex->ItemIndex];
  else
   tSource->IndexName = "";

}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxDestIndexChange(TObject *Sender)
{
  if (cmbxDestIndex->ItemIndex != -1)
   tDest->IndexName = cmbxDestIndex->Items->Strings[cmbxDestIndex->ItemIndex];
  else
   tDest->IndexName = "";

}
//---------------------------------------------------------------------------

void __fastcall TForm1::chkbxAbortKeyClick(TObject *Sender)
{
  BatchMove1->AbortOnKeyViol = chkbxAbortKey->Checked;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::chkbxAbortProblemClick(TObject *Sender)
{
  BatchMove1->AbortOnProblem = chkbxAbortProblem->Checked;
}
//---------------------------------------------------------------------------
bool IsStringsEqual(AnsiString s1,AnsiString s2)
{
 return (UpperCase(s1) == UpperCase(s2));
};

void __fastcall TForm1::cmbxModeChange(TObject *Sender)
{
  if (cmbxMode->ItemIndex != -1)
  {
    if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Append"))
      BatchMove1->Mode = Sqlmemmain::batAppend;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Copy"))
      BatchMove1->Mode = Sqlmemmain::batCopy;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Append Update"))
      BatchMove1->Mode = Sqlmemmain::batAppendUpdate;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Delete"))
      BatchMove1->Mode = Sqlmemmain::batDelete;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Update"))
      BatchMove1->Mode = Sqlmemmain::batUpdate;
    else
      MessageDlg("Batch mode not found",mtError,TMsgDlgButtons()<<mbOK,0);
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button1Click(TObject *Sender)
{
 AnsiString s;

  if ((cmbxMode->Items->Strings[cmbxMode->ItemIndex] != ""))
  {
    BatchMove1->RecordCount = StrToInt(edtRecCount->Text);
    BatchMove1->Source = tSource;
    BatchMove1->Destination = tDest;
  }
 else
  {
    MessageDlg("Incomplete input->",mtError,TMsgDlgButtons()<<mbOK,0);
    return;
  };
  BatchMove1->Execute();  // run the batchmove
  if (BatchMove1->Mode == Sqlmemmain::batCopy)
   tDest->Open();
  s = "BatchMove complete. Number of records applied: "+IntToStr(BatchMove1->MovedCount)+
       "\r\n" + "Problem record count: "+ IntToStr(BatchMove1->ProblemCount) +
       "\r\n" + "Changed record count: "+ IntToStr(BatchMove1->ChangedCount) +
       "\r\n" + "Key violation count: "+ IntToStr(BatchMove1->KeyViolCount);
  MessageDlg(s,mtInformation,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------

