//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MsgComDBACRb5.res");
USEUNIT("MsgDatabaseAccuracer.pas");
USERES("MsgDatabaseAccuracer.dcr");
USEUNIT("MsgDatabaseAccuracerReg.pas");
USEPACKAGE("vclAccuracerb5.bpi");
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
