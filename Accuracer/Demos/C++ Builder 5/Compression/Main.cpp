//---------------------------------------------------------------------------
#include <vcl.h>
#include <stdlib.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
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
void __fastcall TMainForm::NewCustBtnClick(TObject *Sender)
{
 TACRAdvFieldDef *AdvFieldDef = new TACRAdvFieldDef();
 int status;
 if (Form2->ShowModal()==mrCancel)
  {exit(status);}

 ACRTable1->Active = false;

 if (ACRTable1->Exists) {ACRTable1->DeleteTable();};

 ACRTable1->AdvFieldDefs->Clear();
 // Create advanced field definition for VarChar field
 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = Form2->Edit1->Text;
 AdvFieldDef->DataType = aftMemo;
 AdvFieldDef->Size = 1000;
 if (Form2->ComboBox2->ItemIndex > 0)
  {
   // Compression Algorithm (ZLIB, PPM, BZIP)
   switch (Form2->ComboBox2->ItemIndex)
   {
    case 1:AdvFieldDef->BLOBCompressionAlgorithm = caZLIB;
           break;
    case 2:AdvFieldDef->BLOBCompressionAlgorithm = caBZIP;
           break;
    case 3:AdvFieldDef->BLOBCompressionAlgorithm = caPPM;
           break;
   }
   // Compression Mode (from 1 to 9)
   AdvFieldDef->BLOBCompressionMode = Form2->SpinEdit3->Value;
  }
 // Block Size in Bytes
 if (Form2->SpinEdit1->Value != 102400)
  {AdvFieldDef->BLOBBlockSize = Form2->SpinEdit1->Value;};

 AdvFieldDef = NULL;
 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = "Company";
 AdvFieldDef->DataType = aftChar;
 AdvFieldDef->Size = 25;
 ACRTable1->CreateTable();
 DBMemo1->DataField = Form2->Edit1->Text;
 ACRTable1->Active = true;
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::FormCreate(TObject *Sender)
{
 ACRDatabase1->Connected = true;
 if (ACRTable1->Exists)
  {ACRTable1->Active = true;}
}
//---------------------------------------------------------------------------
