//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
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
/*  //if table doesn't exist
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
   EasyTable1->IndexDefs->Add("ByCompanyAsc","Company",TIndexOptions()<<ixCaseInsensitive);
   EasyTable1->IndexDefs->Add("ByCompanyDesc","Company",TIndexOptions()<<ixDescending);
   EasyTable1->CreateTable();
   // open table
   EasyTable1->Active = true;
   // add complex index
   EasyTable1->AddIndex("ByAddrAscCompanyDesc","Address;Company",TIndexOptions()<<ixCaseInsensitive,"Company","");
  }
  // open table
  EasyTable1->Active = true;
  // update buttons
  UpdateButtons();*/
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::UpdateButtons()
{
}
//---------------------------------------------------------------------------







