//---------------------------------------------------------------------------
#include <vcl.h>
#include <stdlib.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma resource "*.dfm"
TfmMain *fmMain;
//---------------------------------------------------------------------------
__fastcall TfmMain::TfmMain(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button3Click(TObject *Sender)
{
 Close();
 Application->Terminate();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormCreate(TObject *Sender)
{
  ACRDatabase1->DatabaseFileName = ExtractFilePath(Application->ExeName)+"test.adb";
  if (! ACRDatabase1->Exists)
   ACRDatabase1->CreateDatabase();
  ACRDatabase1->Open();
  if (! LogTable->Exists)
   LogTable->CreateTable();
  LogTable->Open();
  if (!TestTable->Exists) 
   TestTable->CreateTable();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button1Click(TObject *Sender)
{
 if (!TestTable->Active) 
  TestTable->Open();
 TestTable->Insert();
 TestTable->FieldByName("ID")->AsInteger = random(MaxInt);
 TestTable->FieldByName("Str")->AsString = "Table Test!!! "+IntToStr(random(MaxInt));
 TestTable->Post();
 TestTable->Edit();
 TestTable->FieldByName("ID")->AsInteger = -TestTable->FieldByName("ID")->AsInteger;
 TestTable->FieldByName("Str")->AsString = "Table Test - record updated!!! "+IntToStr(random(MaxInt));
 TestTable->Post();
 TestTable->Delete();
 TestTable->Close();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button2Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = "INSERT INTO Test VALUES ("+IntToStr(random(MaxInt))+", "+
                       "\"Query Test!!! "+IntToStr(random(MaxInt))+"\");";
 ACRQuery1->ExecSQL();

 ACRQuery1->SQL->Text = "UPDATE Test SET ID = -ID, Str = Str + \"Updated By SQL!!!\";";
 ACRQuery1->ExecSQL();

 ACRQuery1->SQL->Text = "DELETE FROM Test WHERE Str LIKE \"%Updated%\";";
 ACRQuery1->ExecSQL();

 ACRQuery1->RequestLive = True;
 ACRQuery1->SQL->Text = "SELECT * FROM Test";
 ACRQuery1->Open();
 ACRQuery1->InsertRecord(ARRAYOFCONST((random(MaxInt),"Insert By Live Query")));
 ACRQuery1->Edit();
 ACRQuery1->Fields->Fields[0]->AsInteger = 0;
 ACRQuery1->Fields->Fields[1]->AsString = "Live edit by query!!!";
 ACRQuery1->Post();

 ACRQuery1->Delete();
 ACRQuery1->Close();
 ACRQuery1->RequestLive = False;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button4Click(TObject *Sender)
{
 if (!TestTable->Active)
  TestTable->Open();
 TestTable->Insert();
 TestTable->FieldByName("ID")->AsInteger = random(MaxInt);
 TestTable->FieldByName("Str")->AsString = "Block";
 try
 {
  TestTable->Post();
 }
 catch (Exception &e)
 {
  TestTable->Cancel();
  throw Exception(e.Message);
 }
 TestTable->Close();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button5Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = "SELECT * FROM Log";
 ACRQuery1->Open();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::ACRDatabase1BeforeExecuteSQL(TACRQuery *Sender,
      bool &Abort)
{
 AnsiString s = AnsiUpperCase(Sender->SQL->Text);
 Abort = (s.Pos(AnsiUpperCase(LogTable->TableName)) > 0);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::ACRDatabase1BeforeInsertRecord(
      TACRDataSet *Sender, const AnsiString TableName,
      const TACRArrayOfTACRVariant FieldValues, bool &Abort)
{
 if (AnsiUpperCase(TableName) == AnsiUpperCase(LogTable->TableName))
  return;
 Abort = (FieldValues[1]->AsString == "Block");
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::ACRDatabase1AfterInsertRecord(TACRDataSet *Sender,
      const AnsiString TableName, const TACRArrayOfTACRVariant FieldValues)
{
 AnsiString et;
 if (AnsiUpperCase(TableName) == AnsiUpperCase(LogTable->TableName))
  return;
 if (String(Sender->ClassName()) == "TACRTable")
  et = "BY Table";
 else
  et = "BY Query";
 LogTable->Insert();
 LogTable->FieldByName("EventTime")->AsDateTime = Now();
 LogTable->FieldByName("EventType")->AsString = "Insert "+et;
 LogTable->FieldByName("TableName")->AsString = TableName;
 LogTable->FieldByName("NewIDValue")->AsInteger = FieldValues[0]->AsInteger;
 LogTable->FieldByName("NewStrValue")->AsString = FieldValues[1]->AsString;
 LogTable->Post();
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::ACRDatabase1AfterUpdateRecord(TACRDataSet *Sender,
      const AnsiString TableName,
      const TACRArrayOfTACRVariant OldFieldValues,
      const TACRArrayOfTACRVariant NewFieldValues)
{
 AnsiString et;
 if (AnsiUpperCase(TableName) == AnsiUpperCase(LogTable->TableName)) 
   return;
 if (String(Sender->ClassName()) == "TACRTable")
  et = "BY Table";
 else
  et = "BY Query";
 LogTable->Insert();
 LogTable->FieldByName("EventTime")->AsDateTime = Now();
 LogTable->FieldByName("EventType")->AsString = "Update "+et;
 LogTable->FieldByName("TableName")->AsString = TableName;
 LogTable->FieldByName("NewIDValue")->AsInteger = NewFieldValues[0]->AsInteger;
 LogTable->FieldByName("NewStrValue")->AsString = NewFieldValues[1]->AsString;
 LogTable->FieldByName("IDValue")->AsInteger = OldFieldValues[0]->AsInteger;
 LogTable->FieldByName("StrValue")->AsString = OldFieldValues[1]->AsString;
 LogTable->Post();

}
//---------------------------------------------------------------------------

void __fastcall TfmMain::ACRDatabase1AfterDeleteRecord(TACRDataSet *Sender,
      const AnsiString TableName, const TACRArrayOfTACRVariant FieldValues)
{
 AnsiString et;
 if (AnsiUpperCase(TableName) == AnsiUpperCase(LogTable->TableName))
   return;
 if (String(Sender->ClassName()) == "TACRTable")
  et = "BY Table";
 else
  et = "BY Query";
 LogTable->Insert();
 LogTable->FieldByName("EventTime")->AsDateTime = Now();
 LogTable->FieldByName("EventType")->AsString = "Delete "+et;
 LogTable->FieldByName("TableName")->AsString = TableName;
 LogTable->FieldByName("IDValue")->AsInteger = FieldValues[0]->AsInteger;
 LogTable->FieldByName("StrValue")->AsString = FieldValues[1]->AsString;
 LogTable->Post();
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::ACRDatabase1AfterExecuteSQL(TACRQuery *Sender)
{
 LogTable->Insert();
 LogTable->FieldByName("EventTime")->AsDateTime = Now();
 LogTable->FieldByName("EventType")->AsString = "Execute SQL";
 LogTable->FieldByName("SQL")->AsString = Sender->SQL->Text;
 LogTable->Post();

}
//---------------------------------------------------------------------------

