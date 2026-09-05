object Form1: TForm1
  Left = 192
  Top = 132
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Batch demo. (c) AidAim Software LLC, 2003.'
  ClientHeight = 327
  ClientWidth = 681
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 176
    Top = 7
    Width = 315
    Height = 32
    Caption = 
      'This demo program illustrates the batch operations of EasyTable ' +
      'via AddRecords method'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 77
    Width = 320
    Height = 120
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -10
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 46
    Top = 206
    Width = 230
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object DBGrid2: TDBGrid
    Left = 352
    Top = 77
    Width = 320
    Height = 120
    DataSource = DataSource2
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -10
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator2: TDBNavigator
    Left = 391
    Top = 206
    Width = 230
    Height = 25
    DataSource = DataSource2
    TabOrder = 3
  end
  object Button1: TButton
    Left = 300
    Top = 297
    Width = 75
    Height = 26
    Caption = 'Transfer'
    TabOrder = 4
    OnClick = Button1Click
  end
  object rgMode: TRadioGroup
    Left = 182
    Top = 234
    Width = 105
    Height = 85
    Caption = 'Mode'
    ItemIndex = 0
    Items.Strings = (
      'Append'
      'Update'
      'AppendUpdate'
      'Replace')
    TabOrder = 5
  end
  object SourceTable: TEasyTable
    FilterOptions = []
    CurrentVersion = '5.61 '
    TableName = 'biolife'
    DatabaseFileName = '..\\..\\Data\\dbfishes.edb'
    InMemory = False
    AutoIndexes = False
    CacheEnabled = True
    BDELikeFilter = False
    Left = 8
    Top = 64
  end
  object DestTable: TEasyTable
    FilterOptions = []
    CurrentVersion = '5.61 '
    TableName = 'test'
    DatabaseFileName = '..\\..\\Data\\dbfishes.edb'
    InMemory = False
    AutoIndexes = False
    CacheEnabled = True
    BDELikeFilter = False
    Left = 432
    Top = 64
  end
  object DataSource1: TDataSource
    DataSet = SourceTable
    Left = 40
    Top = 64
  end
  object DataSource2: TDataSource
    DataSet = DestTable
    Left = 464
    Top = 64
  end
end
