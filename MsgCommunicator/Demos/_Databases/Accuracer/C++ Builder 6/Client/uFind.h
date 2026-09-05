//---------------------------------------------------------------------------
#ifndef uFindH
#define uFindH
//---------------------------------------------------------------------------
#include <alloc.h>
#include <stdlib.h>
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "uMain.h"
#include "MsgClient.hpp"
#include "MsgComBase.hpp"
#include "MsgTypes.hpp"
//---------------------------------------------------------------------------
class TfmFind : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *bnFind;
  TButton *bnAdd;
  TButton *bnCancel;
  TPanel *Panel2;
  TGroupBox *gbUsers;
  TStringGrid *sgUsers;
  TPanel *Panel3;
  TGroupBox *gbSearchConditions;
  TLabel *Label1;
  TLabel *Label2;
  TEdit *eUserID;
  TEdit *eUserName;
  TComboBox *cbName;
  TCheckBox *chbUserName;
  TRadioGroup *rgStatus;
  TGroupBox *GroupBox1;
  TLabel *Label3;
  TEdit *eContactCustomName;
  TRadioGroup *rgContactNameSource;
  void __fastcall FormShow(TObject *Sender);
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
  void __fastcall bnCancelClick(TObject *Sender);
  void __fastcall bnAddClick(TObject *Sender);
  void __fastcall bnFindClick(TObject *Sender);
  void __fastcall sgUsersDrawCell(TObject *Sender, int ACol, int ARow,
          TRect &Rect, TGridDrawState State);
  void __fastcall sgUsersSelectCell(TObject *Sender, int ACol, int ARow,
          bool &CanSelect);
  void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
    bool FClose;
public:		// User declarations
  __fastcall TfmFind(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmFind *fmFind;
//---------------------------------------------------------------------------
#endif
