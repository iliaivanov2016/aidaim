//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
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
 AnsiString log;
 EasyTable1->Close();
 ADODataSet1->Open();
 // Import all data from CSV file to EasyTable
 if (! EasyTable1->ImportTable(dsADO,ADODataSet1->IndexDefs,log))
  MessageDlg("Error importing table. Error Log: "+log,mtError,TMsgDlgButtons()<<mbOK,0);
 EasyTable1->Open(); // Open the EasyTable table
        
}
//---------------------------------------------------------------------------
 