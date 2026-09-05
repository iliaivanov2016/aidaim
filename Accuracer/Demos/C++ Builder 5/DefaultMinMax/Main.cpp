//---------------------------------------------------------------------------
#include <vcl.h>
#include <stdlib.h>
#pragma hdrstop

#include "Main.h"
#include "Cust.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)#pragma link "ACRMain"

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

 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = Form2->Edit1->Text;
 switch (Form2->ComboBox2->ItemIndex)
 {
  case 0: AdvFieldDef->DataType = aftString;
          break;
  case 1: AdvFieldDef->DataType = aftInteger;
          break;
 }
 if (AdvFieldDef->DataType == aftString)
  { AdvFieldDef->Size = 30;
   if (Form2->Edit2->Text != "")
    {AdvFieldDef->DefaultValue->AsString = Form2->Edit2->Text;}
   if (Form2->Edit3->Text != "")
    {AdvFieldDef->MinValue->AsString = Form2->Edit3->Text;}
   if (Form2->Edit4->Text != "")
    {AdvFieldDef->MaxValue->AsString = Form2->Edit4->Text;}
  }
 else
  {
   AdvFieldDef->Size = 0;
   if (Form2->Edit2->Text != "")
    {AdvFieldDef->DefaultValue->AsInteger = StrToInt(Form2->Edit2->Text);}
   if (Form2->Edit3->Text != "")
    {AdvFieldDef->MinValue->AsInteger = StrToInt(Form2->Edit3->Text);}
   if (Form2->Edit4->Text != "")
    {AdvFieldDef->MaxValue->AsInteger = StrToInt(Form2->Edit4->Text);}
  }
 
 AdvFieldDef = NULL;
 AdvFieldDef = ACRTable1->AdvFieldDefs->AddFieldDef();
 AdvFieldDef->Name = "Company";
 AdvFieldDef->DataType = aftChar;
 AdvFieldDef->Size = 25;
 ACRTable1->CreateTable();
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
