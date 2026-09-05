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
    Left = 80
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 3
    OnClick = Button1Click
  end
  object ACRTable1: TACRTable
    CurrentVersion = '4.80 '
    DatabaseName = 'MEMORY'
    InMemory = True
    ReadOnly = False
    TableName = 'test'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 160
    Top = 112
  end
  object DataSource1: TDataSource
    DataSet = ACRTable1
    Left = 72
    Top = 104
  end
end
