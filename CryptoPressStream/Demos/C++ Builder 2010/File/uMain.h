//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
#pragma option -w-      // All warnings off
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "CPSMain.hpp"
#include <Buttons.hpp>
#include <ComCtrls.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
  TLabel *Label1;
  TLabel *Label2;
  TLabel *Label3;
  TLabel *Label4;
  TLabel *Label5;
  TLabel *Label6;
  TLabel *Label7;
  TLabel *Label8;
  TButton *bnCompress;
  TEdit *edCompRate;
  TEdit *edCompTime;
  TEdit *edDecompTime;
  TButton *bnDecompress;
  TButton *Button3;
  TRadioGroup *rgCompression;
  TComboBox *cbCompression;
  TEdit *edSize;
  TEdit *edPassword;
  TRadioGroup *rgCrypto;
  TEdit *edCompSize;
  TComboBox *cbCrypto;
  TBitBtn *bnAbort;
  TEdit *edFileName;
  TButton *bnBrowse;
  TCPSManager *CPSManager1;
  TOpenDialog *OpenDialog1;
  TProgressBar *ProgressBar1;
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall bnCompressClick(TObject *Sender);
  void __fastcall bnDecompressClick(TObject *Sender);
  void __fastcall bnAbortClick(TObject *Sender);
  void __fastcall Button3Click(TObject *Sender);
  void __fastcall rgCompressionClick(TObject *Sender);
  void __fastcall rgCryptoClick(TObject *Sender);
  void __fastcall CPSManager1Progress(TObject *Sender, double Progress,
          TCPSOperation Operation, bool &Abort);
  void __fastcall bnBrowseClick(TObject *Sender);
private:	// User declarations
  bool  FAbort;
public:		// User declarations
  __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
