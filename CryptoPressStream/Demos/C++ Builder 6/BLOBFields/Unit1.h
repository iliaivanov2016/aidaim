//---------------------------------------------------------------------------

#ifndef Unit1H
#define Unit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "CPSMain.hpp"
#include <ComCtrls.hpp>
#include <DB.hpp>
#include <DBCtrls.hpp>
#include <DBGrids.hpp>
#include <DBTables.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TDBGrid *DBGrid1;
        TPanel *Panel1;
        TButton *bnCompressTable;
        TButton *bnBrowseCompressed;
        TButton *bnExit;
        TDBNavigator *DBNavigator1;
        TPanel *Panel2;
        TSplitter *Splitter1;
        TImage *Image2;
        TRichEdit *RichEdit2;
        TCPSManager *CPSManager1;
        TTable *tSource;
        TDataSource *DataSource1;
        TDataSource *DataSource2;
        TTable *tDest;
        void __fastcall bnCompressTableClick(TObject *Sender);
        void __fastcall bnBrowseCompressedClick(TObject *Sender);
        void __fastcall tDestAfterScroll(TDataSet *DataSet);
        void __fastcall bnExitClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
