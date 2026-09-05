//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
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
 EasyTable1->Active = true;
 EasyTable2->Active = true;
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::EasyTable1AfterDelete(TDataSet *DataSet)
{
 EasyTable2->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::EasyTable1AfterPost(TDataSet *DataSet)
{
 EasyTable2->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::EasyTable2AfterDelete(TDataSet *DataSet)
{
 EasyTable1->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::EasyTable2AfterPost(TDataSet *DataSet)
{
 EasyTable1->Refresh();
}
//---------------------------------------------------------------------------
