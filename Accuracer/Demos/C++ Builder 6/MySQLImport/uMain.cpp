//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uConnect.h"
#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "mySQLDbTables"
#pragma link "ACRMain"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------


void __fastcall TForm1::ConnectBtnClick(TObject *Sender)
{
  if (Database1->Connected)
  {
     ConnectBtn->Caption = "Connect";
     Database1->Connected = false;
  }
  else
  {
     if (ShowConnectDlg(Database1))
     {
        try
        {
          Database1->Connected = true;
          Screen->Cursor = crSQLWait;
          DataSource1->DataSet->Active = true;
          Screen->Cursor = crDefault;
          ConnectBtn->Caption = "Disconnect";
        }
        catch (...)
        {
         ShowMessage("FishFact connection fault");
        }
     }
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::RadioGroup1Click(TObject *Sender)
{
 if (RadioGroup1->ItemIndex == 0)
  {
   DataSource1->DataSet = Table1;
   if (Table1->Exists)
    Table1->Open();
  }
 else
  {
   if (ACRDatabase1->Exists)
   {
    ACRDatabase1->Open();
    DataSource1->DataSet = ACRTable1;
    if (ACRTable1->Exists)
     ACRTable1->Open();
   }
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::ImportBtnClick(TObject *Sender)
{
 AnsiString s;
 Table1->DisableControls();
 ACRTable1->DisableControls();

 if (! ACRDatabase1->Exists)
  ACRDatabase1->CreateDatabase();
 ACRDatabase1->Open();
 ACRTable1->Close();
 s = "";
 ACRTable1->ImportTable(Table1,s);

 if (s == "")
  ShowMessage("Data imported successfully");
 else
  ShowMessage("Data imported with errors: "+s);

 Table1->EnableControls();
 ACRTable1->EnableControls();
}
//---------------------------------------------------------------------------
