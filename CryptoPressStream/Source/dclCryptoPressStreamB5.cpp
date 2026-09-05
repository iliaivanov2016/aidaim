//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("dclCryptoPressStreamB5.res");
USEPACKAGE("vcl50.bpi");
USEPACKAGE("vclx50.bpi");
USEUNIT("CPSReg.pas");
USEPACKAGE("vclCryptoPressStreamB5.bpi");
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
