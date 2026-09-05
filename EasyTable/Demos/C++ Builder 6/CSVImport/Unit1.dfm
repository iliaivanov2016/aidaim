object Form1: TForm1
  Left = 345
  Top = 183
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'CSVImport demo. (c) AidAim Software LLC, 2003.'
  ClientHeight = 449
  ClientWidth = 410
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 64
    Top = 18
    Width = 257
    Height = 39
    AutoSize = False
    Caption = 
      'This demo illustrates importing data from CSV text files to Easy' +
      'Table'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object DBNavigator1: TDBNavigator
    Left = 91
    Top = 414
    Width = 230
    Height = 25
    DataSource = dsEasyTable
    TabOrder = 0
  end
  object DBNavigator2: TDBNavigator
    Left = 91
    Top = 223
    Width = 230
    Height = 25
    DataSource = dsADO
    TabOrder = 1
  end
  object GroupBox1: TGroupBox
    Left = 13
    Top = 78
    Width = 384
    Height = 137
    Caption = 'Excel'
    TabOrder = 2
    object DBGrid2: TDBGrid
      Left = 7
      Top = 13
      Width = 371
      Height = 118
      DataSource = dsADO
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
  end
  object GroupBox2: TGroupBox
    Left = 13
    Top = 273
    Width = 384
    Height = 131
    Caption = 'EasyTable'
    TabOrder = 3
    object DBGrid1: TDBGrid
      Left = 7
      Top = 13
      Width = 371
      Height = 111
      DataSource = dsEasyTable
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
  end
  object ADODataSet1: TADODataSet
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Extended Properti' +
      'es="DSN=test_csv;DBQ=;DefaultDir=;DriverId=27;FIL=text;MaxBuffer' +
      'Size=2048;PageTimeout=5;";Initial Catalog='
    CursorType = ctStatic
    CommandText = 'select *  from 1.csv'
    Parameters = <>
    Left = 272
    Top = 72
  end
  object EasyTable1: TEasyTable
    FilterOptions = []
    CurrentVersion = '5.60 '
    TableName = 'test'
    DatabaseFileName = 'test.edb'
    InMemory = True
    AutoIndexes = False
    CacheEnabled = True
    BDELikeFilter = False
    Left = 272
    Top = 312
  end
  object dsEasyTable: TDataSource
    DataSet = EasyTable1
    Left = 240
    Top = 312
  end
  object dsADO: TDataSource
    DataSet = ADODataSet1
    Left = 232
    Top = 72
  end
end
