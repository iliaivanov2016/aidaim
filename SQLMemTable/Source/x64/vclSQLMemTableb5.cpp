//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("vclSQLMemTableb5.res");
USEPACKAGE("vcl50.bpi");
USEUNIT("SQLMemLocalEngine.pas");
USEUNIT("SQLMemMain.pas");
USERES("SQLMemMain.dcr");
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
