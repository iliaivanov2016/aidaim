//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uBatch.h"
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
 SourceTable->Open();
 DestTable->FieldDefs->Assign(SourceTable->FieldDefs);
 DestTable->IndexDefs->Assign(SourceTable->IndexDefs);
 DestTable->CreateTable();
 DestTable->Open();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 AnsiString Log;

 switch (rgMode->ItemIndex)
  {
   case 0 : if (! DestTable->AddRecords(SourceTable, arAppend, Log))
    { MessageDlg("Error adding records: "+Log,mtError,TMsgDlgButtons()<<mbOK,0);}
   case 1 : if (! DestTable->AddRecords(SourceTable, arUpdate, Log))
    { MessageDlg("Error adding records: "+Log,mtError,TMsgDlgButtons()<<mbOK,0);}
   case 2 : if (! DestTable->AddRecords(SourceTable, arAppendUpdate, Log))
    { MessageDlg("Error adding records: "+Log,mtError,TMsgDlgButtons()<<mbOK,0);}
   case 3 : if (! DestTable->AddRecords(SourceTable, arReplace, Log))
    { MessageDlg("Error adding records: "+Log,mtError,TMsgDlgButtons()<<mbOK,0);}
  }
}
//---------------------------------------------------------------------------
