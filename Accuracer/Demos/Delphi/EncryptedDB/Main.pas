unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, StdCtrls, Buttons, DBCtrls, Grids, DBGrids, ExtCtrls,
  ACRMain;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    DataSource1: TDataSource;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    btnCreateUsingPassword: TButton;
    btnClose: TButton;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    bnCreateUsingKey: TButton;

    procedure CreateTableWithData;

    procedure bnCreateClick(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure bnCreateUsingKeyClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.CreateTableWithData;
begin
 ACRTable1.FieldDefs.Clear;
 ACRTable1.FieldDefs.Add('ID',ftAutoInc);
 ACRTable1.FieldDefs.Add('Name',ftString,100);
 ACRTable1.FieldDefs.Add('Surname',ftString,100);
 ACRTable1.FieldDefs.Add('Comments',ftMemo);
 ACRTable1.IndexDefs.Clear;
 ACRTable1.IndexDefs.Add('idx_id','ID',[ixUnique]);
 ACRTable1.CreateTable;
 ACRTable1.Open;

 ACRTable1.Insert;
 ACRTable1.FieldByName('Name').AsString := 'Leo';
 ACRTable1.FieldByName('Surname').AsString := 'Martin';
 ACRTable1.FieldByName('Comments').AsString := 'Company: AidAim Software LLC'#13#10+'Position: Lead Developer';
 ACRTable1.Post;

 ACRTable1.Insert;
 ACRTable1.FieldByName('Name').AsString := 'Ella';
 ACRTable1.FieldByName('Surname').AsString := 'Perelman';
 ACRTable1.FieldByName('Comments').AsString := 'Company: AidAim Software LLC'#13#10+'Position: Sales Manager';
 ACRTable1.Post;

 ACRTable1.Insert;
 ACRTable1.FieldByName('Name').AsString := 'Gordon';
 ACRTable1.FieldByName('Surname').AsString := 'Freeman';
 ACRTable1.FieldByName('Comments').AsString := 'Company: AidAim Software LLC'#13#10+'Position: Developer';
 ACRTable1.Post;

 ACRTable1.First;
end;

procedure TForm1.bnCreateClick(Sender: TObject);
begin
 ACRDatabase1.Close;

 if (ACRDatabase1.Exists) then
  ACRDatabase1.DeleteDatabase;
 // simple encryption - just set password and algorithm
 // also you can set InitVector and UseInitVector but it is not necessary
 ACRDatabase1.CryptoParams.Password := 'password';
 ACRDatabase1.CryptoParams.CryptoAlgorithm := craRijndael_256;
 ACRDatabase1.CreateDatabase;

 // notice: you need to set only ACRDatabase1.CryptoParams.Password property
 // before opening the database file
 ACRDatabase1.CryptoParams.Password := 'password';
 ACRDatabase1.Open;
 CreateTableWithData;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var pass: string;
    f:		Boolean;
begin
 ACRDatabase1.Close;
 ACRDatabase1.Open;
 ACRTable1.Active := true;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
 ACRDatabase1.Connected := False;
 Close;
 Application.Terminate;
end;


procedure TForm1.bnCreateUsingKeyClick(Sender: TObject);
begin
 ACRDatabase1.Close;
 if (ACRDatabase1.Exists) then
  ACRDatabase1.DeleteDatabase;

 // more advanced encryption - allows to set any encryption parameters
 ACRDatabase1.CryptoParams.CryptoAlgorithm := craRijndael_256;
 ACRDatabase1.CryptoParams.CryptoMode := acmCBC;

 // 256 bits random key generated using Linear Feedback Shift Register
 ACRDatabase1.CryptoParams.MakeRandomKey(32);

 // make random init vector
 ACRDatabase1.CryptoParams.MakeRandomInitVector;
 ACRDatabase1.CryptoParams.UseInitVector := True;
 ACRDatabase1.CreateDatabase;


 // you should set right Key and InitVector before opening the database
 ACRDatabase1.Open;
 CreateTableWithData;
end;

end.
