//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "ACRMain.hpp"
#include <DB.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel2;
        TLabel *Label1;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TGroupBox *GroupBox2;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator2;
        TDataSource *DataSource1;
        TDataSource *DataSource2;
        TACRTable *ACRTable1;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable2;
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
