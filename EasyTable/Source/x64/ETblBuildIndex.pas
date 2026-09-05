{$I ETblVer.inc}

unit ETblBuildIndex;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ETblGauge;

type
  TFormBuildIndex = class(TForm)
    lbTable: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    Indicator: TTETGauge;
    { Public declarations }
  end;

var
  FormBuildIndex: TFormBuildIndex;

implementation

{$R *.DFM}

procedure TFormBuildIndex.FormCreate(Sender: TObject);
begin
  Indicator := TTETGauge.Create(self);
  Indicator.Parent := Self;
  Indicator.Color1 := clWhite;
  Indicator.Color2 := clBlue;
  Indicator.Left := 46;
  Indicator.Top := 49;
  Indicator.Width := 162;
  Indicator.Height := 27;
end;

procedure TFormBuildIndex.FormDestroy(Sender: TObject);
begin
 Indicator.Free;
end;

end.
