//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("Server.res");
USEFORM("uMain.cpp", fmMain);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
        try
        {
                 Application->Initialize();
                 Application->Title = "Server with Accuracer: MsgCommunicator Demo. (c) 2004-2008 AidAim Software";
                 Application->CreateForm(__classid(TfmMain), &fmMain);
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
