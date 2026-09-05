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
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TADODataSet *ADODataSet1;
        TEasyTable *EasyTable1;
        TDataSource *dsEasyTable;
        TDataSource *dsADO;
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid2;
        TGroupBox *GroupBox2;
        TDBGrid *DBGrid1;
        TLabel *Label1;
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
