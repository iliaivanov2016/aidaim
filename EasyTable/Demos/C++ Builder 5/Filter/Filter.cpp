//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("Filter.res");
USEFORM("Main.cpp", MainForm);
USEFORM("Cust.cpp", CustForm);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
        try
        {
                 Application->Initialize();
                 Application->CreateForm(__classid(TMainForm), &MainForm);
                 Application->CreateForm(__classid(TCustForm), &CustForm);
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
