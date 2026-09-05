object Form1: TForm1
  Left = 215
  Top = 103
  Width = 696
  Height = 394
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
  object Button1: TButton
    Left = 64
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 688
    Height = 297
    Align = alTop
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 224
    Top = 328
    Width = 240
    Height = 25
    TabOrder = 2
  end
  object Query1: TQuery
    DatabaseName = 'ACRTest'
    Left = 80
    Top = 96
  end
  object DataSource1: TDataSource
    DataSet = Query1
    Left = 184
    Top = 80
  end
end
