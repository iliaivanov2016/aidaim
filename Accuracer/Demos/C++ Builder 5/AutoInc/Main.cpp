//---------------------------------------------------------------------------
#include <vcl.h>
#include <stdlib.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"

//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma link "ACRTypes"
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
 ACRDatabase1->Connected = true;
 if (ACRTable1->Exists)
  {ACRTable1->Active = true;}
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
 // Create advanced field definition for AutoInc field
 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = Form2->Edit1->Text;
 switch (Form2->ComboBox1->ItemIndex)
 {
  case 0:
   AdvFieldDef->DataType = aftAutoInc;
   break;
  case 1:
   AdvFieldDef->DataType = aftAutoIncShortint;
   break;
  case 2:
   AdvFieldDef->DataType = aftAutoIncSmallint;
   break;
  case 3:
   AdvFieldDef->DataType = aftAutoIncInteger;
   break;
  case 4:
   AdvFieldDef->DataType = aftAutoIncLargeint;
   break;
  case 5:
   AdvFieldDef->DataType = aftAutoIncByte;
   break;
  case 6:
   AdvFieldDef->DataType = aftAutoIncWord;
   break;
  case 7:
   AdvFieldDef->DataType = aftAutoIncCardinal;
   break;
 }
 AdvFieldDef->Size = 0;
 // AutoincMinValue
 if (Form2->SpinEdit4->Value > -1)
  {AdvFieldDef->AutoincMinValue = Form2->SpinEdit4->Value;};
 // AutoincMaxValue
 if (Form2->SpinEdit1->Value > 0)
  {AdvFieldDef->AutoincMaxValue = Form2->SpinEdit1->Value;};
 // AutoincInitialValue
 if (Form2->SpinEdit2->Value > -1)
  {AdvFieldDef->AutoincInitialValue = Form2->SpinEdit2->Value;};
 // AutoincIncrement
 if (Form2->SpinEdit3->Value > 1)
  {AdvFieldDef->AutoincIncrement = Form2->SpinEdit3->Value;};
 // AutoincCycled
 AdvFieldDef->AutoincCycled = Form2->CheckBox1->Checked;
 
 AdvFieldDef = NULL;
 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = "Company";
 AdvFieldDef->DataType = aftChar;
 AdvFieldDef->Size = 25;
 ACRTable1->CreateTable();
 ACRTable1->Active = true;
}
//---------------------------------------------------------------------------
