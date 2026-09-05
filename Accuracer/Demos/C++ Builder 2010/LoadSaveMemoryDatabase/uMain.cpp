//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma link "ACRMain"
#pragma resource "*.dfm"
TfmMain *fmMain;
//---------------------------------------------------------------------------
__fastcall TfmMain::TfmMain(TComponent* Owner)
	: TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnLoadDBClick(TObject *Sender)
{
  db->LoadDatabaseFromFile(SaveFileName);
  ShowMessage("DB loaded from: \r\n"+SaveFileName);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormCreate(TObject *Sender)
{
/*
 TempDir = IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
 SaveFileName = TempDir+"memory_database.acr";
 db->InMemory = True;
 db->DatabaseName = "MemDBLoadSave";
 db->CreateDatabase();
 db->Open();
 tEmp->DatabaseName = db->DatabaseName;
 tDept->DatabaseName = db->DatabaseName;
 tEmp->TableName = "emp";
 tDept->TableName = "dept";
 tDept->FieldDefs->Clear();
 tDept->AdvFieldDefs->Clear();
 tDept->AdvFieldDefs->Add("ID",aftAutoInc);
 tDept->AdvFieldDefs->Add("Name",aftChar,50);
 tDept->IndexDefs->Clear();
 tDept->IndexDefs->Add("PK","ID,Name",TIndexOptions()<<ixPrimary);
 tDept->ForeignKeyDefs->Clear();
 tDept->CreateTable();
 tDept->Open();

 tEmp->FieldDefs->Clear();
 tEmp->AdvFieldDefs->Clear();
 tEmp->AdvFieldDefs->Add("ID",aftAutoInc);
 tEmp->AdvFieldDefs->Add("Name",aftChar,50);
 tEmp->AdvFieldDefs->Add("Surname",aftChar,50);
 tEmp->AdvFieldDefs->Add("DeptID",aftInteger);
 tEmp->AdvFieldDefs->Add("DeptName",aftChar,50);
 tEmp->AdvFieldDefs->Find("DeptID")->DefaultValue->AsInteger = -1;
 tEmp->AdvFieldDefs->Find("DeptName")->DefaultValue->AsString = "UNKNOWN DEPARTMENT";
 tEmp->IndexDefs->Clear();
 tEmp->IndexDefs->Add("PK","ID",TIndexOptions()<<ixPrimary);
 tEmp->IndexDefs->Add("FK","DeptID,DeptName",TIndexOptions());
 tEmp->ForeignKeyDefs->Clear();
 tEmp->ForeignKeyDefs->Add("FK_DeptID","DeptID,DeptName","dept",
                         fkmtFull,fkaCascade,fkaCascade);
 tEmp->CreateTable();
 tEmp->Open();

 tDept->Insert();
 tDept->FieldByName("Name")->AsString = "Development Department";
 tDept->Post();
 tDept->Insert();
 tDept->FieldByName("Name")->AsString = "Technical Support Team";
 tDept->Post();
 tDept->Insert();
 tDept->FieldByName("Name")->AsString = "Sales Department";
 tDept->Post();
 tDept->Insert();
 tDept->FieldByName("ID")->AsInteger = -1;
 tDept->FieldByName("Name")->AsString = "UNKNOWN DEPARTMENT";
 tDept->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Leo";
 tEmp->FieldByName("Surname")->AsString = "Martin";
 tEmp->FieldByName("DeptID")->AsInteger = 1;
 tEmp->FieldByName("DeptName")->AsString = "Development Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Richard";
 tEmp->FieldByName("Surname")->AsString = "Watson";
 tEmp->FieldByName("DeptID")->AsInteger = 1;
 tEmp->FieldByName("DeptName")->AsString = "Development Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Garry";
 tEmp->FieldByName("Surname")->AsString = "Robinson";
 tEmp->FieldByName("DeptID")->AsInteger = 1;
 tEmp->FieldByName("DeptName")->AsString = "Development Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Alex";
 tEmp->FieldByName("Surname")->AsString = "Lambert";
 tEmp->FieldByName("DeptID")->AsInteger = 1;
 tEmp->FieldByName("DeptName")->AsString = "Development Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Fred";
 tEmp->FieldByName("Surname")->AsString = "Bolt";
 tEmp->FieldByName("DeptID")->AsInteger = 1;
 tEmp->FieldByName("DeptName")->AsString = "Development Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Ray";
 tEmp->FieldByName("Surname")->AsString = "Lahoy";
 tEmp->FieldByName("DeptID")->AsInteger = 2;
 tEmp->FieldByName("DeptName")->AsString = "Technical Support Team";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "Ella";
 tEmp->FieldByName("Surname")->AsString = "Perelman";
 tEmp->FieldByName("DeptID")->AsInteger = 3;
 tEmp->FieldByName("DeptName")->AsString = "Sales Department";
 tEmp->Post();

 tEmp->Insert();
 tEmp->FieldByName("Name")->AsString = "John";
 tEmp->FieldByName("Surname")->AsString = "Smith";
 tEmp->FieldByName("DeptID")->AsInteger = 3;
 tEmp->FieldByName("DeptName")->AsString = "Sales Department";
 tEmp->Post();

 tEmp->IndexName = "FK";
 tEmp->MasterSource = DataSource1;
 tEmp->MasterFields = "ID;Name";
 tDept->First();
 bnSaveDBClick(this);
 */
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnSaveDBClick(TObject *Sender)
{
  db->SaveDatabaseToFile(SaveFileName,"",caZLIB,9,2*1024*1024);
  ShowMessage("DB saved to: \r\n"+SaveFileName);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnCloseClick(TObject *Sender)
{
 db->Close();
 db->DeleteDatabase();
}
//---------------------------------------------------------------------------
