//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "Main.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::CreateTableWithData()
{
 ACRTable1->FieldDefs->Clear();
 ACRTable1->FieldDefs->Add("ID",ftAutoInc,0,false);
 ACRTable1->FieldDefs->Add("Name",ftString,100,false);
 ACRTable1->FieldDefs->Add("Surname",ftString,100,false);
 ACRTable1->FieldDefs->Add("Comments",ftMemo,1000,false);
 ACRTable1->IndexDefs->Clear();
 ACRTable1->IndexDefs->Add("idx_id","ID",TIndexOptions() << ixUnique);
 ACRTable1->CreateTable();
 ACRTable1->Open();

 ACRTable1->Insert();
 ACRTable1->FieldByName("Name")->AsString = "Leo";
 ACRTable1->FieldByName("Surname")->AsString = "Martin";
 ACRTable1->FieldByName("Comments")->AsString = "Company: AidAim Software LLC \nPosition: Lead Developer";
 ACRTable1->Post();

 ACRTable1->Insert();
 ACRTable1->FieldByName("Name")->AsString = "Ella";
 ACRTable1->FieldByName("Surname")->AsString = "Perelman";
 ACRTable1->FieldByName("Comments")->AsString = "Company: AidAim Software LLC \nPosition: Sales Manager";
 ACRTable1->Post();

 ACRTable1->Insert();
 ACRTable1->FieldByName("Name")->AsString = "Gordon";
 ACRTable1->FieldByName("Surname")->AsString = "Freeman";
 ACRTable1->FieldByName("Comments")->AsString = "Company: AidAim Software LLC \nPosition: Developer";
 ACRTable1->Post();

 ACRTable1->First();
}
void __fastcall TForm1::btnCreateUsingPasswordClick(TObject *Sender)
{
 ACRDatabase1->Close();

 if (ACRDatabase1->Exists)
  {ACRDatabase1->DeleteDatabase();};
 // simple encryption - just set password and algorithm
 // also you can set InitVector and UseInitVector but it is not necessary
 ACRDatabase1->CryptoParams->Password = "password";
 ACRDatabase1->CryptoParams->CryptoAlgorithm = craRijndael_256;
 ACRDatabase1->CreateDatabase();

 // notice: you need to set only ACRDatabase1->CryptoParams->Password property
 // before opening the database file
 ACRDatabase1->CryptoParams->Password = "password";
 ACRDatabase1->Open();
 CreateTableWithData();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::bnCreateUsingKeyClick(TObject *Sender)
{
 ACRDatabase1->Close();
 if (ACRDatabase1->Exists)
  {ACRDatabase1->DeleteDatabase();};

 // more advanced encryption - allows to set any encryption parameters
 ACRDatabase1->CryptoParams->CryptoAlgorithm = craRijndael_256;
 ACRDatabase1->CryptoParams->CryptoMode = acmCBC;

 // 256 bits random key generated using Linear Feedback Shift Register
 ACRDatabase1->CryptoParams->MakeRandomKey(32);

 // make random init vector
 ACRDatabase1->CryptoParams->MakeRandomInitVector();
 ACRDatabase1->CryptoParams->UseInitVector = True;
 ACRDatabase1->CreateDatabase();


 // you should set right Key and InitVector before opening the database
 ACRDatabase1->Open();
 CreateTableWithData();        
}
//---------------------------------------------------------------------------
void __fastcall TForm1::btnCloseClick(TObject *Sender)
{
 ACRDatabase1->Connected = False;
 Close();
 Application->Terminate();
}
//---------------------------------------------------------------------------
