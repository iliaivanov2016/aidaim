//---------------------------------------------------------------------------
#ifndef uLoginH
#define uLoginH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include "uMain.h"
//---------------------------------------------------------------------------
class TfmLogin : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *bnLogin;
  TButton *bnCancel;
  TPanel *Panel2;
  TLabel *Label12;
  TLabel *Label10;
  TEdit *edPassword;
  TEdit *RegUserID;
  TGroupBox *GroupBox1;
  TLabel *Label1;
  TLabel *Label2;
  TEdit *edHost;
  TEdit *edPort;
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall bnCancelClick(TObject *Sender);
  void __fastcall bnLoginClick(TObject *Sender);
private:	// User declarations
  bool FClose;
public:		// User declarations
  __fastcall TfmLogin(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmLogin *fmLogin;
//---------------------------------------------------------------------------
#endif
