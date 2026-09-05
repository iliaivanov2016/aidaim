//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("dclSQLMemTableb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("SQLMemReg.pas");
USEPACKAGE("vcldb40.bpi");
USEPACKAGE("vclSQLMemTableb4.bpi");
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
