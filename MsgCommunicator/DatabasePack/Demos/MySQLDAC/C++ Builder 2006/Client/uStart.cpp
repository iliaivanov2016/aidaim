//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uStart.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TfmStart *fmStart;
//---------------------------------------------------------------------------
__fastcall TfmStart::TfmStart(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmStart::FormShow(TObject *Sender)
{
 ModalResult = mrOk;
 bnOK->SetFocus();  
}
//---------------------------------------------------------------------------
