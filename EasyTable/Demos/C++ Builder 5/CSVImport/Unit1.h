//---------------------------------------------------------------------------

#ifndef Unit1H
#define Unit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <ADODB.hpp>
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
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid2;
        TGroupBox *GroupBox2;
        TDBGrid *DBGrid1;
        TADODataSet *ADODataSet1;
        TEasyTable *EasyTable1;
        TDataSource *dsEasyTable;
        TDataSource *dsADO;
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
