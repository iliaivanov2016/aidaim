unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  frxClass, StdCtrls, frxCross, Db,  ACRMain;

type
  TForm1 = class(TForm)
    Button1: TButton;
    frxCrossObject1: TfrxCrossObject;
    frxReport1: TfrxReport;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    procedure Button1Click(Sender: TObject);
    procedure frxReport1BeforePrint(c: TfrxReportComponent);
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
begin
  frxReport1.ShowReport;
end;

procedure TForm1.frxReport1BeforePrint(c: TfrxReportComponent);
var
  Cross: TfrxCrossView;
  i, j: Integer;
begin
  if c is TfrxCrossView then
  begin
    Cross := TfrxCrossView(c);
    ACRTable1.Open;
    ACRTable1.First;
    i := 0;
    while not ACRTable1.Eof do
    begin
      for j := 0 to ACRTable1.Fields.Count - 1 do
        Cross.AddValue([i], [ACRTable1.Fields[j].DisplayLabel], [ACRTable1.Fields[j].AsString]);

      ACRTable1.Next;
      Inc(i);
    end;
  end;
end;

end.
