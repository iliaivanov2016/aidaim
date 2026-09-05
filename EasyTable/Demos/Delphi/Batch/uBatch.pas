unit uBatch;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, EasyTable, StdCtrls, ExtCtrls, DBCtrls, Grids, DBGrids;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    Button1: TButton;
    rgMode: TRadioGroup;
    SourceTable: TEasyTable;
    DestTable: TEasyTable;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.Button1Click(Sender: TObject);
var Log : string;
begin
 case rgMode.ItemIndex of
  0: if (not DestTable.AddRecords(SourceTable, arAppend, Log)) then
     MessageDlg('Error adding records: '+Log,mtError,[mbOk],0);
  1: if (not DestTable.AddRecords(SourceTable, arUpdate, Log)) then
     MessageDlg('Error adding records: '+Log,mtError,[mbOk],0);
  2: if (not DestTable.AddRecords(SourceTable, arAppendUpdate, Log)) then
     MessageDlg('Error adding records: '+Log,mtError,[mbOk],0);
  3: if (not DestTable.AddRecords(SourceTable, arReplace, Log)) then
     MessageDlg('Error adding records: '+Log,mtError,[mbOk],0);
 end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 SourceTable.Open;
 DestTable.FieldDefs.Assign(SourceTable.FieldDefs);
 DestTable.IndexDefs.Assign(SourceTable.IndexDefs);
 DestTable.CreateTable;
 DestTable.Open
end;

end.
