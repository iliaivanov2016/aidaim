//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("mySQLImport.res");
USEFORM("uMain.cpp", Form1);
USEFORM("uConnect.cpp", ConnectDlg);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
        try
        {
                 Application->Initialize();
                 Application->CreateForm(__classid(TForm1), &Form1);
                 Application->CreateForm(__classid(TConnectDlg), &ConnectDlg);
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
