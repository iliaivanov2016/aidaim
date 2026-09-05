//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "ACRMain.hpp"
#include <DB.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TLabel *Label2;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TButton *btSaveTable;
        TDataSource *DataSource1;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TButton *btLoad;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall btSaveTableClick(TObject *Sender);
        void __fastcall btLoadClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
