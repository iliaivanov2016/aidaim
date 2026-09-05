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
#include "ACRMain.hpp"
//---------------------------------------------------------------------------
class TfmMain : public TForm
{
__published:	// IDE-managed Components
	TSplitter *Splitter1;
	TPanel *Panel1;
	TPanel *Panel2;
	TButton *Button1;
	TButton *Button2;
	TButton *Button3;
	TButton *bnExit;
	TButton *Button4;
	TButton *Button5;
	TButton *Button6;
	TButton *Button7;
	TButton *bnRunSQL;
	TButton *Button8;
	TRichEdit *reSQL;
	TGroupBox *gbDB1;
	TSplitter *Splitter2;
	TListBox *lbTables1;
	TDBGrid *DBGrid1;
	TDBNavigator *DBNavigator1;
	TGroupBox *gbDB2;
	TSplitter *Splitter3;
	TListBox *lbTables2;
	TDBGrid *DBGrid2;
	TDBNavigator *DBNavigator2;
	TACRDatabase *ACRDatabase1;
	TACRDatabase *ACRDatabase2;
	TACRQuery *ACRQuery1;
	TACRTable *ACRTable1;
	TACRTable *ACRTable2;
	TACRQuery *ACRQuery2;
	TDataSource *DS1;
	TDataSource *DS2;
	TACRQuery *ACRQuery3;
	void __fastcall Button1Click(TObject *Sender);
	void __fastcall Button2Click(TObject *Sender);
	void __fastcall Button3Click(TObject *Sender);
	void __fastcall Button4Click(TObject *Sender);
	void __fastcall Button8Click(TObject *Sender);
	void __fastcall Button5Click(TObject *Sender);
	void __fastcall Button6Click(TObject *Sender);
	void __fastcall Button7Click(TObject *Sender);
	void __fastcall bnRunSQLClick(TObject *Sender);
	void __fastcall bnExitClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
	__fastcall TfmMain(TComponent* Owner);
	void __fastcall TfmMain::ShowTables(TACRDatabase *db);

};
//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
#endif
