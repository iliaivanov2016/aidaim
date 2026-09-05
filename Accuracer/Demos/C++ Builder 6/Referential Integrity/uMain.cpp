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

void __fastcall TForm1::tDeptAfterPost(TDataSet *DataSet)
{
 tEmp->Refresh();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::tDeptAfterDelete(TDataSet *DataSet)
{
 tEmp->Refresh();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button1Click(TObject *Sender)
{
 Close();  
}
//---------------------------------------------------------------------------

void __fastcall TForm1::bnExecClick(TObject *Sender)
{
 tDept->Close();
 tEmp->Close();
 ACRQuery1->SQL->Text = reSQL->Text;
 ACRQuery1->ExecSQL();
 tDept->Open();
 tEmp->Open();
 dbgDept->Columns->Items[0]->Width = 55;
 dbgDept->Columns->Items[1]->Width = 160;

 dbgEmp->Columns->Items[0]->Width = 55;
 dbgEmp->Columns->Items[1]->Width = 90;
 dbgEmp->Columns->Items[2]->Width = 90;
 dbgEmp->Columns->Items[3]->Width = 55;
 dbgEmp->Columns->Items[4]->Width = 150;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
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
 tEmp->ForeignKeyDefs->Clear();
 tEmp->ForeignKeyDefs->Add("FK_DeptID","DeptID,DeptName","Dept",
                         fkmtFull,fkaCascade,fkaCascade);
 tEmp->CreateTable();
 tEmp->Open();

 dbgDept->Columns->Items[0]->Width = 55;
 dbgDept->Columns->Items[1]->Width = 160;

 dbgEmp->Columns->Items[0]->Width = 55;
 dbgEmp->Columns->Items[1]->Width = 90;
 dbgEmp->Columns->Items[2]->Width = 90;
 dbgEmp->Columns->Items[3]->Width = 55;
 dbgEmp->Columns->Items[4]->Width = 150;

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


 tEmp->First();
 tDept->First();

 reSQL->Lines->Add("-- Dept table");
 reSQL->Lines->Add(tDept->ExportTableToSQL(True,True,True,False,True,False,False));

 reSQL->Lines->Add("-- Emp table");
 reSQL->Lines->Add(tEmp->ExportTableToSQL(True,True,True,False,True,False,False));

}
//---------------------------------------------------------------------------
