//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "ACRMain"
#pragma resource "*.dfm"
TfmMain *fmMain;
//---------------------------------------------------------------------------
__fastcall TfmMain::TfmMain(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormCreate(TObject *Sender)
{
 edDBName->Text = ACRDefaultDBName;
 edRemoteHost->Text = ACRDefaultHost;
 edRemotePort->Text = IntToStr(ACRDefaultServerPort);
 edLocalPort->Text = IntToStr(ACRDefaultClientPort);
 bnConnect->Enabled = true;
 bnDisconnect->Enabled = false;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnConnectClick(TObject *Sender)
{
 ACRDatabase1->Close();
 ACRDatabase1->ConnectionParams->DatabaseName = edDBName->Text;
 ACRDatabase1->ConnectionParams->RemoteHost = edRemoteHost->Text;
 ACRDatabase1->ConnectionParams->RemotePort = StrToInt(edRemotePort->Text);
 ACRDatabase1->ConnectionParams->LocalPort = StrToInt(edLocalPort->Text);
 try
 {
   ACRDatabase1->Open();
 }
 catch (const Exception &E)
 {
     MessageDlg("Error connecting to a remote database server: \r\n"+E.Message,mtError,TMsgDlgButtons()<<mbOK,0);
     ACRDatabase1->Close();
     return;
 };
 try
 {
   ACRDatabase1->GetTablesList(lbTables->Items);
   gbTables->Caption = " Available tables: "+IntToStr(lbTables->Items->Count);
 }
 catch (const Exception &E)
 {
     MessageDlg("Error retrieving tables list: \r\n"+E.Message,mtError,TMsgDlgButtons()<<mbOK,0);
     ACRDatabase1->Close();
     return;
 };
 bnConnect->Enabled = false;
 bnDisconnect->Enabled = true;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::bnDisconnectClick(TObject *Sender)
{
 try
 {
   ACRDatabase1->Close();
 }
 catch (const Exception &E)
 {
  MessageDlg("Error disconnecting from a remote database server: \r\n"+E.Message,mtError,TMsgDlgButtons()<<mbOK,0);
  return;
 };
 bnConnect->Enabled = true;
 bnDisconnect->Enabled = false;
 lbTables->Items->Clear();
 gbTables->Caption = " Available tables: ";
 gbRecords->Caption = " Record Count: ";
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::lbTablesDblClick(TObject *Sender)
{
 if (lbTables->ItemIndex >= 0)
  {
   ACRTable1->Close();
   ACRTable1->TableName = lbTables->Items->Strings[lbTables->ItemIndex];
   try
   {
     ACRTable1->Open();
   }
   catch (const Exception &E)
   {
     MessageDlg("Error opening table """+ACRTable1->TableName+ """ from a remote database server: \r\n"+E.Message,mtError,TMsgDlgButtons()<<mbOK,0);
     ACRTable1->Close();
     return;
   };
   gbRecords->Caption = " Record Count: "+IntToStr(ACRTable1->RecordCount);
  }
}
//---------------------------------------------------------------------------
