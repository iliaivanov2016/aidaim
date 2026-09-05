//---------------------------------------------------------------------------

#ifndef uConnectH
#define uConnectH
//---------------------------------------------------------------------------
#include "mySQLDbTables.hpp"
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TConnectDlg : public TForm
{
__published:	// IDE-managed Components
        TBevel *Bevel1;
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TLabel *Label5;
        TEdit *DBUserID;
        TEdit *DBPasswd;
        TEdit *DBName;
        TEdit *DBHost;
        TEdit *DBPort;
        TButton *OkBtn;
        TButton *CancelBtn;
public:		// User declarations
        TmySQLDatabase *Database;
public:		// User declarations
        __fastcall TConnectDlg(TComponent* Owner);
        void __fastcall GetDatabaseProperty(TmySQLDatabase *Db);
        void __fastcall SetDatabaseProperty(TmySQLDatabase *Db);
        bool __fastcall Edit();
};
bool __fastcall ShowConnectDlg(TmySQLDatabase *Db);
//---------------------------------------------------------------------------
extern PACKAGE TConnectDlg *ConnectDlg;
//---------------------------------------------------------------------------
#endif
