//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <SQLMemMain.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <DB.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TButton *bnSave;
        TButton *bnLoad;
        TButton *bnExit;
        TSQLMemTable *SQLMemTable1;
        TDataSource *dsTable;
        TOpenDialog *OpenDialog1;
        TSaveDialog *SaveDialog1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall bnLoadClick(TObject *Sender);
        void __fastcall bnSaveClick(TObject *Sender);
        void __fastcall bnExitClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
