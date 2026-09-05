//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("vclSQLMemTableb4.res");
USEPACKAGE("vcl40.bpi");
USEUNIT("SQLMemLocalEngine.pas");
USEUNIT("SQLMemMain.pas");
USERES("SQLMemMain.dcr");
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
