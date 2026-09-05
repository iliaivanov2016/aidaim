//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
#include "BkThread.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma resource "*.dfm"
TfMain *fMain;
//---------------------------------------------------------------------------
__fastcall TfMain::TfMain(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfMain::FormCreate(TObject *Sender)
{
 if (!EasyDatabase1->Exists)
  EasyDatabase1->CreateDatabase();
  //if table doesn't exist
  if (!EasyTable1->Exists)
  {
   //set table structure
   EasyTable1->FieldDefs->Clear();
   EasyTable1->FieldDefs->Add("id",ftAutoInc,0,False);
   EasyTable1->FieldDefs->Add("Time",ftTime,0,False);
   EasyTable1->FieldDefs->Add("Name",ftString,300,False);
   EasyTable1->FieldDefs->Add("Integer",ftInteger,0,False);
   EasyTable1->FieldDefs->Add("Money",ftCurrency,0,False);

   EasyTable1->IndexDefs->Clear();
   EasyTable1->CreateTable();
  }
  // open table
  EasyTable1->Active = true;
}
//---------------------------------------------------------------------------

void __fastcall TfMain::UpdateButtons()
{
}
//---------------------------------------------------------------------------

void __fastcall TfMain::btStartClick(TObject *Sender)
{
 int i;
 
 // create threads
 for (i=0; i<10; i++)
   new TQueryThread(False);
}
//---------------------------------------------------------------------------

void __fastcall TfMain::EasyTable1AfterScroll(TDataSet *DataSet)
{
 lbRecNo->Caption = IntToStr(EasyTable1->RecNo);
}
//---------------------------------------------------------------------------

