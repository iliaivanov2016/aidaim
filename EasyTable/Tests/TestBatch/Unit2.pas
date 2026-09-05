unit Unit2;

interface

uses
  Classes, EasyTable, SysUtils;

type
  TestThread1 = class(TThread)
  private
    { Private declarations }
    Session:  TEasySession;
    Database: TEasyDatabase;
    Table:    TEasyTable;
    Query:    TEasyQuery;
  protected
    procedure Execute; override;
  end;

implementation

uses Windows, ETblEngine;
{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TestThread1.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TestThread1 }

var Section: TRTLCriticalSection;

procedure TestThread1.Execute;
var
 SesName, DBName: string;
begin
  SesName := 'ses'+IntToStr(Random(100000));
  DBName := 'db'+IntToStr(Random(100000));
  Session := TEasySession.Create(nil);
  Session.SessionName := SesName;
  Database := TEasyDatabase.Create(nil);
  Database.SessionName := SesName;
  Database.DatabaseName := DBName;
  Database.DatabaseFileName := 's:\dbdemos.edb';
  Table := TEasyTable.Create(nil);
  Table.SessionName := SesName;
  Table.DatabaseName := DBName;
  Table.TableName := 'customer';
  Query := TEasyQuery.Create(nil);
  Query.SessionName := SesName;
  Query.DatabaseName := DBName;
  Query.SQL.Text := 'select * from customer';

  Query.Open;
  Query.Close;

  Table.Active := True;
  Table.Last;
  Table.Insert;
  Table.Post;
  Table.Insert;
  Table.Post;
  Table.Insert;
  Table.Post;
  Table.Locate('ID0', 2, []);
  Table.Last;
//  Table.Delete;

  Table.Active := False;

  Query.Free;
  Table.Free;
  Database.Free;
  Session.Free;

//  ETblEnterCriticalSection(@Section);
//  ETblEnterCriticalSection(@Section);
//  ETblLeaveCriticalSection(@Section);
  Terminate;
end;

Initialization
 ETblInitializeCriticalSection(@Section);

end.
