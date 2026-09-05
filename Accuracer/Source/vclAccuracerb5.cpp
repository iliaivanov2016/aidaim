//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("vclAccuracerb5.res");
USEPACKAGE("vcl50.bpi");
USEUNIT("ACRLocalEngine.pas");
USEUNIT("ACRMain.pas");
USERES("ACRMain.dcr");
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
