//---------------------------------------------------------------------------

#ifndef Unit1H
#define Unit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include "ACRComMain.hpp"
#include "ACRTypes.hpp"
#include <ComCtrls.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TSplitter *Splitter1;
        TPanel *Panel1;
        TPanel *Panel4;
        TButton *Button1;
        TPanel *Panel5;
        TLabel *Label1;
        TPanel *Panel6;
        TRichEdit *reLog;
        TPanel *Panel2;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TPanel *Panel3;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator2;
        TTimer *Timer1;
        TACRDatabase *db1;
        TACRDatabase *db2;
        TACRTable *t1;
        TACRTable *t2;
        TDataSource *ds1;
        TDataSource *ds2;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall Timer1Timer(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
private:	// User declarations
        TACRTableState FState;
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
