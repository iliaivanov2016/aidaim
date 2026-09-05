unit BkThread;

interface

uses
  Classes, SysUtils, EasyTable, Dialogs, Windows;

type
  TQueryThread = class(TThread)
  private
    Session:  TEasySession;
    Database: TEasyDatabase;
    Query:    TEasyQuery;

    procedure UpdateGrid;
  protected
    procedure Execute; override;
  end;

implementation

uses uMain;

{ TQueryThread }

procedure TQueryThread.UpdateGrid;
begin
  fMain.EasyTable1.Refresh;
  fMain.lbRecCount.Caption := IntToStr(fMain.EasyTable1.RecordCount);
end;


procedure TQueryThread.Execute;
var
 SesName, DBName: string;
 i: integer;
begin
  SesName := 'ses'+IntToStr(Random(100000));
  DBName := 'db'+IntToStr(Random(100000));

  Session := TEasySession.Create(nil);
  Session.SessionName := SesName;

  Database := TEasyDatabase.Create(nil);
  Database.SessionName := SesName;
  Database.DatabaseName := DBName;
  Database.DatabaseFileName := fMain.EasyDatabase1.DatabaseFileName;

  Query := TEasyQuery.Create(nil);
  Query.SessionName := SesName;
  Query.DatabaseName := DBName;

  Query.SQL.Text := 'INSERT INTO TEST (Time, Name, Integer, Money) VALUES (:Time, :Name, :Integer, :Money)';
  // 100 inserts
  for i := 0 to 99 do
   begin
    Query.ParamByName('Time').AsTime := Now;
    Query.ParamByName('Name').AsString := SesName;
    Query.ParamByName('Integer').AsInteger := Random(MaxInt);
    Query.ParamByName('Money').AsFloat := Random * 5000;

    Query.ExecSQL;
    Synchronize(UpdateGrid);
    Sleep(20);
   end;

  Query.Free;
  Database.Free;
  Session.Free;

end;

end.
 