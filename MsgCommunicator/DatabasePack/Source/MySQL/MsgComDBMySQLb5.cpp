//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBMySQLb5.res");
USEUNIT("MsgDatabaseMySQL.pas");
USERES("MsgDatabaseMySQL.dcr");
USEUNIT("MsgDatabaseMySQLReg.pas");
USEPACKAGE("vclMsgComB5.bpi");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("vcldb50.bpi");
USEPACKAGE("vclbde50.bpi");
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
