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
 AnsiString Log;
 ACRTable1->Close();
 ADODataSet1->Open();
 // Import all data from CSV file to Accuracer Table
 if (! ACRTable1->ImportTable((TDataSet *)ADODataSet1, Log))
	 MessageDlg("Error importing table-> Error Log: "+Log, mtError,
		TMsgDlgButtons()<<mbOK, 0);
 ACRTable1->Open(); // Open the Accuracer Table table
}
//---------------------------------------------------------------------------
