unit BkThread;

interface

uses
  Classes, SysUtils, ACRMain, Dialogs, Windows;

type
  TQueryThread = class(TThread)
  private
    Session:  TACRSession;
    Database: TACRDatabase;
    Query:    TACRQuery;
    Table:    TACRTable;

    procedure UpdateGrid;
  protected
    procedure Execute; override;
  end;

implementation

uses uMain;

{ TQueryThread }

procedure TQueryThread.UpdateGrid;
begin
  fMain.ACRTable1.Refresh;
  fMain.lbRecCount.Caption := IntToStr(fMain.ACRTable1.RecordCount);
end;


procedure TQueryThread.Execute;
var
 SesName, DBName: string;
 i: integer;
begin
  SesName := 'ses'+IntToStr(Random(100000));
  DBName := 'db'+IntToStr(Random(100000));

  Session := TACRSession.Create(nil);
  Session.SessionName := SesName;

  Database := TACRDatabase.Create(nil);
  Database.SessionName := SesName;
  Database.DatabaseName := DBName;
  Database.DatabaseFileName := fMain.ACRDatabase1.DatabaseFileName;
  Database.Open;
{
  Table := TACRTable.Create(nil);
  Table.SessionName := SesName;
  Table.DatabaseName := DBName;
  Table.TableName := fMain.ACRTable1.TableName;
  Table.Open;

  for i := 0 to 99 do
   begin
    Table.Insert;
    Table.FieldByName('Time').AsDateTime := Now;
    Table.FieldByName('Name').AsString := SesName;
    Table.FieldByName('Integer').AsInteger := Random(MaxInt);
    Table.FieldByName('Money').AsFloat := Random * 5000;
    Table.Post;
    Synchronize(UpdateGrid);
    Sleep(20);
   end;
  Table.Free;
  
}
  Query := TACRQuery.Create(nil);
  Query.SessionName := SesName;
  Query.DatabaseName := DBName;

  Query.SQL.Text := 'INSERT INTO TEST (Time, Name, Integer, Money) VALUES (:Time, :Name, :Integer, :Money)';
//  Query.SQL.Text := 'SELECT * from Test order by Name desc';
  // 100 inserts
  for i := 0 to 99 do
   begin

    Query.ParamByName('Time').AsTime := Now;
    Query.ParamByName('Name').AsString := SesName;
    Query.ParamByName('Integer').AsInteger := Random(MaxInt);
    Query.ParamByName('Money').AsFloat := Random * 5000;

    Query.ExecSQL;

//Query.Open;
    Synchronize(UpdateGrid);
    Sleep(20);
   end;
  Query.Free;

  Database.Free;
  Session.Free;
end;

end.
