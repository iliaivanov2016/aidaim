//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBMySQLb5.res");
USEUNIT("MsgDatabaseMySQLDAC.pas");
USERES("MsgDatabaseMySQLDAC.dcr");
USEUNIT("MsgDatabaseMySQLDACReg.pas");
USEPACKAGE("vclMsgComB5.bpi");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("vcldb50.bpi");
USEPACKAGE("mySQLDACBCB5.bpi");
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
