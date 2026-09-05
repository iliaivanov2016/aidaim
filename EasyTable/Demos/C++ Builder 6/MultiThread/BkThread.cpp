//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include <Math.h>
#include "BkThread.h"
#include "uMain.h"
#pragma package(smart_init)

//---------------------------------------------------------------------------
__fastcall TQueryThread::TQueryThread(bool CreateSuspended)
        : TThread(CreateSuspended)
{
}
//---------------------------------------------------------------------------
void __fastcall TQueryThread::UpdateGrid()
{
 fMain->EasyTable1->Refresh();
 fMain->lbRecCount->Caption = IntToStr(fMain->EasyTable1->RecordCount);
}

//---------------------------------------------------------------------------
void __fastcall TQueryThread::Execute()
{
 AnsiString SesName, DBName;
 int i;
 static long UniqueNumber;

  // Ensure the Query has a unique session and database.  A unique session
  // is required for each thread.  Since databases are session specific
  // it must be unique as well
  InterlockedIncrement(&UniqueNumber);

  SesName = "ses"+IntToStr((int)UniqueNumber);
  DBName = "db"+IntToStr((int)UniqueNumber);

  Session = new TEasySession(NULL);
  Session->SessionName = SesName;

  Database = new TEasyDatabase(NULL);
  Database->SessionName = SesName;
  Database->DatabaseName = DBName;
  Database->DatabaseFileName = fMain->EasyDatabase1->DatabaseFileName;

  Query = new TEasyQuery(NULL);
  Query->SessionName = SesName;
  Query->DatabaseName = DBName;

  Query->SQL->Text = "INSERT INTO TEST (Time, Name, Integer, Money) VALUES (:Time, :Name, :Integer, :Money)";
  // 10 inserts
  for (i = 0; i<99; i++)
  {
    Query->ParamByName("Time")->AsTime = Now();
    Query->ParamByName("Name")->AsString = SesName;
    Query->ParamByName("Integer")->AsInteger = random(MaxInt);
    Query->ParamByName("Money")->AsFloat = random(5000);

    Query->ExecSQL();
    Synchronize(UpdateGrid);
    Sleep(10);
  }

  Query->Free();
  Database->Free();
  Session->Free();

}

