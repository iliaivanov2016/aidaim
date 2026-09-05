unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, CPSMain;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    rgFormats: TRadioGroup;
    bnStringToFormat: TButton;
    bnFormatToString: TButton;
    Button1: TButton;
    GroupBox1: TGroupBox;
    reSource: TRichEdit;
    GroupBox2: TGroupBox;
    reEncoded: TRichEdit;
    GroupBox3: TGroupBox;
    reDecoded: TRichEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnStringToFormatClick(Sender: TObject);
    procedure bnFormatToStringClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i: Integer;
begin
 rgFormats.Items.Clear;
 for i := Low(CPSStringFormatNames) to High(CPSStringFormatNames) do
  rgFormats.Items.Add(CPSStringFormatNames[i]);
 rgFormats.ItemIndex := 0;
 reSource.Lines.LoadFromFile('uMain.pas');
end;

procedure TForm1.bnStringToFormatClick(Sender: TObject);
begin
 reEncoded.Text := CPSManager1.StringToFormat(reSource.Text,TCPSStringFormat(rgFormats.ItemIndex));
 bnFormatToString.Enabled := True;
end;


procedure TForm1.bnFormatToStringClick(Sender: TObject);
begin
 reDecoded.Text := CPSManager1.FormatToString(reEncoded.Text,TCPSStringFormat(rgFormats.ItemIndex));
end;

end.
