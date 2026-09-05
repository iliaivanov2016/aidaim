//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
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

  EasyTable2->InMemory = true;
  EasyTable2->Active = true;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::btSaveTableClick(TObject *Sender)
{
 EasyTable2->SaveTable();
}
//---------------------------------------------------------------------------

