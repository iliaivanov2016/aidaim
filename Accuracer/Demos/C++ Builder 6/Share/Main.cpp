//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
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
 ACRTable1->Active = true;
 ACRTable2->Active = true;
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::ACRTable1AfterDelete(TDataSet *DataSet)
{
 ACRTable2->Refresh();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::ACRTable1AfterPost(TDataSet *DataSet)
{
 ACRTable2->Refresh();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::ACRTable2AfterDelete(TDataSet *DataSet)
{
 ACRTable1->Refresh();
}
//---------------------------------------------------------------------------

void __fastcall TMainForm::ACRTable2AfterPost(TDataSet *DataSet)
{
 ACRTable1->Refresh();
}
//---------------------------------------------------------------------------

