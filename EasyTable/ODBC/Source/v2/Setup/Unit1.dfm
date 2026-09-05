object Form1: TForm1
  Left = 408
  Top = 256
  BorderStyle = bsDialog
  Caption = 'Setup'
  ClientHeight = 141
  ClientWidth = 163
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object OK: TButton
    Left = 43
    Top = 104
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = OKClick
  end
  object ToDo: TRadioGroup
    Left = 8
    Top = 8
    Width = 145
    Height = 81
    Caption = 'EasyTable ODBC Driver'
    ItemIndex = 0
    Items.Strings = (
      'Install'
      'Uninstall')
    TabOrder = 1
  end
end
