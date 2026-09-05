//---------------------------------------------------------------------------
#ifndef MainUnitH
#define MainUnitH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
  TDBGrid *DBGrid1;
  TDBNavigator *DBNavigator1;
  TDBMemo *DBMemo1;
  TPanel *Panel1;
  TImage *Image1;
  TButton *bnLoad;
  TButton *Button1;
  TEasyTable *EasyTable1;
  TEasyDatabase *EasyDatabase1;
  TDataSource *DataSource1;
  TOpenDialog *OpenDialog1;
  TSaveDialog *SaveDialog1;
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall bnLoadClick(TObject *Sender);
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall EasyTable1AfterScroll(TDataSet *DataSet);
private:	// User declarations
public:		// User declarations
  __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
