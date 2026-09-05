unit Cust;

interface

uses
  Windows, Messages, SysUtils, 
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Spin;

type
  TForm2 = class(TForm)
    SpinEdit3: TSpinEdit;
    Label2: TLabel;
    Label4: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Edit1: TEdit;
    Label6: TLabel;
    ComboBox2: TComboBox;
    SpinEdit1: TSpinEdit;
    Label3: TLabel;
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
