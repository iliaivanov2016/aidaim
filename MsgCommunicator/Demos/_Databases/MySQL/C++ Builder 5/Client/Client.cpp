//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USERES("Client.res");
USEFORM("uMain.cpp", fmMain);
USEFORM("uStart.cpp", fmStart);
USEFORM("uFind.cpp", fmFind);
USEFORM("uHistory.cpp", fmHistory);
USEFORM("uLogin.cpp", fmLogin);
USEFORM("uRegister.cpp", fmRegister);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
  try
  {
     Application->Initialize();
     Application->Title = "Client with MySQL: MsgCommunicator Demo. (c) 2004-2008 AidAim Software";
     Application->CreateForm(__classid(TfmMain), &fmMain);
     Application->CreateForm(__classid(TfmStart), &fmStart);
     Application->CreateForm(__classid(TfmFind), &fmFind);
     Application->CreateForm(__classid(TfmHistory), &fmHistory);
     Application->CreateForm(__classid(TfmLogin), &fmLogin);
     Application->CreateForm(__classid(TfmRegister), &fmRegister);
     Application->Run();
  }
  catch (Exception &exception)
  {
     Application->ShowException(&exception);
  }
  return 0;
}
//---------------------------------------------------------------------------
