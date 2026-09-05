//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TfmMain : public TForm
{
__published:	// IDE-managed Components
  TPanel *Panel1;
  TButton *Button1;
  TButton *Button2;
  TButton *Button3;
  TButton *Button4;
  TButton *Button5;
  TGroupBox *GroupBox2;
  TSplitter *Splitter1;
  TDBGrid *DBGridLog;
  TDBNavigator *DBNavigator1;
  TDBMemo *DBMemoSQL;
  TACRTable *TestTable;
  TACRQuery *ACRQuery1;
  TACRTable *LogTable;
  TDataSource *DataSource1;
  TACRDatabase *ACRDatabase1;
  void __fastcall Button3Click(TObject *Sender);
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall Button2Click(TObject *Sender);
  void __fastcall Button4Click(TObject *Sender);
  void __fastcall Button5Click(TObject *Sender);
  void __fastcall ACRDatabase1BeforeExecuteSQL(TACRQuery *Sender,
          bool &Abort);
  void __fastcall ACRDatabase1BeforeInsertRecord(TACRDataSet *Sender,
          const AnsiString TableName,
          const TACRArrayOfTACRVariant FieldValues, bool &Abort);
  void __fastcall ACRDatabase1AfterInsertRecord(TACRDataSet *Sender,
          const AnsiString TableName,
          const TACRArrayOfTACRVariant FieldValues);
  void __fastcall ACRDatabase1AfterUpdateRecord(TACRDataSet *Sender,
          const AnsiString TableName,
          const TACRArrayOfTACRVariant OldFieldValues,
          const TACRArrayOfTACRVariant NewFieldValues);
  void __fastcall ACRDatabase1AfterDeleteRecord(TACRDataSet *Sender,
          const AnsiString TableName,
          const TACRArrayOfTACRVariant FieldValues);
  void __fastcall ACRDatabase1AfterExecuteSQL(TACRQuery *Sender);
private:	// User declarations
public:		// User declarations
  __fastcall TfmMain(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
#endif
