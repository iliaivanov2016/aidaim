//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
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
void __fastcall TForm1::FormCreate(TObject *Sender)
{
  ACRTable1->InMemory = true;
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
}
//---------------------------------------------------------------------------

void __fastcall TForm1::btSaveTableClick(TObject *Sender)
{
 ACRTable1->Close();
 ACRTable1->SaveTableToFile("customers.tbl",caZLIB,3,4);
 ACRTable1->Open();
}
//---------------------------------------------------------------------------


void __fastcall TForm1::btLoadClick(TObject *Sender)
{
 ACRTable1->Close();
 ACRTable1->LoadTableFromFile("customers.tbl");
 ACRTable1->Open();
}
//---------------------------------------------------------------------------

