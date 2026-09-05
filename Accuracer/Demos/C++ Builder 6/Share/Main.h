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
        TDBGrid *DBGrid1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TDataSource *DataSource1;
        TDataSource *DataSource2;
        TLabel *Label1;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TACRTable *ACRTable2;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall ACRTable1AfterDelete(TDataSet *DataSet);
        void __fastcall ACRTable1AfterPost(TDataSet *DataSet);
        void __fastcall ACRTable2AfterDelete(TDataSet *DataSet);
        void __fastcall ACRTable2AfterPost(TDataSet *DataSet);
private:	// User declarations
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
