//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "SQLMemMain"
#pragma resource "*.dfm"
TfmMain *fmMain;
//---------------------------------------------------------------------------
__fastcall TfmMain::TfmMain(TComponent* Owner)
	: TForm(Owner)
{
}
void __fastcall TfmMain::ShowTables(TSQLMemDatabase *db)
{
 TListBox *lb;
 if (db == SQLMemDatabase1)
  lb = lbTables1;
 else
  lb = lbTables2;
 lb->Items->Clear();
 if (db == SQLMemDatabase1)
  {
	SQLMemDatabase1->GetTablesList(lb->Items);
	gbDB1->Caption = " Database #1: "+IntToStr(lbTables1->Items->Count)+" tables ";
  }
 else
  {
	SQLMemDatabase2->GetTablesList(lb->Items);
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
 SQLMemQuery1->SQL->Text = s;
 reSQL->Text = SQLMemQuery1->SQL->Text;
/*
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.ExecSQL();
 SQLMemDatabase1.InMemory := True;
 SQLMemDatabase1.DatabaseName := 'MemDB1';
 SQLMemDatabase1.Open();
 SQLMemDatabase2.InMemory := True;
 SQLMemDatabase2.DatabaseName := 'MemDB2';
 SQLMemDatabase2.Open();
 SQLMemQuery1.DatabaseName := SQLMemDatabase1.DatabaseName;
 SQLMemTable1.DatabaseName := SQLMemDatabase1.DatabaseName;
 SQLMemQuery2.DatabaseName := SQLMemDatabase2.DatabaseName;
 SQLMemTable2.DatabaseName := SQLMemDatabase2.DatabaseName;

*/
 SQLMemQuery1->ExecSQL();

 SQLMemDatabase1->InMemory = True;
 SQLMemDatabase1->DatabaseName = "MemDB1";
 SQLMemDatabase1->Open();
 SQLMemDatabase2->InMemory = True;
 SQLMemDatabase2->DatabaseName = "MemDB2";
 SQLMemDatabase2->Open();
 SQLMemQuery1->DatabaseName = SQLMemDatabase1->DatabaseName;
 SQLMemQuery2->DatabaseName = SQLMemDatabase2->DatabaseName;
 SQLMemTable1->DatabaseName = SQLMemDatabase1->DatabaseName;
 SQLMemTable2->DatabaseName = SQLMemDatabase2->DatabaseName;

 Button1->Enabled = False;
 Button2->Enabled = True;
 Button3->Enabled = True;
 Button4->Enabled = True;
 Button5->Enabled = True;
 Button6->Enabled = True;
 Button7->Enabled = True;
 Button8->Enabled = True;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);
;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button2Click(TObject *Sender)
{
 SQLMemQuery1->SQL->Text = "SELECT * FROM MEMORY MemDB1.Table1 ORDER BY name";
 reSQL->Text = SQLMemQuery1->SQL->Text;
 SQLMemQuery1->Open();
 if (SQLMemTable1->Active)
  SQLMemTable1->Close();
 DS1->DataSet = SQLMemQuery1;

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button3Click(TObject *Sender)
{
 SQLMemQuery2->SQL->Text = "SELECT * FROM MEMORY MemDB2.Table1 ORDER BY name DESC";
 reSQL->Text = SQLMemQuery2->SQL->Text;
 SQLMemQuery2->Open();
 if (SQLMemTable2->Active)
  SQLMemTable2->Close();
 DS2->DataSet = SQLMemQuery2;

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button4Click(TObject *Sender)
{
 AnsiString s =  "SELECT * INTO MEMORY MemDB2.Table3";
			s += "\r\nFROM MEMORY MemDB1.Table1 as t11 INNER JOIN ";
			s += "\r\nMEMORY MemDB2.Table1 as t21 ON (t11.id = t21.id)";
			s += "\r\nORDER BY 2 DESC, 4 DESC";
 SQLMemQuery1->SQL->Text = s;
 reSQL->Text = SQLMemQuery1->SQL->Text;
 SQLMemQuery1->Open();
 if (SQLMemTable1->Active)
  SQLMemTable1->Close();
 DS1->DataSet = SQLMemQuery1;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);

}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button8Click(TObject *Sender)
{
 AnsiString s =  "INSERT INTO MEMORY MemDB2.Table2 ";
			s += "\r\nSELECT * FROM MEMORY MemDB1.Table1 UNION";
			s += "\r\nSELECT * FROM MEMORY MemDB2.Table1;";
			s += "\r\nSELECT * FROM MEMORY MemDB2.Table2";
			s += "\r\nORDER BY 2 DESC";
 SQLMemQuery1->SQL->Text = s;
 reSQL->Text = SQLMemQuery1->SQL->Text;
 SQLMemQuery1->Open();
 if (SQLMemTable1->Active)
  SQLMemTable1->Close();
 DS1->DataSet = SQLMemQuery1;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button5Click(TObject *Sender)
{
 SQLMemQuery1->SQL->Text = "UPDATE MEMORY MemDB1.Table1 SET name = name + '!'";
 SQLMemQuery1->ExecSQL();
 if (SQLMemTable1->Active)
  SQLMemTable1->Close();
 SQLMemTable1->TableName = "Table1";
 SQLMemTable1->Open();
 DS1->DataSet = SQLMemTable1;
 SQLMemTable1->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button6Click(TObject *Sender)
{
 SQLMemQuery1->SQL->Text = "DELETE FROM MEMORY MemDB1.Table1";
 SQLMemQuery1->ExecSQL();
 if (SQLMemTable1->Active)
  SQLMemTable1->Close();
 SQLMemTable1->TableName = "Table1";
 SQLMemTable1->Open();
 DS1->DataSet = SQLMemTable1;
 SQLMemTable1->Refresh();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Button7Click(TObject *Sender)
{
 SQLMemDatabase1->Close();
 SQLMemDatabase2->Close();
 SQLMemQuery1->SQL->Text = "DROP DATABASE MEMORY MemDB1; DROP DATABASE MEMORY MemDB2;";
 reSQL->Text = SQLMemQuery1->SQL->Text;
 SQLMemQuery1->ExecSQL();
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
 SQLMemQuery3->SQL->Text = reSQL->Text;
 if (Pos("SELECT",AnsiUpperCase(SQLMemQuery3->SQL->Text)) > 0)
  SQLMemQuery3->Open();
 else
  SQLMemQuery3->ExecSQL();
 DS1->DataSet = SQLMemQuery3;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnExitClick(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
