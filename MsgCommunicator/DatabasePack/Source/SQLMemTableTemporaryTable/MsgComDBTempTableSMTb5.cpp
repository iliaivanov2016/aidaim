//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USEUNIT("MsgDatabaseTempTableSQLMemTable.pas");
USERES("MsgDatabaseTempTableSQLMemTable.dcr");
USEUNIT("MsgDatabaseTempTableSQLMemTableReg.pas");
USEPACKAGE("vclMsgComB5.bpi");
USEPACKAGE("vclSQLMemTableb5.bpi");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("vcldb50.bpi");
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
