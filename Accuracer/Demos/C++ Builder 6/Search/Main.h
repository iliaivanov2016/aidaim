//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Buttons.hpp>
#include <Db.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "ACRMain.hpp"
#include <DB.hpp>
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
        TDataSource *DataSource1;
        TPanel *Panel2;
        TLabel *Label1;
        TGroupBox *GroupBox2;
        TLabel *Label2;
        TGroupBox *GroupBox3;
        TCheckBox *cbCaseSensitive;
        TCheckBox *cbPartialKey;
        TComboBox *SearchCondition;
        TButton *btLocate;
        TButton *btLookup;
        TACRTable *ACRTable1;
        TACRDatabase *ACRDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall NewCustBtnClick(TObject *Sender);
        void __fastcall EditCustBtnClick(TObject *Sender);
        void __fastcall DeleteCustBtnClick(TObject *Sender);
        void __fastcall btLocateClick(TObject *Sender);
        void __fastcall btLookupClick(TObject *Sender);
private:	// User declarations
        void __fastcall UpdateButtons();
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
