//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uBkThread.h"
#include "uMain.h"

void __fastcall TRestructureThread::Finish()
{
  Form1->Finish();
}

void __fastcall TRestructureThread::Finalize()
{
  TThreadMethod tm = &Finish;
  Synchronize(tm);
}

__fastcall TRestructureThread::TRestructureThread(WideString aDBFile, WideString aTableName, bool CreateSuspended)
: TThread(CreateSuspended)
{
 FTableName = aTableName;
 FDBFileName = aDBFile;
}

void __fastcall TRestructureThread::Execute()
{
  TACRDatabase *db;
  TACRTable *t;
  int i;
  db = new TACRDatabase(NULL);
  t = new TACRTable(NULL);
  try
  {
    db->DatabaseFileName = FDBFileName;
    db->Open();
    t->TableName = FTableName;
    t->DatabaseName = db->DatabaseName;
    t->Open();
    t->Close();
    i = t->RestructureFieldDefs->Count;
    t->RestructureFieldDefs->Add("Field #"+IntToStr(i),aftChar,20);
    t->RestructureTable();
  }
  __finally
  {
    delete t;
    delete db;
    Finalize();
  };
}


//---------------------------------------------------------------------------

#pragma package(smart_init)
