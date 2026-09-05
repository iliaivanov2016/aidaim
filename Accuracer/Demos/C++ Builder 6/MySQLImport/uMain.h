//---------------------------------------------------------------------------

#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------

#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "mySQLDbTables.hpp"
#include <Buttons.hpp>
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <Menus.hpp>
#include "ACRMain.hpp"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel1;
        TLabel *lbField1;
        TDBMemo *DBMemo1;
        TDBImage *DBImage1;
        TPanel *Panel2;
        TDBText *DBLabel2;
        TPanel *Panel4;
        TPanel *Panel5;
        TBitBtn *ConnectBtn;
        TBitBtn *btnExit;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TDataSource *DataSource1;
        TmySQLDatabase *Database1;
        TmySQLTable *Table1;
        TOpenDialog *dlgOpen1;
        TSaveDialog *dlgSave1;
        TBitBtn *ImportBtn;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TRadioGroup *RadioGroup1;
        void __fastcall ConnectBtnClick(TObject *Sender);
        void __fastcall RadioGroup1Click(TObject *Sender);
        void __fastcall ImportBtnClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);

};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
