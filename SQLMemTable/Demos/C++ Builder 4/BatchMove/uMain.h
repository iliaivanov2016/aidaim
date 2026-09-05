//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "SQLMemMain.hpp"
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TBevel *Bevel2;
        TBevel *Bevel1;
        TLabel *Label8;
        TLabel *Label5;
        TLabel *Label1;
        TLabel *Label2;
        TComboBox *cmbxDestIndex;
        TComboBox *cmbxSourceIndex;
        TDBGrid *DBGrid1;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator1;
        TDBNavigator *DBNavigator2;
        TSQLMemTable *tDest;
        TDataSource *dsSource;
        TDataSource *dsDest;
        TSQLMemTable *tSource;
        TSQLMemBatchMove *BatchMove1;
        TButton *Button1;
        TLabel *Label10;
        TCheckBox *chkbxAbortKey;
        TCheckBox *chkbxAbortProblem;
        TLabel *Label11;
        TEdit *edtRecCount;
        TBevel *Bevel3;
        TLabel *Label9;
        TComboBox *cmbxMode;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall cmbxSourceIndexChange(TObject *Sender);
        void __fastcall cmbxDestIndexChange(TObject *Sender);
        void __fastcall chkbxAbortKeyClick(TObject *Sender);
        void __fastcall chkbxAbortProblemClick(TObject *Sender);
        void __fastcall cmbxModeChange(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
