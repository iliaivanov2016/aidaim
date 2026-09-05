//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Unitdbpc.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "dbftreepro"
#pragma link "exgrid"
#pragma link "FlytreePro"
#pragma link "ISCalendar"
#pragma link "RapTree"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
AnsiString TForm1::GetCustomerCompany(AnsiString &aData)
{
 if (Customers->Active)
 {
   Set<TLocateOption,0,1> flags;
   if (Customers->Locate("CUSTOMERID", aData, flags))
   {
      return Customers->FieldValues["CUSTOMERID"];
   }
   else
   {
     return aData;//not found
   }
 }
}
//---------------------------------------------------------------------------
AnsiString TForm1::GetCustomerID(AnsiString &aData)
{
 if (Customers->Active)
 {
   Set<TLocateOption,0,1> flags;
   if (Customers->Locate("COMPANYNAM", aData, flags))
   {
     return Customers->FieldValues["COMPANYNAM"];
   }
   else
   {
     return "";//not found
   }
 }
}
//---------------------------------------------------------------------------
void TForm1::ActivateTable(TEasyTable* aTable)
{
  if (!aTable->Active)
  {
//   aTable->DatabaseName = ExtractFileDir(ParamStr(0));
   aTable->Active = true;
  }
}

void TForm1::FillCustomers(TISPlugSection* aSection)
{
 TFlyNode* aNode;
 if (Customers->Active)
 {
  Customers->First();
  while (!Customers->Eof)
  {
    // add items to section for dropdown
    aNode = aSection->Items->Add(NULL, Customers->FieldValues["COMPANYNAM"]);
    aNode->Cells[1] = Customers->FieldValues["COMPANYNAM"];
    Customers->Next();
  }
 }

}

void __fastcall TForm1::FormCreate(TObject *Sender)
{
 ActivateTable(MainTable);
 ActivateTable(Customers);
 ActivateTable(Details);
 ActivateTable(Master);

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP1GetNodeData(TFlyNode *Node, int Column,
      AnsiString &aData)
{
  TDBTreeColumn* aColumn;
  aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[Column];
  if (aColumn->ColumnField == "CUSTOMERID")
     aData = GetCustomerCompany(aData);//translate value
}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP1PrepareDropDown(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *Dropdown)
{
  TDBTreeColumn* aColumn;
  TPopupTree * aTree;
  TFlyNode* aNode;

  aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[DBFP1->Col];
  if (aColumn->ColumnField == "CUSTOMERID")
  {
    Section->DropDownColCount = 2;
    Section->DropDownColwidth[1] = aColumn->Width;
    FillCustomers(Section);//fill data from another table
    aTree = (TPopupTree *)Dropdown->ContainedControl;
    aTree->FitToHeight = true;
    aTree->ColCount = 2; //create multicolumnar tree
    aTree->Width = aColumn->Width * 2;
    aTree->Height = 120;
    aTree->Options  << goVertLine << goColSizing;//you can size columns in dropdown!

    Dropdown->Styles << ddsSizeToControlSize;
  }
  else if (aColumn->ColumnField == "ORDERDATE")
  {
     TISCalendar* Cal;
     aNode = DBFP1->Selected;
     Cal = (TISCalendar *)Dropdown->ContainedControl;
     Cal->Date = StrToDate(aNode->Cells[DBFP1->Col]);
  }
  else if (aColumn->ColumnField == "EMPLOYEEID")
  {
    Dropdown->Styles << ddsOK << ddsSizeToControlSize;//adjust dropdown size to control size
    DropdownFP->DataSource = DetailsDS; //connect
  }
}
//---------------------------------------------------------------------------


void __fastcall TForm1::DBFP1ValidateNodeData(TFlyNode *Node, int Column,
      AnsiString &aData, bool &Cancel)
{
 TDBTreeColumn* aColumn;
 try
 {
  aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[Column];
  if (aColumn->ColumnField == "CUSTOMERID")
  {
    aData = GetCustomerID(aData);//translate value
    Cancel = (aData == "");//if value not found
  }
  else if (aColumn->ColumnField == "EMPLOYEEID")
  {
    Cancel = true ;//prevent from input
  }
 }
 catch (...)
 {
   Cancel = true; //cancel changes
 }

}
//---------------------------------------------------------------------------


void __fastcall TForm1::DBFP1GetDropdownControl(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *DropDown,
      TWinControl *&DropDownCtl)
{
  TDBTreeColumn* aColumn;

 aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[DBFP1->Col];

 if (aColumn->ColumnField == "ORDERDATE")
 {
   TISCalendar* aCal = new TISCalendar(DropDown);

   DropDownCtl = (TWinControl *)aCal;

   aCal->Colors->BackColor = clBtnFace;
   aCal->Colors->TitleBackColor = clGray;
   aCal->Date = StrToDate(Sender->Text);
   aCal->Width = Sender->Width;
   aCal->Height = Sender->Width;
   aCal->OnKeyDown = ISCalendarKeyDown;
   aCal->FixedStyle = dsRaised;
   aCal->TodayStyle = dsSunken;
   aCal->CalendarStyle = dsRaised;
   aCal->SelectedStyle = dsSunken;;

   DropDown->Styles  << ddsSizeToControlSize;
 }
 else if (aColumn->ColumnField == "EMPLOYEEID")
 {
   DropDownCtl = DropdownFP;
   DropDownCtl->Width = DBFP1->Width - Sender->Left;
   DropDownCtl->Height = DBFP1->Height - Sender->Top;
   DropdownFP->Parent = NULL;
   DropdownFP->ParentWindow = DropDown->Handle;
   DropDownCtl->Visible = true;
 }

}
//---------------------------------------------------------------------------

void __fastcall TForm1::ISCalendarKeyDown(TObject *Sender, WORD &Key,
      TShiftState Shift)
{
 if (Key == VK_RETURN || Key == VK_ESCAPE)
 {
  DBFP1->CloseUp(Key == VK_RETURN);
 }
 //        
}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP1CloseUp(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *DropDown, bool &Accept)
{
 TDBTreeColumn* aColumn;

 aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[DBFP1->Col];
 if ((aColumn->ColumnField == "ORDERDATE") && Accept)
 {
   TISCalendar* aCal = (TISCalendar *)DropDown->ContainedControl;
   Sender->Text = DateToStr(aCal->Date);
   aCal->~TISCalendar();
 }
 else if (aColumn->ColumnField == "EMPLOYEEID")
 {
   DropdownFP->DataSource = NULL; //disconnect
   DropdownFP->Parent = Form1;
   DropdownFP->SendToBack();
   DropdownFP->Visible = false;

 }

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP1ButtonPress(TISPlugInplaceEdit *Sender,
      TPressedButtons Button)
{

 TDBTreeColumn* aColumn = (TDBTreeColumn *)DBFP1->Columns->VisibleColumn[DBFP1->Col];
 if (aColumn->ColumnField == "EMPLOYEEID")
 {
    AnsiString aEmpID = DBFP1->Selected->Cells[DBFP1->Col];
    Details->Filtered = false;
    Details->Filter = "[EMPLOYEEID]=" + aEmpID;
    Details->Filtered = true;
    Sender->DropDown();
 }

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DropdownFPKeyDown(TObject *Sender, WORD &Key,
      TShiftState Shift)
{
  if (Key == VK_RETURN || Key == VK_ESCAPE)
  {
   if (PageControl1->ActivePage == TabSheet1)
   {
     DBFP1->CloseUp(false);
   }
   else
   {
     DBFP2->CloseUp(false);
   }
  }

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP2ButtonPress(TISPlugInplaceEdit *Sender,
      TPressedButtons Button)
{
    AnsiString aEmpID = DBFP2->Selected->Cells[DBFP2->Col];
    Details->Filtered = false;
    Details->Filter = "[EMPLOYEEID]=" + aEmpID;
    Details->Filtered = true;
    Sender->DropDown();

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP2GetDropdownControl(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *DropDown,
      TWinControl *&DropDownCtl)
{
   DropDownCtl = DropdownFP;
   DropDownCtl->Width = DBFP2->Width - Sender->Left;
   DropDownCtl->Height = DBFP2->Height - Sender->Top;
   DropdownFP->Parent = NULL;
   DropdownFP->ParentWindow = DropDown->Handle;
   DropDownCtl->Visible = true;

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP2CloseUp(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *DropDown, bool &Accept)
{
   DropdownFP->DataSource = NULL; //disconnect
   DropdownFP->Parent = Form1;
   DropdownFP->SendToBack();
   DropdownFP->Visible = false;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP2PrepareDropDown(TISPlugInplaceEdit *Sender,
      TISPlugSection *Section, TISDropDown *Dropdown)
{
  Dropdown->Styles << ddsOK << ddsSizeToControlSize;//adjust dropdown size to control size
  DropdownFP->DataSource = DetailsDS; //connect

}
//---------------------------------------------------------------------------

void __fastcall TForm1::DBFP2ValidateNodeData(TFlyNode *Node, int Column,
      AnsiString &aData, bool &Cancel)
{
  Cancel = true; //prevent from input
}
//---------------------------------------------------------------------------


