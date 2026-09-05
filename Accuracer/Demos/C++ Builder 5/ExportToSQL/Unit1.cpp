//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
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
void __fastcall TForm1::Button2Click(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button3Click(TObject *Sender)
{
 ACRQuery1->SQL->Text = Memo1->Text;
 ACRQuery1->ExecSQL();
 ShowMessage("Script executed successfully, rows affected = "+IntToStr(ACRQuery1->RowsAffected));
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
 AnsiString s;
 TFileStream* fs;
 int i;

 s = "";
 if (lbTables->SelCount > 0)
  for (i = 0; i < lbTables->Items->Count; i++)
   if (lbTables->Selected[i])
    {
     ACRTable1->TableName = lbTables->Items->Strings[i];
     s = s + ACRTable1->ExportTableToSQL(
      cbExportStructure->Checked,
      cbAddDROPTable->Checked,
      cbExportIndexes->Checked,
      cbAddDROPIndex->Checked,
      cbExportData->Checked,
      cbExportBLOBFields->Checked,
      cbUseBrackets->Checked);
    };
 Memo1->Text = s;
 fs = new TFileStream("test.sql",fmCreate);
 fs->WriteBuffer(&s[1],s.Length());
 delete fs;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button4Click(TObject *Sender)
{
 AnsiString s;
 TFileStream* fs;

 s = ACRDatabase1->ExportDatabaseToSQL(
      cbExportStructure->Checked,
      cbAddDROPTable->Checked,
      cbExportIndexes->Checked,
      cbAddDROPIndex->Checked,
      cbExportData->Checked,
      cbExportBLOBFields->Checked,
      cbUseBrackets->Checked);
 Memo1->Text = s;
 fs = new TFileStream("test.sql",fmCreate);
 fs->WriteBuffer(&s[1],s.Length());
 delete fs;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 ACRDatabase1->Open();
 ACRDatabase1->GetTablesList(lbTables->Items);
 if (! ACRDatabase2->Exists)
  ACRDatabase2->CreateDatabase();
 ACRDatabase2->Open();
}
//---------------------------------------------------------------------------
