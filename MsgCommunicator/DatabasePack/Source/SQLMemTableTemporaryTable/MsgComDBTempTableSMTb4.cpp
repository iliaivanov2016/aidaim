//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBTempTableSMTb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("MsgDatabaseTempTableSQLMemTable.pas");
USERES("MsgDatabaseTempTableSQLMemTable.dcr");
USEUNIT("MsgDatabaseTempTableSQLMemTableReg.pas");
USEPACKAGE("vclMsgComB4.bpi");
USEPACKAGE("vcldb40.bpi");
USEPACKAGE("vclSQLMemTableb4.bpi");
//---------------------------------------------------------------------------
#pragma package(smart_init)
//---------------------------------------------------------------------------
//   Package source.
//---------------------------------------------------------------------------
int WINAPI DllEntryPoint(HINSTANCE hinst, unsigned long reason, void*)
{
  return 1;
}
//---------------------------------------------------------------------------
