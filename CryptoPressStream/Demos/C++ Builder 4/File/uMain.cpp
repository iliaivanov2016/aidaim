//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
#include "CPSMain.hpp"
#include "CPSConst.hpp"
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
void __fastcall TForm1::FormCreate(TObject *Sender)
{
 int i;

 edFileName->Text = Application->ExeName;
 OpenDialog1->FileName = Application->ExeName;

 cbCompression->Items->Clear();
 for (i = 0; i < (sizeof(CPSCompressionModeNames) >> 2); i++)
  cbCompression->Items->Add(CPSCompressionModeNames[i]);
 cbCompression->ItemIndex = 5;

 cbCrypto->Items->Clear();
 for (i = 0; i < (sizeof(CPSCryptoModeNames) >> 2); i++)
  cbCrypto->Items->Add(CPSCryptoModeNames[i]);
 cbCrypto->ItemIndex = 0;

 rgCompression->Items->Clear();
 for (i = 0; i < (sizeof(CPSCompressionAlgorithmNames) >> 2);i++)
  rgCompression->Items->Add(CPSCompressionAlgorithmNames[i]);
 rgCompression->ItemIndex = 1;

 rgCrypto->Items->Clear();
 for (i = 0; i < (sizeof(CPSCryptoAlgorithmNames) >> 2); i++)
  rgCrypto->Items->Add(CPSCryptoAlgorithmNames[i]);
 rgCrypto->ItemIndex = 2;

}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnCompressClick(TObject *Sender)
{
 unsigned t;
 double   d;
 __int64   compSize,Size;
 TFileStream *fs;
 AnsiString  newName;

 FAbort = false;
 CPSManager1->CompressionAlgorithm = TCPSCompressionAlgorithm(rgCompression->ItemIndex);
 CPSManager1->CompressionMode = cbCompression->ItemIndex+1;
 CPSManager1->CryptoParams->CryptoAlgorithm = TCPSCryptoAlgorithm(rgCrypto->ItemIndex);
 CPSManager1->CryptoParams->CryptoMode = TCPSCryptoMode(cbCrypto->ItemIndex);
 CPSManager1->CryptoParams->Password = edPassword->Text;
 t = GetTickCount();
 fs = new TFileStream(edFileName->Text,fmOpenRead + fmShareDenyNone);
 try
 {
   Size = fs->Size;
 }
 __finally
 {
   delete fs;
 }
 newName = ChangeFileExt(edFileName->Text,".cps");
 CPSManager1->CompressFile(edFileName->Text,newName);
 edCompTime->Text = IntToStr(GetTickCount()-t);
 fs = new TFileStream(newName,fmOpenRead + fmShareDenyNone);
 try
 {
   compSize = fs->Size;
 }
 __finally
 {
   delete fs;
 }
 edSize->Text = IntToStr(Size);
 edCompSize->Text = IntToStr(compSize);
 d = (double)(Size - compSize) / (double)Size * 100.0;
 edCompRate->Text = FormatFloat("0.00",d)+" %";
 bnDecompress->Enabled = True;
  
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnDecompressClick(TObject *Sender)
{
 unsigned t;
 AnsiString newName;

 FAbort = false;
 CPSManager1->CryptoParams->Password = edPassword->Text;
 newName = ChangeFileExt(edFileName->Text,".src");
 t = GetTickCount();
 CPSManager1->DecompressFile(ChangeFileExt(edFileName->Text,".cps"),newName);
 edDecompTime->Text = IntToStr(GetTickCount()-t);
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnAbortClick(TObject *Sender)
{
 FAbort = True;
 Application->ProcessMessages();

}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button3Click(TObject *Sender)
{
 Close();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::rgCompressionClick(TObject *Sender)
{
 if (rgCompression->ItemIndex == 0)
   cbCompression->Enabled = false;
 else
   cbCompression->Enabled = true;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::rgCryptoClick(TObject *Sender)
{
 if (rgCrypto->ItemIndex == 0)
  {
   cbCrypto->Enabled = false;
   edPassword->Enabled = false;
  }
 else
  {
   cbCrypto->Enabled = true;
   edPassword->Enabled = true;
  }
}
//---------------------------------------------------------------------------
void __fastcall TForm1::CPSManager1Progress(TObject *Sender,
      double Progress, TCPSOperation Operation, bool &Abort)
{
 ProgressBar1->Position = (int)(Progress+0.5);
 Abort = FAbort;
}
//---------------------------------------------------------------------------
void __fastcall TForm1::bnBrowseClick(TObject *Sender)
{
 if (OpenDialog1->Execute())
   edFileName->Text = OpenDialog1->FileName;
}
//---------------------------------------------------------------------------
