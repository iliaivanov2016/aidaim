//---------------------------------------------------------------------------
#ifndef uHistoryH
#define uHistoryH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Db.hpp>
#include <Forms.hpp>
#include <ComCtrls.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "MsgTypes.hpp"
#include "MsgComBase.hpp"
#include "uMain.h"
//---------------------------------------------------------------------------
class TfmHistory : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *bnShowHistory;
  TButton *bnCancel;
  TGroupBox *GroupBox1;
  TLabel *Label1;
  TDateTimePicker *dtpFrom;
  TDateTimePicker *dtpTo;
  TCheckBox *cbLocal;
  TRadioGroup *rgMessageType;
  TCheckBox *cbFrom;
  TCheckBox *cbTo;
  TComboBox *cbMessage;
  TCheckBox *chbIgnoreCase;
  TEdit *eMessage;
  TGroupBox *gbMessages;
  TStringGrid *sgHistory;
  void __fastcall bnCancelClick(TObject *Sender);
  void __fastcall FormShow(TObject *Sender);
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall cbFromClick(TObject *Sender);
  void __fastcall cbToClick(TObject *Sender);
  void __fastcall bnShowHistoryClick(TObject *Sender);
  void __fastcall sgHistoryMouseMove(TObject *Sender, TShiftState Shift,
          int X, int Y);
private:	// User declarations
  bool FClose;
public:		// User declarations
  __fastcall TfmHistory(TComponent* Owner);
  void __fastcall ShowHistory(TDataSet* ds);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmHistory *fmHistory;
//---------------------------------------------------------------------------
#endif
