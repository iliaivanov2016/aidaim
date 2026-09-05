//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("vclMsgComB5.res");
USEUNIT("MsgCommunicator.pas");
USERES("MsgCommunicator.dcr");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("vclx50.bpi");
USEPACKAGE("vcldb50.bpi");
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
