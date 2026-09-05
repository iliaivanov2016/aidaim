//---------------------------------------------------------------------------

#ifndef Unit1H
#define Unit1H
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
        TMainMenu *MainMenu1;
        TMenuItem *File1;
        TMenuItem *Exit1;
        TMenuItem *miField1;
        TMenuItem *CopytoClipboard1;
        TMenuItem *CuttoClipboard1;
        TMenuItem *Copytostream1;
        TMenuItem *N1;
        TMenuItem *SaveToFile1;
        TMenuItem *migLoadfromfile1;
        TSaveDialog *dlgSave1;
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
