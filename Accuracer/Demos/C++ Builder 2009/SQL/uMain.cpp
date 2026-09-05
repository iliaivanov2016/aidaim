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
 reSQL->Text = ACRQuery1->SQL->Text;
 ACRDatabase1->DatabaseFileName =
  IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)))
  +"..\\..\\Data\\DBDemos.adb";
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnCloseClick(TObject *Sender)
{
 Close();
 Application->Terminate();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnExecSQLClick(TObject *Sender)
{
 unsigned int t;
 double d,d1;

 try
 {
  t = Acrlinux::GetTickCount();
  ACRQuery1->SQL->Text = reSQL->Text;
  ACRQuery1->ExecSQL();
  t = Acrlinux::GetTickCount() - t;
  d = t / 1000.0;
  d1 = ACRQuery1->RowsAffected;
  bnExecSQL->Hint = "Query execution time, seconds: "+
	   FormatFloat("#,##0->000",d)+"-> Rows affected: "+FormatFloat("#,##0",d1);
  lbRecCount->Caption = "RecordCount: "+ FormatFloat("#,##0",d1);
  lbTime->Caption = "Time, sceonds: "+ FormatFloat("#,##0.000",d);
 }
 catch (const Exception &e)
 {
  MessageDlg("Error executing SQL script: \n"+e.Message,mtError,
	TMsgDlgButtons()<<mbOK,0);
 }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnOpenClick(TObject *Sender)
{
 unsigned int t;
 double d,d1;

 try
 {
  t = Acrlinux::GetTickCount();
  ACRQuery1->SQL->Text = reSQL->Text;
  ACRQuery1->Open();
  t = Acrlinux::GetTickCount() - t;
  d = t / 1000.0;
  d1 = ACRQuery1->RowsAffected;
  bnExecSQL->Hint = "Query execution time, seconds: "+
	   FormatFloat("#,##0->000",d)+"-> Rows affected: "+FormatFloat("#,##0",d1);
  lbRecCount->Caption = "RecordCount: "+ FormatFloat("#,##0",d1);
  lbTime->Caption = "Time, sceonds: "+ FormatFloat("#,##0.000",d);
 }
 catch (const Exception &e)
 {
  MessageDlg("Error executing SQL script: \n"+e.Message,mtError,
	TMsgDlgButtons()<<mbOK,0);
 }
}
//---------------------------------------------------------------------------
