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
#include "EasyTable.hpp"
#include <Db.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
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
        TEasyTable *Deps2_ds;
        TEasyTable *Members1_ds;
        TEasyTable *DMLinks1_ds;
        TStringField *DMLinks1_dsMemberName;
        TIntegerField *DMLinks1_dsDepartment_ID;
        TIntegerField *DMLinks1_dsMember_ID;
        TAutoIncField *DMLinks1_dsID;
        TDataSource *DataSource2;
        TDataSource *DataSource4;
        TEasyTable *DMLinks2_ds;
        TStringField *DMLinks2_dsDepartmentName;
        TIntegerField *DMLinks2_dsDepartment_ID;
        TIntegerField *DMLinks2_dsMember_ID;
        TAutoIncField *DMLinks2_dsID;
        TDataSource *DataSource3;
        TEasyTable *Members2_ds;
        TEasyTable *Deps1_ds;
        TDataSource *DataSource1;
        TEasyDatabase *EasyDatabase1;
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
