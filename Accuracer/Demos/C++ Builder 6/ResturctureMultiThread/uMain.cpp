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
void __fastcall TForm1::Button2Click(TObject *Sender)
{
  FFinished = true;
  Application->Terminate();
  Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 ACRDatabase1->CreateDatabase();
 ACRDatabase1->Open();
 ACRTable1->AdvFieldDefs->Add("id",aftAutoInc);
 ACRTable1->AdvFieldDefs->Add("str",aftChar,20);
 ACRTable1->CreateTable();
 ACRTable1->Open();
 ACRTable1->Insert();
 ACRTable1->Fields->Fields[1]->AsString = "test 1";
 ACRTable1->Post();
 ACRTable1->Insert();
 ACRTable1->Fields->Fields[1]->AsString = "test 2";
 ACRTable1->Post();
 ACRTable1->Insert();
 ACRTable1->Fields->Fields[1]->AsString = "test 3";
 ACRTable1->Post();

}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 TRestructureThread *th;
 FFinished = false;
 ACRTable1->Close();
 Button1->Enabled = false;
 try
 {
  th = new TRestructureThread((WideString)ACRDatabase1->DatabaseFileName,ACRTable1->TableName);
  th->Resume();
  while ((!FFinished) && (!Application->Terminated)) 
   {
    Sleep(16);
    Application->ProcessMessages();
   };
 }
 __finally
 {
   ACRTable1->Open();
   Button1->Enabled = true;
 };

}
//---------------------------------------------------------------------------
