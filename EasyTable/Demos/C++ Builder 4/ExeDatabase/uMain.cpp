//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma resource "*.dfm"
TForm1 *Form1;

// path to default database
const AnsiString DefaultDBFile =  "..\\..\\Data\\DBFishes.edb";

//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
  : TForm(Owner)
{
}

//---------------------------------------------------------------------------
void __fastcall TForm1::OpenDatabase(bool bOpenAsExe = true)
{
  char str = '\'';
  EasyDatabase1->Close();
 // try to open application file as database file in read only mode
 if (bOpenAsExe)
  {
   EasyDatabase1->DatabaseFileName = Application->ExeName;
   if (EasyDatabase1->IsEasyTableDatabaseFile(EasyDatabase1->DatabaseFileName))
    try
    {
     EasyDatabase1->Open();
     eDBPath->Text = Application->ExeName;
    }
   catch (...)
   {
     MessageDlg("Error opening database file "+
      AnsiQuotedStr(eDBPath->Text,str),mtError,TMsgDlgButtons()<<mbOK,0);
     return;
   }
  }
 else
  {
   // try to open external database file
   // set read only to false
   EasyDatabase1->ReadOnly = False;
   EasyTable1->ReadOnly = False;
   EasyDatabase1->DatabaseFileName = eDBPath->Text;
   if (EasyDatabase1->IsEasyTableDatabaseFile(EasyDatabase1->DatabaseFileName))
    {
     try
     {
      EasyDatabase1->Open();
     }
     catch (...)
     {
       MessageDlg("Error opening database file "+
        AnsiQuotedStr(eDBPath->Text,'\''),mtError,TMsgDlgButtons()<<mbOK,0);
       return;
     }
    }
   else
    {
     MessageDlg("Database file "+
        AnsiQuotedStr(eDBPath->Text,'\'')+ " does ! exists!",mtError,TMsgDlgButtons()<<mbOK,0);
     return;
    }
  }
 // open table
 if (EasyDatabase1->Connected) 
  EasyTable1->Open();
}

//---------------------------------------------------------------------------
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 OpenDialog1->InitialDir = DefaultDBFile;
 SaveDialog1->InitialDir = ExtractFilePath(Application->ExeName);
 SaveDialog2->InitialDir = SaveDialog1->InitialDir;
 eDBPath->Text = DefaultDBFile;
 // try to open as executable file
 OpenDatabase(true);
 // if ! successful try to open as external database file
 if (! EasyDatabase1->Connected)
  OpenDatabase(false);
}
//---------------------------------------------------------------------------

void __fastcall TForm1::bnMakeEXEClick(TObject *Sender)
{
 if (SaveDialog1->Execute())
  {
   try
   {
    EasyDatabase1->DatabaseFileName = eDBPath->Text;
    // create executable database file from database file and stub file
    EasyDatabase1->MakeExeDatabase(Application->ExeName,SaveDialog1->FileName);
    MessageDlg("Executable database file created successfully. \r\n Database FileName = "+
      AnsiQuotedStr(eDBPath->Text,'\'') +
      ", executable database FileName = "+
      AnsiQuotedStr(SaveDialog1->FileName,'\''),mtInformation,TMsgDlgButtons()<<mbOK,0);
   }
   catch (...)
   {
    MessageDlg("Error creating executable database file. \r\n Database FileName = "+
      AnsiQuotedStr(eDBPath->Text,'\'') +
      ", executable database FileName = "+
      AnsiQuotedStr(SaveDialog1->FileName,'\''),mtError,TMsgDlgButtons()<<mbOK,0);
   }
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnOpenDBClick(TObject *Sender)
{
 OpenDatabase(False);
 EasyTable1->Open();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnCloseDBClick(TObject *Sender)
{
 EasyDatabase1->Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnExitClick(TObject *Sender)
{
 Close();
 Application->Terminate();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button5Click(TObject *Sender)
{
 OpenDialog1->InitialDir = ExtractFilePath(eDBPath->Text);
 if (OpenDialog1->Execute())
  {
   eDBPath->Text = OpenDialog1->FileName;
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnExtractClick(TObject *Sender)
{
 if (SaveDialog2->Execute()) 
  {
   try
   {
    EasyDatabase1->CopyDatabase(SaveDialog2->FileName);
    if (EasyDatabase1->Connected)
     EasyTable1->Open();
    MessageDlg("Database file "+
      AnsiQuotedStr(EasyDatabase1->DatabaseFileName,'\'')+
      " have been extracted to file  \r\n " +
      AnsiQuotedStr(SaveDialog2->FileName,'\''),mtInformation,TMsgDlgButtons()<<mbOK,0);
   }
   catch (...)
   {
    MessageDlg("Error extracting database file "+
      AnsiQuotedStr(EasyDatabase1->DatabaseFileName,'\'')+" to file \r\n"+
      AnsiQuotedStr(SaveDialog2->FileName,'\''),mtError,TMsgDlgButtons()<<mbOK,0);
   }
  }
}
//---------------------------------------------------------------------------
