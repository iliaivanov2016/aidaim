//---------------------------------------------------------------------------
#ifndef MainH
#define MainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "EasyTable.hpp"
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
        TLabel *Label2;
        TEdit *edPass;
        TButton *btnCreate;
        TButton *btnOpen;
        TButton *btnSetPwd;
        TButton *btnDecrypt;
        TButton *btnClose;
        TEasyTable *EasyTable1;
        TEasyDatabase *EasyDatabase1;
        TDataSource *DataSource1;
        void __fastcall btnCreateClick(TObject *Sender);
        void __fastcall btnOpenClick(TObject *Sender);
        void __fastcall btnCloseClick(TObject *Sender);
        void __fastcall btnSetPwdClick(TObject *Sender);
        void __fastcall btnDecryptClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
