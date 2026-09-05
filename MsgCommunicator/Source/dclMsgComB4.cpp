//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("dclMsgComB4.res");
USEPACKAGE("vcl40.bpi");
USEPACKAGE("vclx40.bpi");
USEPACKAGE("vclMsgComB4.bpi");
USEUNIT("MsgReg.pas");
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
