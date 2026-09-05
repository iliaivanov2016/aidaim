//---------------------------------------------------------------------------

#ifndef uBatchH
#define uBatchH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator2;
        TButton *Button1;
        TRadioGroup *rgMode;
        TEasyTable *SourceTable;
        TEasyTable *DestTable;
        TDataSource *DataSource1;
        TDataSource *DataSource2;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
