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
void __fastcall TForm1::bnChooseSourceDBClick(TObject *Sender)
{
 int x;
 OpenDialog1->FileName = edtSourceDBFileName->Text;
 if (OpenDialog1->Execute())
  {
   edtSourceDBFileName->Text = OpenDialog1->FileName;
   dbSource->Close();
   dbSource->DatabaseFileName = edtSourceDBFileName->Text;
   dbSource->Open();
   x = cmbxSourceTable->ItemIndex;
   dbSource->GetTablesList(cmbxSourceTable->Items);
   cmbxSourceTable->ItemIndex = x;
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnChooseDestDBClick(TObject *Sender)
{
 int x;
 OpenDialog1->FileName = edtDestDBFileName->Text;
 if (OpenDialog1->Execute())
  {
   edtDestDBFileName->Text = OpenDialog1->FileName;
   dbDest->Close();
   dbDest->DatabaseFileName = edtDestDBFileName->Text;
   dbDest->Open();
   x = cmbxDestTable->ItemIndex;
   dbDest->GetTablesList(cmbxDestTable->Items);
   cmbxDestTable->ItemIndex = x;
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxSourceTableChange(TObject *Sender)
{
  if (cmbxSourceTable->ItemIndex != -1)
  {
     tblSource->TableName = cmbxSourceTable->Items->Strings[cmbxSourceTable->ItemIndex];
     tblSource->GetIndexNames(cmbxSourceIndex->Items);
  }
  else
  {
    tblSource->TableName = "";
    cmbxSourceIndex->Items->Clear();
  };
}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxDestTableChange(TObject *Sender)
{
  if (cmbxDestTable->ItemIndex != -1)
  {
     tblDest->TableName = cmbxDestTable->Items->Strings[cmbxDestTable->ItemIndex];
     tblDest->GetIndexNames(cmbxDestIndex->Items);
  }
  else
  {
    tblDest->TableName = "";
    cmbxDestIndex->Items->Clear();
  };
}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxSourceIndexChange(TObject *Sender)
{
  if (cmbxSourceIndex->ItemIndex != -1)
   tblSource->IndexName = cmbxSourceIndex->Items->Strings[cmbxSourceIndex->ItemIndex];
  else
   tblSource->IndexName = "";
}
//---------------------------------------------------------------------------

void __fastcall TForm1::cmbxDestIndexChange(TObject *Sender)
{
  if (cmbxDestIndex->ItemIndex != -1)
   tblDest->IndexName = cmbxDestIndex->Items->Strings[cmbxDestIndex->ItemIndex];
  else
   tblDest->IndexName = "";
}
//---------------------------------------------------------------------------

void __fastcall TForm1::chkbxAbortKeyClick(TObject *Sender)
{
  BatchMove1->AbortOnKeyViol = chkbxAbortKey->Checked;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::chkbxAbortProblemClick(TObject *Sender)
{
  BatchMove1->AbortOnProblem = chkbxAbortProblem->Checked;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::chkbxTransClick(TObject *Sender)
{
  BatchMove1->UseTransactions = chkbxTrans->Checked;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::FormCreate(TObject *Sender)
{
  OpenDialog1->InitialDir = ExtractFilePath(Application->ExeName);
}
//---------------------------------------------------------------------------

bool IsStringsEqual(AnsiString s1,AnsiString s2)
{
 return (UpperCase(s1) == UpperCase(s2));
};

void __fastcall TForm1::cmbxModeChange(TObject *Sender)
{
  if (cmbxMode->ItemIndex != -1)
  {
    if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Append"))
      BatchMove1->Mode = batAppend;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Copy"))
      BatchMove1->Mode = batCopy;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Append Update"))
      BatchMove1->Mode = batAppendUpdate;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Delete"))
      BatchMove1->Mode = batDelete;
    else if (IsStringsEqual(cmbxMode->Items->Strings[cmbxMode->ItemIndex],"Update"))
      BatchMove1->Mode = batUpdate;
    else
      MessageDlg("Batch mode not found",mtError,TMsgDlgButtons()<<mbOK,0);
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button1Click(TObject *Sender)
{
 AnsiString s;

  if (tblDest->TableName == "")
    tblDest->TableName = cmbxDestTable->Text;
  if ((dbSource->DatabaseFileName != "") && // test for enough input
     (tblSource->TableName != "") &&
     (dbDest->DatabaseFileName != "") &&
     (tblDest->TableName != "") &&
     (cmbxMode->Items->Strings[cmbxMode->ItemIndex] != ""))
  {
    BatchMove1->ChangedTableName = edtChangedTable->Text;  // more batchmove setup
    BatchMove1->KeyViolTableName = edtKeyVioTbl->Text;
    BatchMove1->ProblemTableName = edtProbTbl->Text;
    BatchMove1->RecordCount = StrToInt(edtRecCount->Text);
    BatchMove1->CommitCount = StrToInt(edtCommitCount->Text);
    BatchMove1->Source = tblSource;
    BatchMove1->Destination = tblDest;
  }
 else
  {
    MessageDlg("Incomplete input->",mtError,TMsgDlgButtons()<<mbOK,0);
    return;
  };
  BatchMove1->Execute();  // run the batchmove
  s = "BatchMove complete. Number of records applied: "+IntToStr(BatchMove1->MovedCount)+
       "\r\n" + "Problem record count: "+ IntToStr(BatchMove1->ProblemCount) +
       "\r\n" + "Changed record count: "+ IntToStr(BatchMove1->ChangedCount) +
       "\r\n" + "Key violation count: "+ IntToStr(BatchMove1->KeyViolCount);
  MessageDlg(s,mtInformation,TMsgDlgButtons()<<mbOK,0);
}
//---------------------------------------------------------------------------

