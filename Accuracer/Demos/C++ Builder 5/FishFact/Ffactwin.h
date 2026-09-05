//---------------------------------------------------------------------------
#ifndef FfactwinH
#define FfactwinH
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
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel1;
        TDBText *DBLabel1;
        TDBImage *DBImage1;
        TPanel *Panel2;
        TLabel *Label1;
        TDBText *DBLabel2;
        TPanel *Panel3;
        TDBMemo *DBMemo1;
        TPanel *Panel4;
        TDBGrid *DBGrid1;
        TDataSource *DataSource1;
  TLabel *Label2;
        TACRTable *ACRTable1;
        TACRDatabase *ACRDatabase1;
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
