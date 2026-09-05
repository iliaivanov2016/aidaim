//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
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
        TSplitter *Splitter1;
        TPanel *Panel1;
        TSplitter *Splitter2;
        TGroupBox *GroupBox1;
        TMemo *Memo1;
        TGroupBox *gbResult;
        TDBGrid *DBGrid1;
        TPanel *Panel2;
        TDBNavigator *DBNavigator1;
        TButton *Button1;
        TButton *Button2;
        TButton *Button3;
        TDataSource *DataSource1;
        TACRQuery *ACRQuery1;
        TACRDatabase *ACRDatabase1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall Button3Click(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
        void __fastcall Button2Click(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
