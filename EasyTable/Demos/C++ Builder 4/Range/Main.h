//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <Buttons.hpp>
#include <Db.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid1;
        TPanel *Panel1;
        TBitBtn *NewCustBtn;
        TBitBtn *EditCustBtn;
        TBitBtn *DeleteCustBtn;
        TEasyTable *EasyTable1;
        TDataSource *DataSource1;
        TPanel *Panel2;
        TLabel *Label1;
        TGroupBox *GroupBox2;
        TLabel *Label2;
        TLabel *Label3;
        TComboBox *cmbStartRange;
        TButton *btApply;
        TButton *btCancel;
        TComboBox *cmbEndRange;
        TCheckBox *cbStartKeyExclusive;
        TCheckBox *cbEndKeyExclusive;
  TEasyDatabase *EasyDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall NewCustBtnClick(TObject *Sender);
        void __fastcall EditCustBtnClick(TObject *Sender);
        void __fastcall DeleteCustBtnClick(TObject *Sender);
        void __fastcall btApplyClick(TObject *Sender);
        void __fastcall btCancelClick(TObject *Sender);
private:	// User declarations
        void __fastcall UpdateButtons();
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
