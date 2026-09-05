//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("dclMsgComB5.res");
USEPACKAGE("vcl50.bpi");
USEUNIT("MsgReg.pas");
USEPACKAGE("vcldb50.bpi");
USEPACKAGE("vclMsgComB5.bpi");
//---------------------------------------------------------------------------
#pragma package(smart_init)
//---------------------------------------------------------------------------

//   Package source.
//---------------------------------------------------------------------------

#pragma argsused
int WINAPI DllEntryPoint(HINSTANCE hinst, unsigned long reason, void*)
{
        return 1;
}
//---------------------------------------------------------------------------
