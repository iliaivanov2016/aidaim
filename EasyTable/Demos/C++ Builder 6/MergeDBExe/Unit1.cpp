//---------------------------------------------------------------------------

#include <vcl.h>
#include "EasyTable.hpp"
#include <SysUtils.hpp>
#include <iostream>
#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused
int main(int argc, char* argv[])
{
 if(argc<3)
  {
    std::cout <<"MergeDBExe ExeFile DBFile";
  }
  else
  {
  AnsiString pExeFile=argv[1];
  AnsiString pDBFile=argv[2];
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
  }
  }
  return 0;

}
//---------------------------------------------------------------------------
 