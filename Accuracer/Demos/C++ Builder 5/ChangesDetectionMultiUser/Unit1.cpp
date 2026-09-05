//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma link "ACRTypes"
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
 TDateTime dt;
 dt = Now();
db1->DatabaseFileName = IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))+"test.adb";
 if (!db1->Exists)
  {
    db1->CreateDatabase();
    db1->Open();
    t1->ClearDefinitions();
    t1->AdvFieldDefs->Add("ID",aftAutoInc);
    t1->AdvFieldDefs->Add("Name",aftWideChar,20);
    t1->AdvFieldDefs->Add("RegDate",aftDateTime);
    t1->CreateTable();
    t1->Open();
    t1->InsertRecord(ARRAYOFCONST((NULL,"User #1",DateTimeToStr(dt) )));
    Sleep(100);
    t1->InsertRecord(ARRAYOFCONST((NULL,"User #2",DateTimeToStr(dt) )));
    Sleep(100);
    t1->InsertRecord(ARRAYOFCONST((NULL,"User #3",DateTimeToStr(dt) )));
   }
 else
  {
   db1->Open();
   t1->Open();
  };
 db2->DatabaseFileName = db1->DatabaseFileName;
 db2->Open();
 t2->Open();
 FState = t1->GetTableState();
 Timer1->Enabled = True;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Timer1Timer(TObject *Sender)
{
 TACRTableState tempState;
 String s;

 tempState = t1->GetTableState();
 if (tempState.TableState != FState.TableState)
   {
    FState = tempState;
    t1->Refresh();
    t2->Refresh();
    s = ACRGetLastTableOpertaion(FState.LastTableOperation)+"\t"+DateTimeToStr(FState.LastModificationDate);
    reLog->Lines->Add(s);
   };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
