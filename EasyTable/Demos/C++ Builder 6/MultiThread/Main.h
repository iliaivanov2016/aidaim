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
#include <DBCtrls.hpp>
//---------------------------------------------------------------------------
class TMainForm : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel3;
        TEasyTable *EasyTable1;
        TDataSource *DataSource1;
        TEasyDatabase *EasyDatabase1;
        TPanel *Panel2;
        TLabel *Label1;
        TLabel *Label2;
        TLabel *lbRecCount;
        TLabel *lbRecNo;
        TDBNavigator *DBNavigator1;
        TButton *btStart;
        TDBGrid *DBGrid1;
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
        void __fastcall UpdateButtons();
public:		// User declarations
        __fastcall TMainForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TMainForm *MainForm;
//---------------------------------------------------------------------------
#endif
