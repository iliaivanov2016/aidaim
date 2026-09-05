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
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
#include "ACRMain.hpp"
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
  TLabel *Label2;
  TLabel *Label3;
  TPanel *Panel1;
  TDBText *DBLabel1;
  TDBImage *DBImage1;
  TPanel *Panel2;
  TLabel *Label1;
  TDBText *DBLabel2;
  TPanel *Panel3;
  TDBMemo *DBMemo1;
  TPanel *Panel4;
  TDBGrid *DBGrid1;
  TButton *bnOpenDB;
  TButton *bnCloseDB;
  TButton *bnMakeEXE;
  TButton *bnExit;
  TEdit *eDBPath;
  TButton *Button5;
  TDBNavigator *DBNavigator1;
  TButton *bnExtract;
  TDataSource *DataSource1;
  TOpenDialog *OpenDialog1;
  TSaveDialog *SaveDialog1;
  TSaveDialog *SaveDialog2;
        TACRDatabase *ACRDatabase1;
        TACRTable *ACRTable1;
        TFloatField *ACRTable1SpeciesNo;
        TStringField *ACRTable1Category;
        TStringField *ACRTable1Common_Name;
        TStringField *ACRTable1SpeciesName;
        TFloatField *ACRTable1Lengthcm;
        TFloatField *ACRTable1Length_In;
        TMemoField *ACRTable1Notes;
        TGraphicField *ACRTable1Graphic;
        TAutoIncField *ACRTable1id;
  void __fastcall FormCreate(TObject *Sender);
  void __fastcall bnMakeEXEClick(TObject *Sender);
  void __fastcall bnOpenDBClick(TObject *Sender);
  void __fastcall bnCloseDBClick(TObject *Sender);
  void __fastcall bnExitClick(TObject *Sender);
  void __fastcall Button5Click(TObject *Sender);
  void __fastcall bnExtractClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
  __fastcall TForm1(TComponent* Owner);
  void __fastcall OpenDatabase(bool bOpenAsExe);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
