object Form1: TForm1
  Left = 192
  Top = 103
  Width = 696
  Height = 320
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Indicator: TGauge
    Left = 208
    Top = 168
    Width = 217
    Height = 24
    ForeColor = clBlue
    Progress = 0
  end
  object Label1: TLabel
    Left = 160
    Top = 64
    Width = 305
    Height = 65
    AutoSize = False
    WordWrap = True
  end
  object Button1: TButton
    Left = 280
    Top = 248
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
end
