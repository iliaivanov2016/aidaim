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
 OpenDialog1->InitialDir = ExtractFilePath(Application->ExeName);
 SaveDialog1->InitialDir = ExtractFilePath(Application->ExeName);

 Caption = "SQLMemTable LoadSave Demo. (c) AidAim Software, 2003-2008.";
 SQLMemTable1->Close();

 // field definitions were filled using design-time FieldDefs editor
 SQLMemTable1->CreateTable();
 SQLMemTable1->Open();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "AidAim Software";
 SQLMemTable1->FieldByName("Address")->AsString = "555 Vine Ave., Suite 110, Highland Park, IL 60035, USA";
 SQLMemTable1->FieldByName("TaxRate")->AsFloat = 20.5;
 SQLMemTable1->FieldByName("LastInvoiceDate")->AsDateTime = Now();
 SQLMemTable1->Post();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "Borland Software Corporation";
 SQLMemTable1->Post();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "Oracle Corporation";
 SQLMemTable1->Post();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "Microsoft Corporation";
 SQLMemTable1->Post();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "IBM Corporation";
 SQLMemTable1->Post();

}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnLoadClick(TObject *Sender)
{
 if (OpenDialog1->Execute())
  {
   SQLMemTable1->Close();
   try
   {
	 if (SQLMemTable1->Exists)
	  SQLMemTable1->DeleteTable(True);
	 SQLMemTable1->LoadTableFromFile(OpenDialog1->FileName);
     SQLMemTable1->Open();
     MessageDlg("Table was successfully loaded from file "+OpenDialog1->FileName,
       mtInformation,TMsgDlgButtons()<<mbOK,0);
   }
   catch (...)
   {
     MessageDlg("Error - Cannot load table from file "+OpenDialog1->FileName,
       mtError,TMsgDlgButtons()<<mbOK,0);
     SQLMemTable1->Close();
   }
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnSaveClick(TObject *Sender)
{
 if (SaveDialog1->Execute())
  {
   SQLMemTable1->Close();
   try
   {
     SQLMemTable1->SaveTableToFile(SaveDialog1->FileName);
     SQLMemTable1->Open();
     MessageDlg("Table was successfully saved to file "+SaveDialog1->FileName,
       mtInformation,TMsgDlgButtons()<<mbOK,0);
   }
   catch (...)
   {
     MessageDlg("Error - Cannot save table to file "+SaveDialog1->FileName,
       mtError,TMsgDlgButtons()<<mbOK,0);
     SQLMemTable1->Close();
   }
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnExitClick(TObject *Sender)
{
 Close();        
}
//---------------------------------------------------------------------------
