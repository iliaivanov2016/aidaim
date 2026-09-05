//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include "ACRTypes.hpp"
#include <ComCtrls.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <DB.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
  TSplitter *Splitter1;
  TPanel *Panel1;
  TGroupBox *GroupBox1;
  TDBGrid *dbgDept;
  TDBNavigator *DBNavigator3;
  TPanel *Panel2;
  TButton *Button1;
  TRichEdit *reSQL;
  TButton *bnExec;
  TGroupBox *GroupBox2;
  TDBNavigator *DBNavigator2;
  TDBGrid *dbgEmp;
  TDataSource *dsDept;
  TDataSource *dsEmp;
  TACRTable *tDept;
  TACRTable *tEmp;
  TACRQuery *ACRQuery1;
  void __fastcall tDeptAfterPost(TDataSet *DataSet);
  void __fastcall tDeptAfterDelete(TDataSet *DataSet);
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall bnExecClick(TObject *Sender);
  void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
  __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
