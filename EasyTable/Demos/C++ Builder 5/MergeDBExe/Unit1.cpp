//---------------------------------------------------------------------------
#include <vcl.h>
#include "EasyTable.hpp"
#include <SysUtils.hpp>
#pragma hdrstop

#include "Unit1.h"
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
  AnsiString pExeFile=ParamStr(1);
  AnsiString pDBFile=ParamStr(2);
  TEasyDatabase* Database = new TEasyDatabase(NULL);
  try
   {
    Database->DatabaseName = "edb";
    Database->DatabaseFileName = pDBFile;
    Database->MakeExeDatabase(pExeFile,pExeFile+"1");
    DeleteFile(pExeFile);
    RenameFile(pExeFile+"1",pExeFile);
   }
  __finally
   {
    delete Database;
    Close();
    Application->Terminate();
   }
}
//---------------------------------------------------------------------------
