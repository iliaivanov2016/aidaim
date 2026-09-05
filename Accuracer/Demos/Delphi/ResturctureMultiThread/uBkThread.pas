unit uBkThread;

interface

uses Classes, SysUtils, Windows, ACRMain, ACRTypes;


type
  TRestructureThread = class (TThread)
    private
     FDBFileName:    String;
     FTableName:     String;
    protected
     procedure Finalize;
    public
     constructor Create(aDBFile, aTableName: String);
     procedure Execute; override;
  end;

implementation

uses uMain;

{ TRestructureThread }

constructor TRestructureThread.Create(aDBFile, aTableName: String);
begin
  inherited Create(True);
  FDBFileName := aDBFile;
  FTableName := aTableName;
end;

procedure TRestructureThread.Execute;
var
    db: TACRDatabase;
    t:  TACRTable;
    i:  Integer;
begin
  db := TACRDatabase.Create(nil);
  t := TACRTable.Create(nil);
  try
    db.DatabaseFileName := FDBFileName;
    db.Open;
    t.TableName := FTableName;
    t.DatabaseName := db.DatabaseName;
    t.Open;
    t.Close;
    i := t.RestructureFieldDefs.Count;
    t.RestructureFieldDefs.Add('Field #'+IntToStr(i),aftChar,20);
    t.RestructureTable;
  finally
    t.Free;
    db.Free;
    Synchronize(Finalize);
  end;
end;

procedure TRestructureThread.Finalize;
begin
  Form1.Finish;
end;

end.
