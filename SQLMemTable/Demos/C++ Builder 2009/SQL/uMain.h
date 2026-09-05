//---------------------------------------------------------------------------

#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ComCtrls.hpp>
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <Menus.hpp>
#include "SQLMemMain.hpp"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
	TRichEdit *reSQL;
	TPanel *Panel1;
	TLabel *lbRecCount;
	TLabel *lbTime;
	TButton *bnOpen;
	TButton *bnExecSQL;
	TButton *bnClose;
	TDBNavigator *DBNavigator1;
	TDBGrid *DBGrid1;
	TDataSource *DataSource1;
	TSQLMemQuery *SQLMemQuery1;
	void __fastcall FormCreate(TObject *Sender);
	void __fastcall bnCloseClick(TObject *Sender);
	void __fastcall bnExecSQLClick(TObject *Sender);
	void __fastcall bnOpenClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
	__fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
