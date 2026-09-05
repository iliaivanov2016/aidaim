//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TGroupBox *GroupBox1;
        TDBGrid *DBGrid1;
        TDBMemo *DBMemo1;
        TDBNavigator *DBNavigator1;
        TPanel *Panel1;
        TButton *btnCreateUsingPassword;
        TButton *btnClose;
        TButton *bnCreateUsingKey;
        TDataSource *DataSource1;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        void __fastcall btnCreateUsingPasswordClick(TObject *Sender);
        void __fastcall bnCreateUsingKeyClick(TObject *Sender);
        void __fastcall btnCloseClick(TObject *Sender);
        void __fastcall CreateTableWithData(void);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
