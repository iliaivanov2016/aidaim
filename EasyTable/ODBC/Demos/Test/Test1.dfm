object Form1: TForm1
  Left = 208
  Top = 107
  Width = 641
  Height = 475
  Caption = 'EasyTable ODBC Driver Test'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 88
    Top = 6
    Width = 116
    Height = 13
    Caption = 'EasyTable direct access'
  end
  object Label2: TLabel
    Left = 428
    Top = 6
    Width = 114
    Height = 13
    Caption = 'EasyTable ODBC Driver'
  end
  object DBGrid1: TDBGrid
    Left = 320
    Top = 168
    Width = 297
    Height = 241
    DataSource = ODBCTable1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 344
    Top = 416
    Width = 240
    Height = 25
    DataSource = ODBCTable1
    TabOrder = 1
  end
  object OpenTable: TButton
    Left = 32
    Top = 24
    Width = 100
    Height = 25
    Caption = 'Open Table'
    TabOrder = 2
    OnClick = EasyTableOpenTableClick
  end
  object CloseTable: TButton
    Left = 168
    Top = 24
    Width = 100
    Height = 25
    Caption = 'Close Table'
    TabOrder = 3
    OnClick = EasyTableCloseTableClick
  end
  object DBGrid2: TDBGrid
    Left = 8
    Top = 168
    Width = 297
    Height = 241
    DataSource = EasyTableTable1
    TabOrder = 4
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object ODBCOpenTable: TButton
    Left = 357
    Top = 24
    Width = 100
    Height = 25
    Caption = 'Open Table'
    TabOrder = 5
    OnClick = ODBCOpenTableClick
  end
  object Button2: TButton
    Left = 493
    Top = 24
    Width = 100
    Height = 25
    Caption = 'Close Table'
    TabOrder = 6
    OnClick = ODBCCloseTableClick
  end
  object DBMemo1: TDBMemo
    Left = 320
    Top = 56
    Width = 297
    Height = 105
    DataSource = ODBCTable1
    ScrollBars = ssBoth
    TabOrder = 7
  end
  object DBNavigator2: TDBNavigator
    Left = 32
    Top = 415
    Width = 240
    Height = 25
    DataSource = EasyTableTable1
    TabOrder = 8
  end
  object DBMemo2: TDBMemo
    Left = 8
    Top = 56
    Width = 297
    Height = 105
    DataSource = EasyTableTable1
    ScrollBars = ssBoth
    TabOrder = 9
  end
  object Table1: TTable
    DatabaseName = 'Test'
    FieldDefs = <
      item
        Name = 'Int16'
        DataType = ftSmallint
      end>
    StoreDefs = True
    TableName = 'Table1'
    Left = 600
    Top = 72
  end
  object Test: TDatabase
    AliasName = 'Test'
    Connected = True
    DatabaseName = 'Test'
    LoginPrompt = False
    SessionName = 'Default'
    Left = 600
    Top = 40
  end
  object EasyTable1: TEasyTable
    FilterOptions = []
    CurrentVersion = '5.10 '
    TableName = 'Table1'
    DatabaseName = 'Test'
    InMemory = False
    AutoIndexes = False
    CacheEnabled = True
    BDELikeFilter = False
    Top = 64
  end
  object EasyDatabase1: TEasyDatabase
    DatabaseFileName = 'test.edb'
    DatabaseName = 'Test'
    InMemory = False
    SessionName = 'Default'
    Top = 32
  end
  object ODBCTable1: TDataSource
    DataSet = Table1
    Left = 600
    Top = 112
  end
  object EasyTableTable1: TDataSource
    DataSet = EasyTable1
    Top = 104
  end
end
