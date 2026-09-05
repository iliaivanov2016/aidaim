//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Ffactwin.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
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
  ACRTable1->Active = true;
}
//---------------------------------------------------------------------------
 