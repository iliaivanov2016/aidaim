//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Cust.h"
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
 MainForm->EasyTable1->Post();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::Button2Click(TObject *Sender)
{
 MainForm->EasyTable1->Cancel();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::FormClose(TObject *Sender, TCloseAction &Action)
{
 if ((MainForm->EasyTable1->State == dsInsert) ||
     (MainForm->EasyTable1->State == dsEdit))
   MainForm->EasyTable1->Cancel();
}
//---------------------------------------------------------------------------
void __fastcall TCustForm::FormActivate(TObject *Sender)
{
 ActiveControl = CompanyDBEd;
}
//---------------------------------------------------------------------------


