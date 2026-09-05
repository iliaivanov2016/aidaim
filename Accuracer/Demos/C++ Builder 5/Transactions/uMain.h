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
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator2;
        TButton *bnClose;
        TButton *Button1;
        TButton *Button2;
        TButton *Button3;
        TButton *Button4;
        TACRDatabase *ACRDatabase1;
        TACRQuery *ACRQuery1;
        TACRTable *ACRTable1;
        TDataSource *DataSource1;
        TDataSource *DataSource2;
        TACRQuery *ACRQuery2;
        void __fastcall Button1Click(TObject *Sender);
        void __fastcall Button2Click(TObject *Sender);
        void __fastcall bnCloseClick(TObject *Sender);
        void __fastcall Button4Click(TObject *Sender);
        void __fastcall Button3Click(TObject *Sender);
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
