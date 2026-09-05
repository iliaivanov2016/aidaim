//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TDBGrid *DBGrid1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TEasyTable *EasyTable1;
        TDataSource *DataSource1;
        TEasyTable *EasyTable2;
        TDataSource *DataSource2;
        TLabel *Label1;
  TEasyDatabase *EasyDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall EasyTable1AfterDelete(TDataSet *DataSet);
        void __fastcall EasyTable1AfterPost(TDataSet *DataSet);
        void __fastcall EasyTable2AfterDelete(TDataSet *DataSet);
        void __fastcall EasyTable2AfterPost(TDataSet *DataSet);
private:	// User declarations
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
