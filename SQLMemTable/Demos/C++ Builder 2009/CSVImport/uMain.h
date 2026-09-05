//---------------------------------------------------------------------------

#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ADODB.hpp>
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "SQLMemMain.hpp"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
	TLabel *Label1;
	TGroupBox *GroupBox1;
	TDBGrid *DBGrid2;
	TDBNavigator *DBNavigator2;
	TGroupBox *GroupBox2;
	TDBGrid *DBGrid1;
	TDBNavigator *DBNavigator1;
	TDataSource *dsADO;
	TADODataSet *ADODataSet1;
	TDataSource *dsSQLMemTable;
	TSQLMemTable *SQLMemTable1;
	void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
	__fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
