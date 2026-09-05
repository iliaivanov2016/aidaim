//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("vclMsgComB4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("MsgCommunicator.pas");
USERES("MsgCommunicator.dcr");
USEPACKAGE("vclx40.bpi");
USEPACKAGE("vcldb40.bpi");
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
