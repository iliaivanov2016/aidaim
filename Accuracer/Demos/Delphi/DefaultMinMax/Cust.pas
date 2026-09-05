unit Cust;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Dialogs, StdCtrls, Buttons, Spin;

type
  TForm2 = class(TForm)
    Label2: TLabel;
    Label4: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Edit1: TEdit;
    Label6: TLabel;
    ComboBox2: TComboBox;
    Label3: TLabel;
    Label1: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

end.
