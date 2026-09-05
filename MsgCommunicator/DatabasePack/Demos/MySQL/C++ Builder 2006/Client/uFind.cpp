//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "uFind.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "MsgClient"
#pragma link "MsgComBase"
#pragma link "MsgTypes"
#pragma resource "*.dfm"
TfmFind *fmFind;
//---------------------------------------------------------------------------
__fastcall TfmFind::TfmFind(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::FormShow(TObject *Sender)
{
 int i;
 FClose = true;
 gbUsers->Caption = " Users found: 0 ";
 ModalResult = mrCancel;
 sgUsers->ColCount = 12;
 sgUsers->RowCount = 2;
 sgUsers->FixedRows = 1;
 sgUsers->Cells[0][0] = "Sel->";
 sgUsers->ColWidths[0] = sgUsers->DefaultRowHeight;
 sgUsers->Cells[1][0] = "Status";
 sgUsers->ColWidths[1] = 50;
 sgUsers->Cells[2][0] = "UserID";
 sgUsers->ColWidths[2] = 50;
 sgUsers->Cells[3][0] = "UserName";
 sgUsers->ColWidths[3] = 70;
 sgUsers->Cells[4][0] = "FirstName";
 sgUsers->ColWidths[4] = 70;
 sgUsers->Cells[5][0] = "LastName";
 sgUsers->ColWidths[5] = 70;
 sgUsers->Cells[6][0] = "Organization";
 sgUsers->ColWidths[6] = 70;
 sgUsers->Cells[7][0] = "Department";
 sgUsers->ColWidths[7] = 70;
 sgUsers->Cells[8][0] = "Application";
 sgUsers->ColWidths[8] = 150;
 sgUsers->Cells[9][0] = "Host";
 sgUsers->ColWidths[9] = 100;
 sgUsers->Cells[10][0] = "Port";
 sgUsers->ColWidths[10] = 40;
 sgUsers->ColWidths[11] = 0;
 for (i = 0; i < sgUsers->ColCount; i++)
  sgUsers->Cells[i][1] = "";
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::FormClose(TObject *Sender, TCloseAction &Action)
{
 if (! FClose)
  Action = Forms::caNone;
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::bnCancelClick(TObject *Sender)
{
  ModalResult = mrCancel;
  FClose = true;
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::bnAddClick(TObject *Sender)
{
  int i,Code;
  unsigned int UserID;
  ModalResult = mrOk;
  FClose = true;
  for (i = 1; i < sgUsers->RowCount; i++)
   if (sgUsers->Cells[11][i] != "")
    {
     try
     {
       UserID = Cardinal(StrToInt(sgUsers->Cells[11][i]));
       Code = fmMain->MsgClient1->AddUserToContacts(UserID,TMsgContactNameSource(rgContactNameSource->ItemIndex),
        eContactCustomName->Text);
       if (Code != MSG_COMMAND_OK)
        {
         ShowMessage("Cannot add selected user(s) to contact list-> Error code = "+IntToStr(Code));
         FClose = false;
         return;
        }
     }
     catch (...){};
    }
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::bnFindClick(TObject *Sender)
{
  int Code, numUsers;
  TMsgUserInfoArray Users;
  TMsgTextComparison UserNameComparison;
  TMsgTextComparison FirstNameComparison;
  TMsgTextComparison LastNameComparison;
  TMsgTextComparison OrganizationComparison;
  TMsgTextComparison DepartmentComparison;
  TMsgTextComparison ApplicationComparison;
  TMsgTextComparison HostComparison;
  TMsgIntegerComparison PortComparison;
  TMsgUserStatus Status;
  unsigned int UserID;
  AnsiString UserName;
  AnsiString FirstName;
  AnsiString LastName;
  AnsiString Organization;
  AnsiString Department;
  AnsiString Host;
  AnsiString Application;
  AnsiString SearchCondition;
  AnsiString OrderByClause;
  TMsgUserInfoArraySortBy SortBy;
  int i;
  bool Ascending;

  FClose = false;
  SearchCondition = "";
  OrderByClause = "";
  memset(&UserNameComparison,0x00,sizeof(UserNameComparison));
  memset(&FirstNameComparison,0x00,sizeof(FirstNameComparison));
  memset(&LastNameComparison,0x00,sizeof(LastNameComparison));
  memset(&OrganizationComparison,0x00,sizeof(OrganizationComparison));
  memset(&DepartmentComparison,0x00,sizeof(DepartmentComparison));
  memset(&ApplicationComparison,0x00,sizeof(ApplicationComparison));
  memset(&HostComparison,0x00,sizeof(HostComparison));
  memset(&PortComparison,0x00,sizeof(PortComparison));
  memset(&Status,0x00,sizeof(TMsgUserStatus));
  UserName = "";
  FirstName = "";
  LastName = "";
  Organization = "";
  Department = "";
  Host = "";
  Application = "";
  SearchCondition = "";
  OrderByClause = "";
  try
  {
  if (eUserID->Text != "")
   UserID = StrToInt(eUserID->Text);
  else
   UserID = MSG_INVALID_USER_ID;
  }
  catch(...)
  {
   ShowMessage("Invalid UserID");
   return;
  }
  if (rgStatus->ItemIndex == 1)
   Status = msgOnLine;
  else
  if (rgStatus->ItemIndex == 2)
   Status = msgOffLine;
  else
   Status = msgNone; // all users
  UserName = eUserName->Text;
  if (eUserName->Text != "")
  {
   switch (cbName->ItemIndex)
   {
    case 1: UserNameComparison.Comparison = mscmpStarts; break;
    case 2: UserNameComparison.Comparison = mscmpContains; break;
    default: UserNameComparison.Comparison = mscmpExact;
   }
   UserNameComparison.CaseInsensitive = chbUserName->Checked;
  }

  Ascending = true;
  SortBy = msgusbNone;

  Code = fmMain->MsgClient1->FindUsersCPP(
                      Users,
                      UserNameComparison,FirstNameComparison,LastNameComparison,
                      OrganizationComparison,DepartmentComparison,
                      ApplicationComparison,HostComparison,PortComparison,
                      Status,UserID,
                      UserName,
                      FirstName,
                      LastName,
                      Organization,
                      Department,
                      Host,
                      Application,
                      SearchCondition,
                      (int)SortBy,
                      Ascending,
                      OrderByClause
                      );
/*
TMsgTextComparison tcmp;
TMsgIntegerComparison icmp;
Msgcombase::TMsgUserInfoArray u1;
  Code = fmMain->MsgClient1->FindUsersCPP(
                      u1,
                      tcmp,
                      tcmp,
                      tcmp,
                      tcmp,
                      tcmp,
                      tcmp,
                      tcmp,
                      icmp,
                      msgNone,
                      1,
                      "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      msgusbNone,
                      true,
                      ""
                      );
*/
  if (Code != MSG_COMMAND_OK)
    ShowMessage("Cannot find users-> Error code = "+IntToStr(Code));
  else
  {
   gbUsers->Caption = " Users found: "+IntToStr(Users.Length)+" ";
   sgUsers->RowCount = Users.Length+1;
   if (Users.Length <= 0)
    {
     sgUsers->RowCount = 2;
     for (i = 0; i < sgUsers->ColCount; i++)
      sgUsers->Cells[i][1] = "";
    }
   numUsers = Users.get_length();
   for (i = 0; i < numUsers; i++)
    {
     switch (Users[i].Status)
     {
      case msgOnLine:  sgUsers->Cells[1][i+1] = "Online"; break;
      case msgOffLine: sgUsers->Cells[1][i+1] = "Offline"; break;
      default:         sgUsers->Cells[1][i+1] = "";
     }
     sgUsers->Cells[2][i+1] = IntToStr(Integer(Users[i].UserID));
     sgUsers->Cells[3][i+1] = Users[i].UserName;
     sgUsers->Cells[4][i+1] = Users[i].FirstName;
     sgUsers->Cells[5][i+1] = Users[i].LastName;
     sgUsers->Cells[6][i+1] = Users[i].Organization;
     sgUsers->Cells[7][i+1] = Users[i].Department;
     sgUsers->Cells[8][i+1] = Users[i].Application;
     sgUsers->Cells[9][i+1] = Users[i].Host;
     sgUsers->Cells[10][i+1] = IntToStr(Users[i].Port);
     sgUsers->Cells[11][i+1] = "";
    }
  }
}

//---------------------------------------------------------------------------
void __fastcall TfmFind::sgUsersDrawCell(TObject *Sender, int ACol,
      int ARow, TRect &Rect, TGridDrawState State)
{
 TColor col;
 TCanvas *cnv;

 if ((ARow >= 1) && (ARow < sgUsers->RowCount))
  if (ACol == 0)
   {
    cnv = ((TStringGrid *)Sender)->Canvas;
    cnv->Brush->Color = clWindow;
    cnv->FillRect(Rect);
    if (sgUsers->Cells[11][ARow] != "")
     {
       col = (TColor)0x00CC00;
       cnv->Brush->Color = col;
       cnv->Rectangle(Rect.Left+5,Rect.Top+5,Rect.Right-5,Rect.Bottom-5);
       cnv->FloodFill(Rect.Left+6,Rect.Top+6,col,fsSurface);
     }
   }
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::sgUsersSelectCell(TObject *Sender, int ACol,
      int ARow, bool &CanSelect)
{
if ((ARow >= 1) && (ARow < sgUsers->RowCount)) 
  if (ACol == 0)
   {
    if (sgUsers->Cells[2][ARow] == IntToStr(fmMain->MsgClient1->UserID))
     CanSelect = false;
    else
     {
      if (sgUsers->Cells[11][ARow] == "")
       sgUsers->Cells[11][ARow] = sgUsers->Cells[2][ARow];
      else
       sgUsers->Cells[11][ARow] = "";
     }
   }
}
//---------------------------------------------------------------------------
void __fastcall TfmFind::FormCreate(TObject *Sender)
{
  cbName->ItemIndex = 0;
}
//---------------------------------------------------------------------------




