//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
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
 ACRTable1->FieldDefs->Clear();
 ACRTable1->AdvFieldDefs->Clear();
 ACRTable1->IndexDefs->Clear();
 ACRTable1->AdvIndexDefs->Clear();
 ACRTable1->ForeignKeyDefs->Clear();
 ACRTable1->AdvFieldDefs->Add("Text_char",aftWideChar,300,False);
 ACRTable1->AdvFieldDefs->Add("Text_varchar",aftWideString,300,False);
 ACRTable1->AdvFieldDefs->Add("Text_memo",aftWideMemo,300,False);
 ACRTable1->CreateTable();
 ACRTable1->Open();
 // Unicode specific characters
 ACRTable1->AppendRecord(ARRAYOFCONST(("","","")));
 ACRTable1->First();
 WideString ws = "WideChar: \t"+ACRTable1->FieldByName("Text_char")->AsWideString+"\r\n"
				+"WideVarChar: \t"+ACRTable1->FieldByName("Text_varchar")->AsWideString+"\r\n"
				+"WideMemo: \t"+ACRTable1->FieldByName("Text_memo")->AsWideString+"\r\n";
/*
 "WideChar: \t"+ACRTable1->Fields[0]->AsWideString+"\r\n"+
 "WideVarChar: \t"+ACRTable1->Fields[1]->AsWideString+"\r\n"+
 "WideMemo: \t"+ACRTable1->Fields[2]->AsWideString;
 */
 ShowMessage(ws);
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button1Click(TObject *Sender)
{
 Close();
 Application->Terminate();
}
//---------------------------------------------------------------------------

