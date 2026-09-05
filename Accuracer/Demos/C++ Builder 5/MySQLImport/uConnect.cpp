//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "uConnect.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TConnectDlg *ConnectDlg;
//---------------------------------------------------------------------------
__fastcall TConnectDlg::TConnectDlg(TComponent* Owner)
        : TForm(Owner)
{
}
bool __fastcall ShowConnectDlg(TmySQLDatabase *Db)
{
 bool res;
 ConnectDlg =  new TConnectDlg(Application);
 ConnectDlg->Database = Db;
 res = ConnectDlg->Edit();
 delete ConnectDlg;
 return res;
}

bool __fastcall TConnectDlg::Edit()
{
  bool res;
  GetDatabaseProperty(Database);
  res = false;
  if (ShowModal() == mrOk)
  {
    SetDatabaseProperty(Database);
    res = true;
  }
 return res;
}

//---------------------------------------------------------------------------
void __fastcall TConnectDlg::GetDatabaseProperty(TmySQLDatabase *Db)
{
  DBName->Text = Db->DatabaseName;
  DBUserID->Text = Db->UserName;
  DBPasswd->Text = Db->UserPassword;
  DBHost->Text = Db->Host;
  DBPort->Text = IntToStr(Db->Port);
}

void __fastcall TConnectDlg::SetDatabaseProperty(TmySQLDatabase *Db)
{
  Db->DatabaseName = DBName->Text;
  Db->UserName = DBUserID->Text;
  Db->UserPassword = DBPasswd->Text;
  Db->Host = DBHost->Text;
  Db->Port = StrToInt(DBPort->Text);
}
//---------------------------------------------------------------------------
