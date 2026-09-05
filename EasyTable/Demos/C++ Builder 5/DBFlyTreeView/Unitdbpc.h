//---------------------------------------------------------------------------
#ifndef UnitdbpcH
#define UnitdbpcH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "dbftreepro.hpp"
#include "ISCalendar.hpp"
#include "exgrid.hpp"
#include "FlytreePro.hpp"
#include "RapTree.hpp"
#include <ComCtrls.hpp>
#include <Db.hpp>
#include <DBCtrls.hpp>
#include <EasyTable.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TDataSource *DataSource1;
        TDataSource *DetailsDS;
        TDataSource *MasterSource;
        TPageControl *PageControl1;
        TTabSheet *TabSheet1;
        TPanel *Panel1;
        TLabel *Label1;
        TDBFlyTreeviewPro *DBFP1;
        TDBNavigator *DBNavigator1;
        TTabSheet *TabSheet2;
        TPanel *Panel2;
        TLabel *Label2;
        TDBFlyTreeviewPro *DBFP2;
        TDBFlyTreeviewPro *DropdownFP;
  TEasyDatabase *EasyDatabase1;
  TEasyTable *MainTable;
  TEasyTable *Customers;
  TEasyTable *Details;
  TEasyTable *Masters;
        TEasyTable *Masters;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall DBFP1GetNodeData(TFlyNode *Node, int Column,
          AnsiString &aData);
        void __fastcall DBFP1PrepareDropDown(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *Dropdown);
        void __fastcall DBFP1ValidateNodeData(TFlyNode *Node, int Column,
          AnsiString &aData, bool &Cancel);
        void __fastcall DBFP1GetDropdownControl(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *DropDown,
          TWinControl *&DropDownCtl);
        void __fastcall ISCalendarKeyDown(TObject *Sender, WORD &Key,
          TShiftState Shift);
        void __fastcall DBFP1CloseUp(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *DropDown, bool &Accept);
        void __fastcall DBFP1ButtonPress(TISPlugInplaceEdit *Sender,
          TPressedButtons Button);
        void __fastcall DropdownFPKeyDown(TObject *Sender, WORD &Key,
          TShiftState Shift);
        void __fastcall DBFP2ButtonPress(TISPlugInplaceEdit *Sender,
          TPressedButtons Button);
        void __fastcall DBFP2GetDropdownControl(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *DropDown,
          TWinControl *&DropDownCtl);
        void __fastcall DBFP2CloseUp(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *DropDown, bool &Accept);
        void __fastcall DBFP2PrepareDropDown(TISPlugInplaceEdit *Sender,
          TISPlugSection *Section, TISDropDown *Dropdown);
        void __fastcall DBFP2ValidateNodeData(TFlyNode *Node, int Column,
          AnsiString &aData, bool &Cancel);
private:	// User declarations
        void ActivateTable(TEasyTable* aTable);
        AnsiString GetCustomerCompany(AnsiString &aData);
        AnsiString GetCustomerID(AnsiString &aData);
        void FillCustomers(TISPlugSection* aSection);
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
