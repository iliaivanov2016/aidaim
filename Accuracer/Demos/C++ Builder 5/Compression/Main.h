//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include <Buttons.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel1;
        TBitBtn *NewCustBtn;
        TDBNavigator *DBNavigator1;
        TPanel *Panel2;
        TLabel *Label1;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid1;
        TDBMemo *DBMemo1;
        TACRTable *ACRTable1;
        TACRDatabase *ACRDatabase1;
        TDataSource *DataSource1;
        void __fastcall NewCustBtnClick(TObject *Sender);
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
