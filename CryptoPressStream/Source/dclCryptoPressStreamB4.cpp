//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("dclCryptoPressStreamB4.res");
USEPACKAGE("vcl40.bpi");
USEPACKAGE("vclx40.bpi");
USEUNIT("CPSReg.pas");
USEPACKAGE("vclCryptoPressStreamB4.bpi");
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
