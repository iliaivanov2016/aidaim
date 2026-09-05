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
 Caption = "SQLMemTable Basic Demo. (c) AidAim Software LLC, 2003.";
 SQLMemTable1->Close();

 // field definitions were filled using design-time FieldDefs editor
 SQLMemTable1->CreateTable();
 SQLMemTable1->Open();
 SQLMemTable1->Insert();
 SQLMemTable1->FieldByName("Company")->AsString = "AidAim Software LLC";
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

 // open query
 SQLMemQuery1->Open();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 Close();        
}
//---------------------------------------------------------------------------

