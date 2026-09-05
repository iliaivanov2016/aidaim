unit uFind;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, DBCtrls, Grids, DBGrids, DB, ExtCtrls, StdCtrls,
  MsgComBase, MsgTypes, MsgConst, MsgClient;

type
  TfmFind = class(TForm)
    Panel1: TPanel;
    bnFind: TButton;
    bnAdd: TButton;
    bnCancel: TButton;
    Panel2: TPanel;
    gbUsers: TGroupBox;
    sgUsers: TStringGrid;
    Panel3: TPanel;
    gbSearchConditions: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    eUserID: TEdit;
    eUserName: TEdit;
    cbName: TComboBox;
    chbUserName: TCheckBox;
    rgStatus: TRadioGroup;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    eContactCustomName: TEdit;
    rgContactNameSource: TRadioGroup;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnCancelClick(Sender: TObject);
    procedure bnAddClick(Sender: TObject);
    procedure bnFindClick(Sender: TObject);
    procedure sgUsersDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure sgUsersSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FClose: Boolean;
  public
    { Public declarations }
  end;

var
  fmFind: TfmFind;

implementation

uses uMain;

{$R *.dfm}

procedure TfmFind.FormShow(Sender: TObject);
var i: Integer;
begin
 FClose := True;
 gbUsers.Caption := ' Users found: 0 ';
 ModalResult := mrCancel;
 sgUsers.ColCount := 12;
 sgUsers.RowCount := 2;
 sgUsers.FixedRows := 1;
 sgUsers.Cells[0,0] := 'Sel.';
 sgUsers.ColWidths[0] := sgUsers.DefaultRowHeight;
 sgUsers.Cells[1,0] := 'Status';
 sgUsers.ColWidths[1] := 50;
 sgUsers.Cells[2,0] := 'UserID';
 sgUsers.ColWidths[2] := 50;
 sgUsers.Cells[3,0] := 'UserName';
 sgUsers.ColWidths[3] := 70;
 sgUsers.Cells[4,0] := 'FirstName';
 sgUsers.ColWidths[4] := 70;
 sgUsers.Cells[5,0] := 'LastName';
 sgUsers.ColWidths[5] := 70;
 sgUsers.Cells[6,0] := 'Organization';
 sgUsers.ColWidths[6] := 70;
 sgUsers.Cells[7,0] := 'Department';
 sgUsers.ColWidths[7] := 70;
 sgUsers.Cells[8,0] := 'Application';
 sgUsers.ColWidths[8] := 150;
 sgUsers.Cells[9,0] := 'Host';
 sgUsers.ColWidths[9] := 100;
 sgUsers.Cells[10,0] := 'Port';
 sgUsers.ColWidths[10] := 40;
 sgUsers.ColWidths[11] := 0;
 for i := 0 to sgUsers.ColCount-1 do
  sgUsers.Cells[i,1] := '';
end;

procedure TfmFind.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (not FClose) then
  Action := TCloseAction(caNone);
end;

procedure TfmFind.bnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  FClose := True;
end;

procedure TfmFind.bnAddClick(Sender: TObject);
var i:      Integer;
    UserID: Cardinal;
    Code:   Integer;
begin
  ModalResult := mrOk;
  FClose := True;
  for i := 1 to sgUsers.RowCount-1 do
   if (sgUsers.Cells[11,i] <> '') then
    begin
     try
       UserID := Cardinal(StrToInt(sgUsers.Cells[11,i]));
       Code := fmMain.MsgClient1.AddUserToContacts(UserID,TMsgContactNameSource(rgContactNameSource.ItemIndex),
        eContactCustomName.Text);
       if (Code <> MSG_COMMAND_OK) then
        begin
         ShowMessage('Cannot add selected user(s) to contact list. Error code = '+IntToStr(Code));
         FClose := False;
         exit;
        end;
     except
     end;
    end;
end;

procedure TfmFind.bnFindClick(Sender: TObject);
var
    Code:                    Integer;
    Users:                   TMsgUserInfoArray;
    UserNameComparison:      TMsgTextComparison;
    FirstNameComparison:     TMsgTextComparison;
    LastNameComparison:      TMsgTextComparison;
    OrganizationComparison:  TMsgTextComparison;
    DepartmentComparison:    TMsgTextComparison;
    ApplicationComparison:   TMsgTextComparison;
    HostComparison:          TMsgTextComparison;
    PortComparison:          TMsgIntegerComparison;
    Status:           TMsgUserStatus;
    UserID:           Cardinal;
    UserName:         ShortString;
    FirstName:        ShortString;
    LastName:         ShortString;
    Organization:     ShortString;
    Department:       ShortString;
    Host:             ShortString;
    Application:      ShortString;
    SearchCondition:  String;
    i: Integer;
    SortBy:           TMsgUserInfoArraySortBy;
    Ascending:        Boolean;
    OrderByClause:    String;
begin
 FClose := False;
 SearchCondition := '';
 OrderByClause := '';
 FillChar(UserNameComparison,SizeOf(UserNameComparison),$00);
 FillChar(FirstNameComparison,SizeOf(UserNameComparison),$00);
 FillChar(LastNameComparison,SizeOf(UserNameComparison),$00);
 FillChar(OrganizationComparison,SizeOf(UserNameComparison),$00);
 FillChar(DepartmentComparison,SizeOf(UserNameComparison),$00);
 FillChar(Application,SizeOf(UserNameComparison),$00);
 FillChar(HostComparison,SizeOf(UserNameComparison),$00);
 FillChar(PortComparison,SizeOf(PortComparison),$00);
 UserName := '';
 FirstName := '';
 LastName := '';
 Organization := '';
 Department := '';
 Host := '';
 Application := '';
 SearchCondition := '';
 OrderByClause := '';
 try
  if (eUserID.Text <> '') then
   UserID := StrToInt(eUserID.Text)
  else
   UserID := MSG_INVALID_USER_ID;
 except
  ShowMessage('Invalid UserID');
  Exit;
 end;
 if (rgStatus.ItemIndex = 1) then
  Status := msgOnLine
 else
 if (rgStatus.ItemIndex = 2) then
  Status := msgOffLine
 else
  Status := msgNone; // all users
 UserName := eUserName.Text;
 if (eUserName.Text <> '') then
  begin
   case (cbName.ItemIndex) of
    1: UserNameComparison.Comparison := mscmpStarts;
    2: UserNameComparison.Comparison := mscmpContains
   else
    UserNameComparison.Comparison := mscmpExact;
   end;
   UserNameComparison.CaseInsensitive := chbUserName.Checked;
  end;

 Ascending := True;
 SortBy := msgusbNone;
 Code := fmMain.MsgClient1.FindUsers(
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
                      SortBy,
                      Ascending,
                      OrderByClause
                      );
 if (code <> MSG_COMMAND_OK) then
  ShowMessage('Cannot find users. Error code = '+IntToStr(code))
 else
  begin
   gbUsers.Caption := ' Users found: '+IntToStr(Length(Users))+' ';
   sgUsers.RowCount := Length(Users)+1;
   if (Length(Users) <= 0) then
    begin
     sgUsers.RowCount := 2;
     for i := 0 to sgUsers.ColCount-1 do
      sgUsers.Cells[i,1] := '';
    end;
   for i := Low(Users) to High(Users) do
    begin
     case Users[i].Status of
      msgOnLine: sgUsers.Cells[1,i+1] := 'Online';
      msgOffLine: sgUsers.Cells[1,i+1] := 'Offline';
     else
      sgUsers.Cells[1,i+1] := '';
     end;
     sgUsers.Cells[2,i+1] := IntToStr(Integer(Users[i].UserID));
     sgUsers.Cells[3,i+1] := Users[i].UserName;
     sgUsers.Cells[4,i+1] := Users[i].FirstName;
     sgUsers.Cells[5,i+1] := Users[i].LastName;
     sgUsers.Cells[6,i+1] := Users[i].Organization;
     sgUsers.Cells[7,i+1] := Users[i].Department;
     sgUsers.Cells[8,i+1] := Users[i].Application;
     sgUsers.Cells[9,i+1] := Users[i].Host;
     sgUsers.Cells[10,i+1] := IntToStr(Users[i].Port);
     sgUsers.Cells[11,i+1] := '';
    end;
  end;
end;  // bnFindClick


procedure TfmFind.sgUsersDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var 
    col:  TColor;
    cnv:  TCanvas;
begin
 if (ARow >= 1) and (ARow < sgUsers.RowCount) then
  if (ACol = 0) then
   begin
    cnv := TStringGrid(Sender).Canvas;
    cnv.Brush.Color := clWindow;
    cnv.FillRect(Rect);
    if (sgUsers.Cells[11,ARow] <> '') then
     begin
       col := $00CC00;
       cnv.Brush.Color := col;
       cnv.Rectangle(Rect.Left+5,Rect.Top+5,Rect.Right-5,Rect.Bottom-5);
       cnv.FloodFill(Rect.Left+6,Rect.Top+6,col,fsSurface);
     end;
   end;
end;


procedure TfmFind.sgUsersSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
 if (ARow >= 1) and (ARow < sgUsers.RowCount) then
  if (ACol = 0) then
   begin
    if (sgUsers.Cells[2,ARow] = IntToStr(fmMain.MsgClient1.UserID)) then
     CanSelect := False
    else
     begin
      if (sgUsers.Cells[11,ARow] = '') then
       sgUsers.Cells[11,ARow] := sgUsers.Cells[2,ARow]
      else
       sgUsers.Cells[11,ARow] := '';
     end;
   end;
end;

procedure TfmFind.FormCreate(Sender: TObject);
begin
  cbName.ItemIndex := 0;
end;

end.
