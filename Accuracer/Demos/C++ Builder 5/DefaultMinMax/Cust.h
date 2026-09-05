//---------------------------------------------------------------------------
#ifndef CustH
#define CustH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Buttons.hpp>
//---------------------------------------------------------------------------
class TForm2 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label2;
        TLabel *Label4;
        TLabel *Label6;
        TLabel *Label3;
        TLabel *Label1;
        TBitBtn *BitBtn1;
        TBitBtn *BitBtn2;
        TEdit *Edit1;
        TComboBox *ComboBox2;
        TEdit *Edit2;
        TEdit *Edit3;
        TEdit *Edit4;
private:	// User declarations
public:		// User declarations
        __fastcall TForm2(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm2 *Form2;
//---------------------------------------------------------------------------
#endif
