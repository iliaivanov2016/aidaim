//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("dclAccuracerb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("ACRReg.pas");
USEPACKAGE("vcldb40.bpi");
USEPACKAGE("vclAccuracerb4.bpi");
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
