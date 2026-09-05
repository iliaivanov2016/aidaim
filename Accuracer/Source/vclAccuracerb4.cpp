//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("vclAccuracerb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("ACRLocalEngine.pas");
USEUNIT("ACRMain.pas");
USERES("ACRMain.dcr");
USEPACKAGE("vclx40.bpi");
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
