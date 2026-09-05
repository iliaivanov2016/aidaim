//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Client.h"
#include "Main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TCustForm *CustForm;
//---------------------------------------------------------------------------
__fastcall TCustForm::TCustForm(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::Button1Click(TObject *Sender)
{
 MainForm->ACRTable1->Post();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::Button2Click(TObject *Sender)
{
 MainForm->ACRTable1->Cancel();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::FormClose(TObject *Sender, TCloseAction &Action)
{
 if ((MainForm->ACRTable1->State == dsInsert) ||
     (MainForm->ACRTable1->State == dsEdit))
   MainForm->ACRTable1->Cancel();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::FormActivate(TObject *Sender)
{
 ActiveControl = CompanyDBEd;
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::btLoadPicClick(TObject *Sender)
{
TFileStream *FS;
TStream *BS;
 if (OpenPictureDialog1->Execute())
  try
  {
   Image->DataField = "";
   FS = new TFileStream(OpenPictureDialog1->FileName,fmOpenRead);
   BS = MainForm->ACRTable1->CreateBlobStream(MainForm->ACRTable1->FieldByName("Photo"),bmReadWrite);
   BS->CopyFrom(FS,FS->Size);
   BS->Free();
   FS->Free();
   Image->DataField = "Photo";
  }
  catch(...)
  {
   MessageDlg("Cannot open file """+OpenDialog1->FileName+"""",mtError,TMsgDlgButtons()<<mbOK,0);
  }
}
//---------------------------------------------------------------------------

void __fastcall TCustForm::btLoadFileClick(TObject *Sender)
{
TFileStream *FS;
TStream *BS;
 if (OpenDialog1->Execute())
  try
  {
   FS = new TFileStream(OpenDialog1->FileName,fmOpenRead);
   BS = MainForm->ACRTable1->CreateBlobStream(MainForm->ACRTable1->FieldByName("File"),bmWrite);
   BS->CopyFrom(FS,FS->Size);
   BS->Free();
   FS->Free();
  }
  catch(...)
  {
   MessageDlg("Cannot open file """+OpenDialog1->FileName+"""",mtError,TMsgDlgButtons()<<mbOK,0);
  }
}

//---------------------------------------------------------------------------

void __fastcall TCustForm::btSaveFileClick(TObject *Sender)
{
TFileStream *FS;
TStream *BS;
 try
 {
  if (SaveDialog1->Execute())
   {
    FS = new TFileStream(SaveDialog1->FileName,fmCreate);
    BS = MainForm->ACRTable1->CreateBlobStream(MainForm->ACRTable1->FieldByName("File"),bmRead);
    FS->CopyFrom(BS,BS->Size);
    BS->Free();
    FS->Free();
   }
 }
 catch(...)
 {
   MessageDlg("Cannot save to file """+SaveDialog1->FileName+"""",mtError,TMsgDlgButtons()<<mbOK,0);
 }
}

//---------------------------------------------------------------------------

