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
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TDBGrid *DBGrid1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TButton *btSaveTable;
        TEasyTable *EasyTable1;
        TDataSource *DataSource1;
        TEasyTable *EasyTable2;
        TDataSource *DataSource2;
  TEasyDatabase *EasyDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall btSaveTableClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
