//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include "MsgClient.hpp"
#include "MsgComBase.hpp"
#include "MsgDatabase.hpp"
#include "MsgDatabaseAccuracer.hpp"
#include <CheckLst.hpp>
#include <ComCtrls.hpp>
#include <ExtCtrls.hpp>
#include "uFind.h"
#include "uHistory.h"
#include "uLogin.h"
#include "uRegister.h"
#include "uStart.h"
//---------------------------------------------------------------------------
class TfmMain : public TForm
{
__published:	// IDE-managed Components
  TSplitter *Splitter1;
  TGroupBox *gbContacts;
  TPanel *pContactsControl;
  TButton *bnFind;
  TButton *bnHistory;
  TButton *bnSend;
  TCheckListBox *lbContacts;
  TPanel *pMain;
  TGroupBox *gbMessageDialog;
  TSplitter *Splitter2;
  TRichEdit *reView;
  TGroupBox *GroupBox1;
  TRichEdit *reSend;
  TACRDatabase *LocalDatabaseAccuracer;
  TMsgClient *MsgClient1;
  TMsgDatabaseAccuracer *MsgDatabaseAccuracer1;
  TMsgTempTableAccuracer *MsgTempTableAccuracer1;
  TTimer *Timer1;
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall bnFindClick(TObject *Sender);
  void __fastcall lbContactsDrawItem(TWinControl *Control, int Index,
          TRect &Rect, TOwnerDrawState State);
  void __fastcall lbContactsClick(TObject *Sender);
  void __fastcall MsgClient1ReceiveTextMessage(const DWORD FromUserID,
          const TDateTime SendingDate, const TDateTime DeliveryDate,
          const AnsiString Text);
  void __fastcall bnSendClick(TObject *Sender);
  void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
  void __fastcall FormActivate(TObject *Sender);
  void __fastcall Timer1Timer(TObject *Sender);
  void __fastcall MsgClient1UserOffLine(const DWORD UserID);
  void __fastcall MsgClient1UserOnLine(const DWORD UserID);
  void __fastcall bnHistoryClick(TObject *Sender);
  void __fastcall MsgClient1ReceiveUnicodeTextMessage(
          const DWORD FromUserID, const TDateTime SendingDate,
          const TDateTime DeliveryDate, const WideString Text);
private:	// User declarations
    AnsiString FConfigFileName;
    TMsgUserInfo FUserInfo;
    TStringList *FTemp;
    Acrcriticalsection::TRTLCriticalSection FCSect;
    bool FStarting;
public:		// User declarations
  __fastcall TfmMain(TComponent* Owner);
    void __fastcall  LoadSettings();
    void __fastcall  SaveSettings();
    void __fastcall  DoLogin();
    void __fastcall  DoRegister();
    bool Login();
    void __fastcall  FillContacts();
    void __fastcall  ClearContacts();
    void __fastcall  Lock();
    void __fastcall  Unlock();

};
class TClientDisplayThread : public TThread
{
 private:
    AnsiString FText;
    WideString FUnicodeText;
 public:		// User declarations
    __fastcall TClientDisplayThread(AnsiString text);
    __fastcall TClientDisplayThread(WideString text);
    void __fastcall DisplayMessage();
    void __fastcall Execute();
};

//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
#endif
