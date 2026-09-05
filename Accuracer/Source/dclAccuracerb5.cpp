//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("dclAccuracerb5.res");
USEPACKAGE("vcl50.bpi");
USEUNIT("ACRReg.pas");
USEPACKAGE("vcldb50.bpi");
USEPACKAGE("vclAccuracerb5.bpi");
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
