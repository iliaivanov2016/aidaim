//---------------------------------------------------------------------------
#ifndef uRegisterH
#define uRegisterH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include "uMain.h"
#include "MsgTypes.hpp"
#include "MsgComBase.hpp"
//---------------------------------------------------------------------------
class TfmRegister : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *bnRegister;
  TButton *bnCancel;
  TPanel *Panel2;
  TLabel *Label12;
  TLabel *Label10;
  TLabel *Label13;
  TLabel *Label14;
  TLabel *Label15;
  TLabel *Label16;
  TLabel *Label1;
  TEdit *RegUserDepartment;
  TEdit *RegUserCompany;
  TEdit *RegUserLastName;
  TEdit *RegUserFirstName;
  TEdit *RegUserName;
  TEdit *RegUserID;
  TEdit *edPassword;
  TGroupBox *GroupBox1;
  TLabel *Label2;
  TLabel *Label3;
  TEdit *edHost;
  TEdit *edPort;
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall bnCancelClick(TObject *Sender);
  void __fastcall bnRegisterClick(TObject *Sender);
private:	// User declarations
  bool FClose;
public:		// User declarations
  __fastcall TfmRegister(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmRegister *fmRegister;
//---------------------------------------------------------------------------
#endif
