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
class TfmMain : public TForm
{
__published:	// IDE-managed Components
        TGroupBox *GroupBox1;
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TEdit *edDBName;
        TButton *bnConnect;
        TButton *bnDisconnect;
        TEdit *edRemoteHost;
        TEdit *edRemotePort;
        TEdit *edLocalPort;
        TGroupBox *gbTables;
        TListBox *lbTables;
        TGroupBox *gbRecords;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TDataSource *DataSource1;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall bnConnectClick(TObject *Sender);
        void __fastcall bnDisconnectClick(TObject *Sender);
        void __fastcall lbTablesDblClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TfmMain(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
#endif
