unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ACRMain, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids, ACRConst, ACRExcept;

type
  TForm1 = class(TForm)
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ACRTable1PostError(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
 if (not ACRDatabase1.Exists) then
  begin
   ACRDatabase1.CreateDatabase;
   ACRDatabase1.Open;
   ACRTable1.FieldDefs.Clear;
   ACRTable1.AdvFieldDefs.Clear;
   ACRTable1.IndexDefs.Clear;
   ACRTable1.ForeignKeyDefs.Clear;
   ACRTable1.FieldDefs.Add('id',ftInteger);
   ACRTable1.FieldDefs.Add('name',ftString,25,true);
   ACRTable1.IndexDefs.Add('PK','id',[ixPrimary]);
   ACRTable1.CreateTable;
   ACRTable1.Open;
   ACRTable1.AppendRecord([1,'Leo']);
   ACRTable1.AppendRecord([2,'Ray']);
  end
 else
  begin
   ACRDatabase1.Open;
   ACRTable1.Open;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  erCode: Integer;
begin
 try
    ACRTable1.Insert;
    ACRTable1.FieldByName('id').AsInteger := 1;
    ACRTable1.FieldByName('name').AsString := 'Test';
    ACRTable1.Post;
  except
    on E:Exception do begin
      erCode := ACRTable1.Handle.ErrorCode;
      ACRTable1.Cancel;
      case (erCode) of
        ACR_ERR_CONSTRAINT_VIOLATED : ShowMessage('Constraint violated');
        ACR_ERR_INSERT_RECORD            : ShowMessage('Insert failed');
        ACR_ERR_UPDATE_RECORD          : ShowMessage('Update failed');
      else
        ShowMessage('Unknown error: '+e.Message);
      end;
    end;
  end;
end;

{
 // error codes

 const ACR_ERR_OK = 0;
 const ACR_ERR_INSERT_RECORD = -1;
 const ACR_ERR_UPDATE_RECORD = -2;
 const ACR_ERR_DELETE_RECORD = -3;
 const ACR_ERR_UPDATE_RECORD_MODIFIED = -4;
 const ACR_ERR_DELETE_RECORD_MODIFIED = -5;
 const ACR_ERR_UPDATE_RECORD_DELETED = -6;
 const ACR_ERR_DELETE_RECORD_DELETED = -7;

 const ACR_ERR_CONSTRAINT_VIOLATED = -8;
 const ACR_ERR_UPDATE_RECORD_PROHIBITED = -9;
 const ACR_ERR_DELETE_RECORD_PROHIBITED = -10;
 const ACR_ERR_CANCEL_PROHIBITED = -11;
 const ACR_ERR_DELETE_RECORD_PROHIBITED_BY_FK_VIOLATION = -12;
 const ACR_ERR_UPDATE_RECORD_PROHIBITED_BY_FK_VIOLATION = -13;
}

procedure TForm1.ACRTable1PostError(DataSet: TDataSet; E: EDatabaseError;
  var Action: TDataAction);
begin
 Action := daAbort;
 Dataset.Cancel;
 if (Pos('30319',e.Message) > 0) then
  ShowMessage('Constraint primary key violated - id value should be unique')
 else
 if (Pos('30026',e.Message) > 0) then
  ShowMessage('Constraint violated - name value should be not null')
 else
  ShowMessage('Error: '+e.Message);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    ACRTable1.Insert;
    ACRTable1.FieldByName('id').AsInteger := 1;
    ACRTable1.FieldByName('name').AsString := 'Test';
    ACRTable1.Post;
end;

end.
