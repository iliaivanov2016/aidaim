//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
#include  <Registry.hpp>
#include  <typeinfo.h>
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "CPSMain"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnCompressTableClick(TObject *Sender)
{
    TCPSStream *cs;
    TStream *bsSource, *bsDest;
    int i,k;
    __int64 srcsize,size;
    double ratio;
    AnsiString path;
    TRegistry *reg;
    unsigned int t;
    TFileStream *fs;
    TDBImage *dbi;
    TCPSStreamHeader h;

 tDest->ReadOnly = False;
 reg = new TRegistry();
 try
 {
   reg->RootKey = HKEY_LOCAL_MACHINE;
   reg->OpenKeyReadOnly("Software\\Borland\\Borland Shared\\Data");
   path = reg->ReadString("RootDir")+"\\";
   delete reg;
 }
 catch(...)
 {
   delete reg;
 }
  cs = new TCPSFileStream(path+"biolife.db",fmOpenRead,CPSManager1);
  srcsize = cs->Size;
  delete cs;
  cs = new TCPSFileStream(path+"biolife.mb",fmOpenRead,CPSManager1);
  srcsize = srcsize + cs->Size;
  delete cs;
  cs = new TCPSFileStream(path+"biolife.px",fmOpenRead,CPSManager1);
  srcsize = srcsize + cs->Size;
  delete cs;
 t = GetTickCount();
 try
 {
   tSource->Open();
   tDest->Close();
   if (tDest->Exists)
    tDest->DeleteTable();
   tDest->FieldDefs->Assign(tSource->FieldDefs);
   tDest->IndexDefs->Assign(tSource->IndexDefs);
   for (i = 0; i < tDest->FieldDefs->Count; i++)
    if ((tDest->FieldDefs->Items[i]->DataType == ftMemo) ||
        (tDest->FieldDefs->Items[i]->DataType == ftGraphic))
     tDest->FieldDefs->Items[i]->DataType = ftBlob;
   tDest->CreateTable();
   tDest->Open();
   tSource->First();
   while (! tSource->Eof)
     {
      tDest->Insert();
      for (i = 0; i < tSource->FieldCount; i++)
       if (! tSource->Fields->Fields[i]->IsNull)
        {
         if (typeid(tSource->Fields->Fields[i]) == typeid(TLargeintField))
          ((TLargeintField *)(tDest->Fields->Fields[i]))->AsLargeInt ==
            ((TLargeintField *)(tSource->Fields->Fields[i]))->AsLargeInt;
         else
         if (tSource->Fields->Fields[i]->IsBlob(NULL))
          {
           if (tSource->Fields->Fields[i]->DataType == ftGraphic)
            {
             bsDest = tDest->CreateBlobStream(tDest->Fields->Fields[i],bmReadWrite);
             cs = CPSManager1->CreateCryptoPressStream(bsDest,True,False);
             dbi = new TDBImage(Form1);
             try
             {
               dbi->DataSource = DataSource2;
               dbi->DataField = tSource->Fields->Fields[i]->FieldName;
               dbi->Picture->Bitmap->SaveToStream(cs);
               dbi->DataSource = NULL;
               delete dbi;
               delete cs;
               delete bsDest;
             }
             catch (...)
             {
               delete dbi;
               delete cs;
               delete bsDest;
             }
            }
           else
            {
               bsSource = tSource->CreateBlobStream(tSource->Fields->Fields[i],bmRead);
               try
               {
                 bsDest = tDest->CreateBlobStream(tDest->Fields->Fields[i],bmReadWrite);
                 cs = CPSManager1->CreateCryptoPressStream(bsDest,True,False);
                 cs->LoadFromStream(bsSource);
                 delete bsDest;
                 delete cs;
                 delete bsSource;
              }
              catch (...)
              {
                delete bsDest;
                delete cs;
                delete bsSource;
              }
            }
          }
         else
          tDest->Fields->Fields[i]->Assign(tSource->Fields->Fields[i]);
        }
      tDest->Post();
      tSource->Next();
     }
  tDest->Close();
  tSource->Close();
  t = GetTickCount() - t;
  cs = new TCPSFileStream("biolife.db",fmOpenRead,CPSManager1);
  size = cs->Size;
  delete cs;
  cs = new TCPSFileStream("biolife.mb",fmOpenRead,CPSManager1);
  size = size + cs->Size;
  delete cs;
  cs = new TCPSFileStream("biolife.px",fmOpenRead,CPSManager1);
  size = size + cs->Size;
  delete cs;
 }
 catch (Exception &e)
 {
    ShowMessage("Error: "+e.Message);
    return;
 }
  ratio = (double)((srcsize - size) / (double)srcsize) * 100.0;
  AnsiString s = "";
  s += "Table compressed successfully. ";
  s += "UncompressedSize = ";
  s += IntToStr(srcsize);
  s += " bytes \r\n";
  s += "CompressedSize = ";
  s += IntToStr(size);
  s += " bytes \r\n";
  s += "Time = ";
  s += IntToStr(t);
  s += " ms\r\n";
  s += "Ratio = ";
  s += FormatFloat("0.00",ratio);
  s += " %";
  ShowMessage(s);

}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnBrowseCompressedClick(TObject *Sender)
{
 if (! tDest->Exists)
  {
   ShowMessage("Compressed table does not exists. Click on \"Compress Table\" button at first");
   return ;
  }
 tDest->ReadOnly = True;
 tDest->Open();
 tDest->First();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::tDestAfterScroll(TDataSet *DataSet)
{
    TCPSCryptoPressStream *cs;
    TStream *bs;
    int i;
    BOOL b1,b2;

 if (! tDest->ReadOnly)
  return;
 b1 = False;
 b2 = False;
 for (i = 0; i < tDest->FieldCount; i++)
  {
   if (b1 && b2)
    break;
   else
    if ((tDest->Fields->Fields[i]->FieldName == "Notes") ||
       (tDest->Fields->Fields[i]->FieldName == "Graphic"))
     {
      bs = tDest->CreateBlobStream(tDest->Fields->Fields[i],bmRead);
      cs = CPSManager1->CreateCryptoPressStream(bs,False,True);
      try
      {
        if (tDest->Fields->Fields[i]->FieldName == "Notes")
         {
          RichEdit2->Lines->LoadFromStream(cs);
          b1 = True;
         }
        else
         {
           Image2->Picture->Bitmap->LoadFromStream(cs);
           b2 = True;
         }
       delete cs;
      }
      catch (...)
      {
       // no need in bs->Free as we created stream with FreeBaseStream = true
       delete cs;
      };
     };
  };
        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnExitClick(TObject *Sender)
{
 Close();
 Application->Terminate();        
}
//---------------------------------------------------------------------------
