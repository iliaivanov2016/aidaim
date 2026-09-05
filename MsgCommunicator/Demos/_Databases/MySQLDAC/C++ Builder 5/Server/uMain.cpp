//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uMain.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "MsgComBase"
#pragma link "MsgDatabase"
#pragma link "MsgDatabaseTempTableSQLMemTable"
#pragma link "MsgDatabaseMySQLDAC"
#pragma link "mySQLDbTables"
#pragma link "MsgServer"
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
  LocalPort->Text = IntToStr(MsgServer1->ConnectionParams->LocalPort);
  // grids headers
  sgConnectedUsers->ColCount = 4;
  sgConnectedUsers->RowCount = 1;
  sgConnectedUsers->ColWidths[0] = 20;
  sgConnectedUsers->ColWidths[2] = 60;
  sgConnectedUsers->ColWidths[3] = 40;
  sgConnectedUsers->ColWidths[1] = sgConnectedUsers->ClientWidth -
                          sgConnectedUsers->ColWidths[3] -
                          sgConnectedUsers->ColWidths[2] -
                          sgConnectedUsers->ColWidths[0];
  sgConnectedUsers->Cells[0][0] = "ID";
  sgConnectedUsers->Cells[1][0] = "Name";
  sgConnectedUsers->Cells[2][0] = "Host";
  sgConnectedUsers->Cells[3][0] = "Port";
  sgAllUsers->ColCount = 6;
  sgAllUsers->RowCount = 1;
  sgAllUsers->ColWidths[0] = 10;
  sgAllUsers->ColWidths[1] = 40;
  sgAllUsers->ColWidths[3] = 40;
  sgAllUsers->ColWidths[4] = 60;
  sgAllUsers->ColWidths[5] = 40;
  sgAllUsers->ColWidths[2] = sgAllUsers->ClientWidth-
                          sgAllUsers->ColWidths[0] -
                          sgAllUsers->ColWidths[1] -
                          sgAllUsers->ColWidths[3] -
                          sgAllUsers->ColWidths[4] -
                          sgAllUsers->ColWidths[5];
  sgAllUsers->Cells[0][0] = "?";
  sgAllUsers->Cells[1][0] = "ID";
  sgAllUsers->Cells[2][0] = "Name";
  sgAllUsers->Cells[3][0] = "Dept";
  sgAllUsers->Cells[4][0] = "Host";
  sgAllUsers->Cells[5][0] = "Port";
// start server
  ServerStartClick(Sender);
  ServerIncoming->Lines->Add(""); // work around bug with the first add
  ServerIncoming->Lines->Clear();   // work around bug with the first add
  FillGrids();
  Pages->ActivePage = Users;  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FormClose(TObject *Sender, TCloseAction &Action)
{
  MsgServer1->Active = false;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::FillGrids()
{
  TMsgUserInfoArray Users;
  TMsgClientInfoArray Clients;
  int i,na,nc;
  AnsiString id1,id2;
  TGridRect gr1,gr2;
  int numUsers, numClients;
  try
  {
    MsgServer1->GetUsers(Users,msgusbNone,true);
    MsgServer1->GetClients(Clients);
    id1 = ServerToID->Text;
    id2 = SelectedUserID->Text;
    gr1 = sgConnectedUsers->Selection;
    gr2 = sgAllUsers->Selection;
    try
    {
      ClearGrid(sgAllUsers);
      ClearGrid(sgConnectedUsers);
      na = 0;
      nc = 0;
      numUsers = Users.get_length();
      for (i = 0; i < numUsers; i++)
       {
        if (Users[i].Status == msgOnLine) 
         {
          nc++;
          if (nc >= sgConnectedUsers->RowCount) 
           sgConnectedUsers->RowCount = nc+1;
          sgConnectedUsers->Cells[0][nc] = IntToStr(Users[i].UserID);
          sgConnectedUsers->Cells[1][nc] = Users[i].UserName;
          sgConnectedUsers->Cells[3][nc] = Users[i].Host;
          sgConnectedUsers->Cells[4][nc] = IntToStr(Users[i].Port);
         }
        na++;
        if (na >= sgAllUsers->RowCount)
         sgAllUsers->RowCount = na+1;
        if (Users[i].Status == msgOnLine)
         sgAllUsers->Cells[0][na] = "+";
        else
         sgAllUsers->Cells[0][na] = "-";
        sgAllUsers->Cells[1][na] = IntToStr(Users[i].UserID);
        sgAllUsers->Cells[2][na] = Users[i].UserName;
        sgAllUsers->Cells[3][na] = Users[i].Department;
        sgAllUsers->Cells[4][na] = Users[i].Host;
        sgAllUsers->Cells[5][na] = IntToStr(Users[i].Port);
       }
      numClients = Clients.get_length();
      for (i = 0; i < numClients; i++)
       if (Clients[i].UserID == MSG_INVALID_USER_ID)
        {
          nc++;
          if (nc >= sgConnectedUsers->RowCount)
           sgConnectedUsers->RowCount = nc+1;
          sgConnectedUsers->Cells[0][nc] = IntToStr(MSG_INVALID_USER_ID);
          sgConnectedUsers->Cells[1][nc] = Guest;
          sgConnectedUsers->Cells[3][nc] = Clients[i].Host;
          sgConnectedUsers->Cells[4][nc] = IntToStr(Clients[i].Port);
          na++;
          if (na >= sgAllUsers->RowCount)
           sgAllUsers->RowCount = na+1;
          sgAllUsers->Cells[0][na] = "+";
          sgAllUsers->Cells[1][na] = IntToStr(MSG_INVALID_USER_ID);
          sgAllUsers->Cells[2][na] = Guest;
          sgAllUsers->Cells[3][na] = "";
          sgAllUsers->Cells[4][na] = Clients[i].Host;
          sgAllUsers->Cells[5][na] = IntToStr(Clients[i].Port);
        }
     for (i = 1; i < sgAllUsers->RowCount; i++)
      if (sgAllUsers->Cells[1][i] == id2)
       {
        gr2.Top = i;
        gr2.Bottom = i;
        sgAllUsers->Selection = gr2;
        SelectedUserID->Text = id2;
        break;
       }
     for (i = 1; i < sgConnectedUsers->RowCount; i++)
      if (sgConnectedUsers->Cells[0][i] == id1)
       {
        gr1.Top = i;
        gr1.Bottom = i;
        sgConnectedUsers->Selection = gr1;
        ServerToID->Text = id1;
        break;
       }
    }
    __finally {};
  }
  catch (...) {};
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::ClearGrid(TStringGrid *Grid)
{
  int i;
  Grid->RowCount = 2;
  Grid->FixedRows = 1;
  for (i = 0; i < Grid->ColCount; i++)
   Grid->Cells[i][1] = "";
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::ServerStartClick(TObject *Sender)
{
  MsgServer1->ConnectionParams->LocalPort = StrToInt(LocalPort->Text);
// start server
  MsgServer1->Active = true;
// show LocalPort
  LocalPort->Text = IntToStr(MsgServer1->ConnectionParams->LocalPort);
// disable/enable buttons
  LocalPort->Enabled = false;
  ServerStart->Enabled = false;
  ServerStop->Enabled = true;
  DisconnectUser->Enabled = false;
  DeleteUser->Enabled = false;  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::ServerStopClick(TObject *Sender)
{
// stop server
  MsgServer1->Active = false;
// disable/enable buttons
  LocalPort->Enabled = true;
  LocalPort->Text = IntToStr(MsgServer1->ConnectionParams->LocalPort);
  ServerStart->Enabled = true;
  ServerStop->Enabled = false;
  DisconnectUser->Enabled = false;
  DeleteUser->Enabled = false;
// clear form
  ClearGrid(sgConnectedUsers);
  ClearGrid(sgAllUsers);
  ServerToID->Text = "";
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgServer1ReceiveTextMessage(
      const DWORD FromUserID, const TDateTime SendingDate,
      const TDateTime DeliveryDate, const AnsiString Text)
{
	AnsiString str;
	TMsgUserInfo UserInfo;
	str = "#" + IntToStr((int)FromUserID) + ", " + DateTimeToStr(SendingDate) + ":";
	try
	{
	 UserInfo = MsgServer1->GetUserInfo(FromUserID);
	 if (UserInfo.UserID != MSG_INVALID_USER_ID)
		str = (AnsiString)UserInfo.UserName + " " + str;
	}
	catch (...)
	{
		str = "Unregistered User ID = "+IntToStr((int)FromUserID)+" "+ str;
	}
//	ServerIncoming->Lines->Add(str);
//	ServerIncoming->Lines->Add(Text);
	str = str+(AnsiString)"\r\n"+Text;
	TServerDisplayThread *sdt = new TServerDisplayThread(str);
	sdt->Resume();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::ServerSendClick(TObject *Sender)
{
  AnsiString str;
  TMsgUserInfo UserInfo;

  if (ServerToID->Text == "")
    return;
  MsgServer1->SendMessage(Cardinal(StrToInt(ServerToID->Text)), ServerMsg->Text);
  str = "#" + ServerToID->Text + ", " + TimeToStr(Time()) + ":";
  UserInfo = MsgServer1->GetUserInfo(StrToInt(ServerToID->Text));
  if ((AnsiString)UserInfo.UserName != "")
    str = (AnsiString)UserInfo.UserName + " " + str;
  ServerSent->Lines->Add(str);
  ServerSent->Lines->Add(ServerMsg->Text);
  ServerMsg->Text = "";  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::sgAllUsersSelectCell(TObject *Sender, int ACol,
      int ARow, bool &CanSelect)
{
  TMsgUserInfo UserInfo;
  if ((ARow <= 0) || (ARow >= sgAllUsers->RowCount))
    return;
  SelectedUserID->Text = "";
  if (sgAllUsers->Cells[1][ARow] != "")
   {
    SelectedUserID->Text = sgAllUsers->Cells[1][ARow];
    DisconnectUser->Enabled = (sgAllUsers->Cells[0][ARow] == "+");
    if (sgAllUsers->Cells[1][ARow] != IntToStr(MSG_INVALID_USER_ID))
     DeleteUser->Enabled = true;
    else
     {
      DisconnectUser->Enabled = false;
      DeleteUser->Enabled = false;
     }
   }
  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::sgConnectedUsersSelectCell(TObject *Sender,
      int ACol, int ARow, bool &CanSelect)
{
  TMsgUserInfo UserInfo;
  if ((ARow <= 0) || (ARow >= sgConnectedUsers->RowCount))
    return;
  ServerToID->Text = "";
  if (sgConnectedUsers->Cells[0][ARow] != "") 
   {
    if (sgConnectedUsers->Cells[0][ARow] != IntToStr(MSG_INVALID_USER_ID)) 
     {
       ServerSend->Enabled = true;
       ServerToID->Text = sgConnectedUsers->Cells[0][ARow];
     }
    else
     {
       ServerSend->Enabled = false;
     }
   }
  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgServer1BeforeDisconnect(TObject *Sender)
{
  ServerToID->Text = "";  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::DisconnectUserClick(TObject *Sender)
{
  MsgServer1->DisconnectUser(Cardinal(StrToInt(SelectedUserID->Text)));
  DisconnectUser->Enabled = false;
  DeleteUser->Enabled = true;
  FillGrids();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::DeleteUserClick(TObject *Sender)
{
  unsigned int UID;
  UID = (unsigned int)StrToInt(SelectedUserID->Text);
  if (MsgServer1->IsUserConnected(UID))
    MsgServer1->DisconnectUser(StrToInt(SelectedUserID->Text));
  if (MsgServer1->IsUserExisting(UID))
    MsgServer1->DeleteUser(UID);
  DeleteUser->Enabled = false;
  DisconnectUser->Enabled = false;
  FillGrids();
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::Timer1Timer(TObject *Sender)
{
 FillGrids();  
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgServer1AfterServerStart(TObject *Sender)
{
  Timer1->Enabled = true;
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::MsgServer1AfterServerStop(TObject *Sender)
{
  Timer1->Enabled = false;
}
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// TServer display thread
//---------------------------------------------------------------------------
__fastcall TServerDisplayThread::TServerDisplayThread(AnsiString text) : TThread(true)
{
  FText = text;
  FUnicodeText = "";
}
//---------------------------------------------------------------------------
__fastcall TServerDisplayThread::TServerDisplayThread(WideString text) : TThread(true)
{
	FText = "";
	FUnicodeText = text;
}
//---------------------------------------------------------------------------
void __fastcall TServerDisplayThread::DisplayMessage()
{
	if (FText == "")
	 fmMain->ServerIncoming->Lines->Add(FUnicodeText);
	else
	 fmMain->ServerIncoming->Lines->Add(FText);
}
//---------------------------------------------------------------------------
void __fastcall TServerDisplayThread::Execute()
{
	TThreadMethod tm = &DisplayMessage;
	Synchronize(tm);
	//Synchronize(DisplayMessage);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::MsgServer1ReceiveUnicodeTextMessage(
      const DWORD FromUserID, const TDateTime SendingDate,
      const TDateTime DeliveryDate, const WideString Text)
{
 WideString str;
 TMsgUserInfo UserInfo;
	str = "#" + IntToStr((int)FromUserID) + ", " + DateTimeToStr(SendingDate) + ":";
	try
	{
	 UserInfo = MsgServer1->GetUserInfo(FromUserID);
	 if (UserInfo.UserID != MSG_INVALID_USER_ID)
		str = (AnsiString)UserInfo.UserName + " " + str;
	}
	catch (...)
	{
		str = "Unregistered User ID = "+IntToStr((int)FromUserID)+" "+ str;
	}
	str = str+(WideString)"\r\n"+Text;
	TServerDisplayThread *sdt = new TServerDisplayThread(str);
	sdt->Resume();
//	ServerIncoming->Lines->Add(str);
//	ServerIncoming->Lines->Add(Text);
}
//---------------------------------------------------------------------------

