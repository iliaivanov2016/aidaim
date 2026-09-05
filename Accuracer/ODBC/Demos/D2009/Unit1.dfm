object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 195
  ClientWidth = 574
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 0
    Top = 39
    Width = 573
    Height = 120
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 168
    Top = 166
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object btnOpen: TButton
    Left = 168
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 2
    OnClick = btnOpenClick
  end
  object btnClose: TButton
    Left = 335
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 3
    OnClick = btnCloseClick
  end
  object Table1: TTable
    DatabaseName = 'Test'
    TableName = 'Table1'
    Left = 320
    Top = 88
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 248
    Top = 88
  end
end
