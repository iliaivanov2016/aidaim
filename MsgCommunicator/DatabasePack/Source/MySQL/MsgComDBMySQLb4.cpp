//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBMySQLb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("MsgDatabaseMySQL.pas");
USERES("MsgDatabaseMySQL.dcr");
USEUNIT("MsgDatabaseMySQLReg.pas");
USEPACKAGE("vclMsgComB4.bpi");
USEPACKAGE("vcldb40.bpi");
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
