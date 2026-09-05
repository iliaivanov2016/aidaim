//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBACRb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("MsgDatabaseAccuracer.pas");
USERES("MsgDatabaseAccuracer.dcr");
USEUNIT("MsgDatabaseAccuracerReg.pas");
USEPACKAGE("vclAccuracerb4.bpi");
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
