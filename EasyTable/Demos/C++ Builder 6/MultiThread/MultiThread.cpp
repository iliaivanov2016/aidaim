//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("MultiThread.res");
USEFORM("uMain.cpp", fMain);
USEUNIT("BkThread.cpp");
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
        try
        {
                 Application->Initialize();
                 Application->CreateForm(__classid(TfMain), &fMain);
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
