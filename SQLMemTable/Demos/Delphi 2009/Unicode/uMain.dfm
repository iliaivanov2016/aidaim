object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Unicode demo. (c) AidAim Software, 2009. http://www.aidaim.com'
  ClientHeight = 375
  ClientWidth = 575
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DBNavigator1: TDBNavigator
    Left = 8
    Top = 264
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 0
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 575
    Height = 258
    Align = alTop
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object DBMemo1: TDBMemo
    Left = 272
    Top = 264
    Width = 295
    Height = 89
    DataField = 'Text_memo'
    DataSource = DataSource1
    TabOrder = 2
  end
  object Button1: TButton
    Left = 136
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 24
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Run Query'
    TabOrder = 4
    OnClick = Button2Click
  end
  object DataSource1: TDataSource
    DataSet = SQLMemTable1
    Left = 72
    Top = 104
  end
  object SQLMemQuery1: TSQLMemQuery
    CurrentVersion = '3.80 '
    ReadOnly = False
    Left = 200
    Top = 104
  end
  object SQLMemTable1: TSQLMemTable
    CurrentVersion = '3.80 '
    ReadOnly = False
    TableName = 'test'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 128
    Top = 104
  end
end
