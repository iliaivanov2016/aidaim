//---------------------------------------------------------------------------
#ifndef MainUnitH
#define MainUnitH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ComCtrls.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include <Db.hpp>
#include "ACRMain.hpp"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TDataSource *DataSource1;
        TDataSource *DataSource3;
        TDataSource *DataSource2;
        TDataSource *DataSource4;
        TPanel *Panel2;
        TLabel *Label1;
        TPageControl *PageControl1;
        TTabSheet *TabSheet1;
        TGroupBox *GroupBox1;
        TGroupBox *GroupBox2;
        TDBGrid *DBGrid1;
        TDBNavigator *DBNavigator1;
        TGroupBox *GroupBox3;
        TDBGrid *DBGrid2;
        TDBNavigator *DBNavigator2;
        TTabSheet *TabSheet2;
        TGroupBox *GroupBox4;
        TGroupBox *GroupBox5;
        TDBGrid *DBGrid3;
        TDBNavigator *DBNavigator3;
        TGroupBox *GroupBox6;
        TDBGrid *DBGrid4;
        TDBNavigator *DBNavigator4;
        TACRDatabase *ACRDatabase1;
        TACRTable *Deps1_ds;
        TACRTable *Members2_ds;
        TACRTable *DMLinks1_ds;
        TACRTable *DMLinks2_ds;
        TACRTable *Members1_ds;
        TACRTable *Deps2_ds;
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
