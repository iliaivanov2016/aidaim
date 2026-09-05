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
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 ACRDatabase1->Open();        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button3Click(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 ACRQuery1->Close();
 ACRQuery1->SQL->Text = Memo1->Text;
 try
 {
  ACRQuery1->Open();
  gbResult->Caption = " Query Result: "+IntToStr(ACRQuery1->RecordCount)+" records";
 }
 catch (Exception *e)
 {
    ShowMessage("Errors occurs while opening query: "+e->Message);
    ACRQuery1->Close();
    gbResult->Caption = " Query Result: ";
 };
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button2Click(TObject *Sender)
{
 ACRQuery1->Close();
 ACRQuery1->SQL->Text = Memo1->Text;
 try
 {
  ACRQuery1->ExecSQL();
  ShowMessage("Script was successfully executed. Rows affected = "+IntToStr(ACRQuery1->RowsAffected));
 }
 catch (Exception *e)
 {
   ShowMessage("Errors occurs while executing script: "+e->Message);
 };
}
//---------------------------------------------------------------------------
