//---------------------------------------------------------------------------
#ifndef ClientH
#define ClientH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <DBCtrls.hpp>
#include <Mask.hpp>
#include <Buttons.hpp>
#include <ComCtrls.hpp>
#include <Dialogs.hpp>
#include <ExtCtrls.hpp>
#include <ExtDlgs.hpp>
//---------------------------------------------------------------------------
class TCustForm : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TLabel *Label5;
        TBevel *Bevel1;
        TDBEdit *CompanyDBEd;
        TButton *Button1;
        TButton *Button2;
        TDBImage *Image;
        TDBMemo *DBMemo1;
        TDBRichEdit *DBRichEdit1;
        TBitBtn *btLoadPic;
        TButton *btLoadFile;
        TButton *btSaveFile;
        TOpenPictureDialog *OpenPictureDialog1;
        TOpenDialog *OpenDialog1;
        TSaveDialog *SaveDialog1;
        void __fastcall Button1Click(TObject *Sender);
        void __fastcall Button2Click(TObject *Sender);
        void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
        void __fastcall FormActivate(TObject *Sender);
        void __fastcall btLoadPicClick(TObject *Sender);
        void __fastcall btLoadFileClick(TObject *Sender);
        void __fastcall btSaveFileClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TCustForm(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TCustForm *CustForm;
//---------------------------------------------------------------------------
#endif
