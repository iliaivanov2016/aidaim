//---------------------------------------------------------------------------
#include <vcl.h>
#include <jpeg.hpp>
#pragma hdrstop

#include "MainUnit.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "EasyTable"
#pragma resource "*.dfm"
TMainForm *MainForm;
//---------------------------------------------------------------------------
__fastcall TMainForm::TMainForm(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::FormCreate(TObject *Sender)
{
 EasyTable1->Open();
}
//---------------------------------------------------------------------------


void __fastcall TMainForm::bnLoadClick(TObject *Sender)
{
 TJPEGImage *jpg;
 TStream *bs;

 if (OpenDialog1->Execute())
 {
	 jpg = new TJPEGImage();
   try
   {
		 jpg->LoadFromFile(OpenDialog1->FileName);
   }
   catch(...)
   {
     MessageDlg("Invalid JPEG file.",mtError,TMsgDlgButtons()<<mbOK,0);
		 delete jpg;
     return;
   }
   EasyTable1->Edit();
   bs = EasyTable1->CreateBlobStream(EasyTable1->FieldByName("Image"),bmWrite);
   jpg->SaveToStream(bs);
   EasyTable1->Post();
   delete bs;
   delete jpg;
 }
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::Button1Click(TObject *Sender)
{
 TJPEGImage *jpg;
 TStream *bs;

 if (SaveDialog1->Execute())
 {
	 jpg = new TJPEGImage();
   try
   {
    bs = EasyTable1->CreateBlobStream(EasyTable1->FieldByName("Image"),bmRead);
    if (bs->Size > 0)
     {
      jpg->LoadFromStream(bs);
   	  jpg->SaveToFile(SaveDialog1->FileName);
     }
    delete bs;
   }
   catch(...)
   {
    MessageDlg("Error saving JPEG file.",mtError,TMsgDlgButtons()<<mbOK,0);
		delete jpg;
    return;
   }
   delete jpg;
 }
}
//---------------------------------------------------------------------------
void __fastcall TMainForm::EasyTable1AfterScroll(TDataSet *DataSet)
{
 TJPEGImage *jpg;
 TStream *bs;

 jpg = new TJPEGImage();
 try
 {
  bs = EasyTable1->CreateBlobStream(EasyTable1->FieldByName("Image"),bmRead);
  Image1->Picture->Assign(NULL);
  if (bs->Size > 0)
   {
	  jpg->LoadFromStream(bs);
    Image1->Picture->Assign(jpg);
   }
  delete bs;
 }
 catch(...)
 {
  MessageDlg("Invalid BLOB field value. This is not an jpeg file!",mtError,
    TMsgDlgButtons()<<mbOK,0);
  delete jpg;
  return;
 }
 delete jpg;
}
//---------------------------------------------------------------------------
