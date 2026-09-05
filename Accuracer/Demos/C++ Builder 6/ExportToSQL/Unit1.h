//---------------------------------------------------------------------------
#ifndef Unit1H
#define Unit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "ACRMain.hpp"
#include <ComCtrls.hpp>
#include <Db.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TPanel *Panel1;
        TLabel *Label1;
        TPanel *Panel2;
        TButton *Button1;
        TButton *Button3;
        TButton *Button2;
        TButton *Button4;
        TPanel *Panel4;
        TSplitter *Splitter1;
        TGroupBox *gbSQL;
        TRichEdit *Memo1;
        TPageControl *PageControl1;
        TTabSheet *tsTables;
        TGroupBox *gbTables;
        TListBox *lbTables;
        TTabSheet *tsExportOptions;
        TGroupBox *gbExportOptions;
        TGroupBox *GroupBox3;
        TCheckBox *cbExportStructure;
        TCheckBox *cbAddDROPTable;
        TGroupBox *GroupBox4;
        TCheckBox *cbExportData;
        TCheckBox *cbExportBLOBFields;
        TGroupBox *GroupBox5;
        TCheckBox *cbExportIndexes;
        TCheckBox *cbAddDROPIndex;
        TCheckBox *cbUseBrackets;
        TACRTable *ACRTable1;
        TACRDatabase *ACRDatabase1;
        TACRDatabase *ACRDatabase2;
        TACRQuery *ACRQuery1;
        void __fastcall Button2Click(TObject *Sender);
        void __fastcall Button3Click(TObject *Sender);
        void __fastcall Button1Click(TObject *Sender);
        void __fastcall Button4Click(TObject *Sender);
        void __fastcall FormCreate(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
