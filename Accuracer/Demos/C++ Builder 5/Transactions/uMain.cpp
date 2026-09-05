//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
  ACRDatabase1->StartTransaction();
  try {
    ACRTable1->Insert();
    ACRTable1->FieldByName("Name")->AsString = "aaa_"+
      ACRTable1->FieldByName("ID")->AsString;
    ACRTable1->Post();
    ACRTable1->Insert();
    ACRTable1->FieldByName("Name")->AsString = "bbb_"+
      ACRTable1->FieldByName("ID")->AsString;
    ACRTable1->Post();
    ACRDatabase1->Commit(true);
    ShowMessage("Transaction committed");
  } catch (...) {
    ACRDatabase1->Rollback();
    ACRTable1->Refresh();
    ShowMessage("Error during the transaction, Rollback called");
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button2Click(TObject *Sender)
{
  ACRDatabase1->StartTransaction();
  try {
    ACRTable1->Insert();
    ACRTable1->FieldByName("Name")->AsString = "test";
    ACRTable1->Post();
    ACRTable1->Insert();
    ACRTable1->FieldByName("Name")->AsString = "test";
    // this will raise an exception due to violation of the unique index on field Name
    ACRTable1->Post();
    ACRDatabase1->Commit(true);
    ShowMessage("Transaction committed");
  } catch (...) {
    ACRTable1->Cancel();
    ACRDatabase1->Rollback();
    ACRTable1->Refresh();
    ShowMessage("Error during the transaction, Rollback called");
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::bnCloseClick(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button4Click(TObject *Sender)
{
  ACRQuery1->Close();
  ACRQuery2->SQL->Clear();
  ACRQuery2->SQL->Add("START TRANSACTION;");
  ACRQuery2->SQL->Add("INSERT INTO TEST (NAME) VALUES(""sql_insert1"");");
  ACRQuery2->SQL->Add("INSERT INTO TEST (NAME) VALUES(""sql_insert2"");");
  ACRQuery2->SQL->Add("COMMIT;");
  try {
    ACRQuery2->ExecSQL();
    ShowMessage("Transaction committed");
  } catch (...) {
    ACRQuery2->SQL->Text = "ROLLBACK";
    ACRQuery2->ExecSQL();
    ACRQuery1->Refresh();
    ShowMessage("Error during the transaction, Rollback called");
  }
  ACRQuery1->Open();

}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button3Click(TObject *Sender)
{
  ACRQuery1->Close();
  ACRQuery2->SQL->Clear();
  ACRQuery2->SQL->Add("START TRANSACTION;");
  ACRQuery2->SQL->Add("INSERT INTO TEST (NAME) VALUES(""sql_insert3"");");
  ACRQuery2->SQL->Add("INSERT INTO TEST (NAME) VALUES(""sql_insert3"");");
  ACRQuery2->SQL->Add("COMMIT;");
  try {
    ACRQuery2->ExecSQL();
    ShowMessage("Transaction committed");
  } catch (...) {
    ACRQuery2->SQL->Text = "ROLLBACK";
    ACRQuery2->ExecSQL();
    ShowMessage("Error during the transaction, Rollback called");
  }
  ACRQuery1->Open();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::FormCreate(TObject *Sender)
{
 ACRDatabase1->Close();
 if (! ACRDatabase1->Exists)
  {
   ACRDatabase1->CreateDatabase();
   ACRTable1->FieldDefs->Clear();
   ACRTable1->FieldDefs->Add("ID",ftAutoInc,0,false);
   ACRTable1->FieldDefs->Add("Name",ftFixedChar,25,false);
   ACRTable1->IndexDefs->Clear();
   ACRTable1->IndexDefs->Add("idxName","Name",TIndexOptions() << ixUnique);
   ACRTable1->CreateTable();
  }
 ACRDatabase1->Open();
 ACRTable1->Open();
 ACRQuery1->Open();
}
//---------------------------------------------------------------------------

