//---------------------------------------------------------------------------

#include <vcl.h>
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
void __fastcall TfmMain::ShowTables(TACRDatabase *db)
{
 TListBox *lb;
 if (db == ACRDatabase1)
  lb = lbTables1;
 else
  lb = lbTables2;
 lb->Items->Clear();
 if (db == ACRDatabase1)
  {
	ACRDatabase1->GetTablesList(lb->Items);
	gbDB1->Caption = " Database #1: "+IntToStr(lbTables1->Items->Count)+" tables ";
  }
 else
  {
	ACRDatabase2->GetTablesList(lb->Items);
	gbDB2->Caption = " Database #2: "+IntToStr(lbTables2->Items->Count)+" tables ";
  }
}

//---------------------------------------------------------------------------
void __fastcall TfmMain::Button1Click(TObject *Sender)
{
 AnsiString s =  "CREATE DATABASE MEMORY MemDB1;\r\n";
			s += "CREATE TABLE MEMORY MemDB1.Table1(id AutoInc, name char(20), PRIMARY KEY(id));\r\n";
			s += "INSERT INTO MEMORY MemDB1.Table1(name) VALUES ('Leo Martin');\r\n";
			s += "INSERT INTO MEMORY MemDB1.Table1(name) VALUES ('Ray Lahoy');\r\n";
			s += "CREATE DATABASE MEMORY MemDB2;\r\n";
			s += "CREATE TABLE MEMORY MemDB2.Table1(id AutoInc, name char(20), PRIMARY KEY(id));\r\n";
			s += "INSERT INTO MEMORY MemDB2.Table1(name) VALUES ('Ella Perelman');\r\n";
			s += "INSERT INTO MEMORY MemDB2.Table1(name) VALUES ('John Smith');\r\n";
			s += "CREATE TABLE MEMORY MemDB2.Table2(id Integer, name char(20), PRIMARY KEY(id,name));\r\n";
 ACRQuery1->SQL->Text = s;
 reSQL->Text = ACRQuery1->SQL->Text;
/*
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.ExecSQL();
 ACRDatabase1.InMemory := True;
 ACRDatabase1.DatabaseName := 'MemDB1';
 ACRDatabase1.Open();
 ACRDatabase2.InMemory := True;
 ACRDatabase2.DatabaseName := 'MemDB2';
 ACRDatabase2.Open();
 ACRQuery1.DatabaseName := ACRDatabase1.DatabaseName;
 ACRTable1.DatabaseName := ACRDatabase1.DatabaseName;
 ACRQuery2.DatabaseName := ACRDatabase2.DatabaseName;
 ACRTable2.DatabaseName := ACRDatabase2.DatabaseName;

*/
 ACRQuery1->ExecSQL();

 ACRDatabase1->InMemory = True;
 ACRDatabase1->DatabaseName = "MemDB1";
 ACRDatabase1->Open();
 ACRDatabase2->InMemory = True;
 ACRDatabase2->DatabaseName = "MemDB2";
 ACRDatabase2->Open();
 ACRQuery1->DatabaseName = ACRDatabase1->DatabaseName;
 ACRQuery2->DatabaseName = ACRDatabase2->DatabaseName;
 ACRTable1->DatabaseName = ACRDatabase1->DatabaseName;
 ACRTable2->DatabaseName = ACRDatabase2->DatabaseName;

 Button1->Enabled = False;
 Button2->Enabled = True;
 Button3->Enabled = True;
 Button4->Enabled = True;
 Button5->Enabled = True;
 Button6->Enabled = True;
 Button7->Enabled = True;
 Button8->Enabled = True;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);
;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button2Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = "SELECT * FROM MEMORY MemDB1.Table1 ORDER BY name";
 reSQL->Text = ACRQuery1->SQL->Text;
 ACRQuery1->Open();
 if (ACRTable1->Active)
  ACRTable1->Close();
 DS1->DataSet = ACRQuery1;

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button3Click(TObject *Sender)
{
 ACRQuery2->SQL->Text = "SELECT * FROM MEMORY MemDB2.Table1 ORDER BY name DESC";
 reSQL->Text = ACRQuery2->SQL->Text;
 ACRQuery2->Open();
 if (ACRTable2->Active)
  ACRTable2->Close();
 DS2->DataSet = ACRQuery2;

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button4Click(TObject *Sender)
{
 AnsiString s =  "SELECT * INTO MEMORY MemDB2.Table3";
			s += "\r\nFROM MEMORY MemDB1.Table1 as t11 INNER JOIN ";
			s += "\r\nMEMORY MemDB2.Table1 as t21 ON (t11.id = t21.id)";
			s += "\r\nORDER BY 2 DESC, 4 DESC";
 ACRQuery1->SQL->Text = s;
 reSQL->Text = ACRQuery1->SQL->Text;
 ACRQuery1->Open();
 if (ACRTable1->Active)
  ACRTable1->Close();
 DS1->DataSet = ACRQuery1;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button8Click(TObject *Sender)
{
 AnsiString s =  "INSERT INTO MEMORY MemDB2.Table2 ";
			s += "\r\nSELECT * FROM MEMORY MemDB1.Table1 UNION";
			s += "\r\nSELECT * FROM MEMORY MemDB2.Table1;";
			s += "\r\nSELECT * FROM MEMORY MemDB2.Table2";
			s += "\r\nORDER BY 2 DESC";
 ACRQuery1->SQL->Text = s;
 reSQL->Text = ACRQuery1->SQL->Text;
 ACRQuery1->Open();
 if (ACRTable1->Active)
  ACRTable1->Close();
 DS1->DataSet = ACRQuery1;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button5Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = "UPDATE MEMORY MemDB1.Table1 SET name = name + '!'";
 ACRQuery1->ExecSQL();
 if (ACRTable1->Active)
  ACRTable1->Close();
 ACRTable1->TableName = "Table1";
 ACRTable1->Open();
 DS1->DataSet = ACRTable1;
 ACRTable1->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button6Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = "DELETE FROM MEMORY MemDB1.Table1";
 ACRQuery1->ExecSQL();
 if (ACRTable1->Active)
  ACRTable1->Close();
 ACRTable1->TableName = "Table1";
 ACRTable1->Open();
 DS1->DataSet = ACRTable1;
 ACRTable1->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button7Click(TObject *Sender)
{
 ACRDatabase1->Close();
 ACRDatabase2->Close();
 ACRQuery1->SQL->Text = "DROP DATABASE MEMORY MemDB1; DROP DATABASE MEMORY MemDB2;";
 reSQL->Text = ACRQuery1->SQL->Text;
 ACRQuery1->ExecSQL();
 Button1->Enabled = True;
 Button2->Enabled = False;
 Button3->Enabled = False;
 Button4->Enabled = False;
 Button5->Enabled = False;
 Button6->Enabled = False;
 Button7->Enabled = False;
 Button8->Enabled = False;
 lbTables1->Items->Clear();
 lbTables2->Items->Clear();
 gbDB1->Caption = " Database #1: ";
 gbDB2->Caption = " Database #2: ";
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnRunSQLClick(TObject *Sender)
{
 ACRQuery3->SQL->Text = reSQL->Text;
 if (Pos("SELECT",AnsiUpperCase(ACRQuery3->SQL->Text)) > 0)
  ACRQuery3->Open();
 else
  ACRQuery3->ExecSQL();
 DS1->DataSet = ACRQuery3;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnExitClick(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
