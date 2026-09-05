//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("SFSPackb5.res");
USEUNIT("SingleFileSystem.pas");
USEUNIT("SFSZlib.pas");
USEUNIT("SFSCipher.pas");
USEUNIT("SFSCompress.pas");
USEUNIT("SFSDECConst.pas");
USEUNIT("SFSDECUtil.pas");
USEUNIT("SFSEngine.pas");
USEUNIT("SFSFileCtrl.pas");
USEUNIT("SFSPassword.pas");
USEUNIT("SFSStrFunc.pas");
USEUNIT("SFSBZip2.pas");
USEPACKAGE("vcl50.bpi");
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
