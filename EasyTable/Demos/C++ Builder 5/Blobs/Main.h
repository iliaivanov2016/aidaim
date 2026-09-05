//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <Buttons.hpp>
#include <Db.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <ComCtrls.hpp>
#include <DBCtrls.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel1;
        TBitBtn *NewCustBtn;
        TBitBtn *EditCustBtn;
        TBitBtn *DeleteCustBtn;
        TPanel *Panel2;
        TLabel *Label1;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid1;
        TDBMemo *DBMemo1;
        TDBImage *DBImage1;
        TDBRichEdit *DBRichEdit1;
        TEasyTable *EasyTable1;
        TDataSource *DataSource1;
  TEasyDatabase *EasyDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall NewCustBtnClick(TObject *Sender);
        void __fastcall EditCustBtnClick(TObject *Sender);
        void __fastcall DeleteCustBtnClick(TObject *Sender);
private:	// User declarations
        void __fastcall UpdateButtons();
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
