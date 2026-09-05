//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("Server.res");
USEFORM("uMain.cpp", Form1);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
        try
        {
                 Application->Initialize();
                 Application->Title = "Server: MsgCommunicator Demo. (c) 2004 - 2008 AidAim Software";
		Application->CreateForm(__classid(TForm1), &Form1);
                 Application->Run();
        }
        catch (Exception &exception)
        {
                 Application->ShowException(&exception);
        }
        return 0;
}
//---------------------------------------------------------------------------
