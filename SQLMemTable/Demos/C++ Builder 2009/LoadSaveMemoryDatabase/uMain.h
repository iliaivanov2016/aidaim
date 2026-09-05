//---------------------------------------------------------------------------

#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "SQLMemMain.hpp"
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TfmMain : public TForm
{
__published:	// IDE-managed Components
	TSplitter *Splitter1;
	TPanel *Panel1;
	TButton *bnLoadDB;
	TButton *bnSaveDB;
	TButton *bnClose;
	TPanel *Panel2;
	TDBGrid *DBGrid1;
	TDBNavigator *DBNavigator1;
	TPanel *Panel3;
	TDBGrid *DBGrid2;
	TDBNavigator *DBNavigator2;
	TSQLMemTable *tDept;
	TSQLMemDatabase *db;
	TSQLMemTable *tEmp;
	TDataSource *DataSource1;
	TDataSource *DataSource2;
	void __fastcall bnLoadDBClick(TObject *Sender);
	void __fastcall FormCreate(TObject *Sender);
	void __fastcall bnSaveDBClick(TObject *Sender);
	void __fastcall bnCloseClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
	__fastcall TfmMain(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
AnsiString  TempDir,SaveFileName;
#endif
