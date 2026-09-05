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
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TBevel *Bevel1;
        TLabel *Label6;
        TLabel *Label7;
        TLabel *Label8;
        TBevel *Bevel2;
        TLabel *Label5;
        TLabel *Label4;
        TLabel *Label3;
        TBevel *Bevel3;
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label10;
        TLabel *Label9;
        TLabel *Label12;
        TLabel *Label13;
        TLabel *Label14;
        TLabel *Label11;
        TLabel *Label15;
        TComboBox *cmbxDestTable;
        TComboBox *cmbxDestIndex;
        TComboBox *cmbxSourceTable;
        TComboBox *cmbxSourceIndex;
        TComboBox *cmbxMode;
        TButton *Button1;
        TCheckBox *chkbxAbortKey;
        TCheckBox *chkbxAbortProblem;
        TCheckBox *chkbxTrans;
        TEdit *edtChangedTable;
        TEdit *edtKeyVioTbl;
        TEdit *edtProbTbl;
        TEdit *edtRecCount;
        TEdit *edtSourceDBFileName;
        TEdit *edtDestDBFileName;
        TButton *bnChooseSourceDB;
        TButton *bnChooseDestDB;
        TEdit *edtCommitCount;
        TACRBatchMove *BatchMove1;
        TACRTable *tblSource;
        TACRTable *tblDest;
        TACRDatabase *dbSource;
        TACRDatabase *dbDest;
        TOpenDialog *OpenDialog1;
        void __fastcall bnChooseSourceDBClick(TObject *Sender);
        void __fastcall bnChooseDestDBClick(TObject *Sender);
        void __fastcall cmbxSourceTableChange(TObject *Sender);
        void __fastcall cmbxDestTableChange(TObject *Sender);
        void __fastcall cmbxSourceIndexChange(TObject *Sender);
        void __fastcall cmbxDestIndexChange(TObject *Sender);
        void __fastcall chkbxAbortKeyClick(TObject *Sender);
        void __fastcall chkbxAbortProblemClick(TObject *Sender);
        void __fastcall chkbxTransClick(TObject *Sender);
        void __fastcall FormCreate(TObject *Sender);
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
