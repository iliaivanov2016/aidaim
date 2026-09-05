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
#include "uBkThread.h"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TDBGrid *DBGrid1;
        TPanel *Panel1;
        TDBNavigator *DBNavigator1;
        TButton *Button1;
        TButton *Button2;
        TDataSource *DataSource1;
        void __fastcall Button2Click(TObject *Sender);
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
private:	// User declarations
        bool FFinished;
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
        void __fastcall Finish()
        {
         FFinished = true;
        } 

};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
