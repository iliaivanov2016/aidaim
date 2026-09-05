//---------------------------------------------------------------------------
#ifndef CustH
#define CustH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "CSPIN.h"
#include <Buttons.hpp>
//---------------------------------------------------------------------------
class TForm2 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label1;
        TLabel *Label2;
        TLabel *Label3;
        TLabel *Label4;
        TLabel *Label5;
        TLabel *Label6;
        TComboBox *ComboBox1;
        TCSpinEdit *SpinEdit4;
        TCSpinEdit *SpinEdit2;
        TCSpinEdit *SpinEdit1;
        TCSpinEdit *SpinEdit3;
        TEdit *Edit1;
        TCheckBox *CheckBox1;
        TBitBtn *BitBtn1;
        TBitBtn *BitBtn2;
private:	// User declarations
public:		// User declarations
        __fastcall TForm2(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm2 *Form2;
//---------------------------------------------------------------------------
#endif
