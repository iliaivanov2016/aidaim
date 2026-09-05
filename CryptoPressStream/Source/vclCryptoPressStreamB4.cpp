//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("vclCryptoPressStreamB4.res");
USEPACKAGE("vcl40.bpi");
USEPACKAGE("vclx40.bpi");
USEUNIT("CPSMain.pas");
USERES("CPSMain.dcr");
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
