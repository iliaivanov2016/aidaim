//---------------------------------------------------------------------------
#ifndef uStartH
#define uStartH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TfmStart : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *bnOK;
  TButton *bnCancel;
  TRadioGroup *rgAction;
  void __fastcall FormShow(TObject *Sender);
private:	// User declarations
public:		// User declarations
  __fastcall TfmStart(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmStart *fmStart;
//---------------------------------------------------------------------------
#endif
