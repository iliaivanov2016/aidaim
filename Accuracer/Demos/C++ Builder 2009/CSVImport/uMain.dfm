object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'CSVImport demo for Delphi 2009. (c) AidAim Software, 2003-2009.'
  ClientHeight = 449
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
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
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    AutoSize = False
    Caption = 
      'This demo illustrates importing data from CSV text files to Accu' +
      'racer Table'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object GroupBox1: TGroupBox
    Left = 13
    Top = 78
    Width = 384
    Height = 137
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Excel'
    TabOrder = 0
    object DBGrid2: TDBGrid
      Left = 7
      Top = 13
      Width = 371
      Height = 118
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      DataSource = dsADO
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
  end
  object DBNavigator2: TDBNavigator
    Left = 91
    Top = 223
    Width = 220
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    DataSource = dsADO
    TabOrder = 1
  end
  object GroupBox2: TGroupBox
    Left = 13
    Top = 273
    Width = 384
    Height = 131
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Accuracer'
    TabOrder = 2
    object DBGrid1: TDBGrid
      Left = 7
      Top = 13
      Width = 371
      Height = 111
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      DataSource = dsEasyTable
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
  end
  object DBNavigator1: TDBNavigator
    Left = 91
    Top = 414
    Width = 220
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    DataSource = dsEasyTable
    TabOrder = 3
  end
  object dsADO: TDataSource
    DataSet = ADODataSet1
    Left = 240
    Top = 72
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
  object dsEasyTable: TDataSource
    DataSet = ACRTable1
    Left = 240
    Top = 312
  end
  object ACRTable1: TACRTable
    CurrentVersion = '4.80 '
    DatabaseName = 'MEMORY'
    InMemory = True
    ReadOnly = False
    TableName = 'test'
    Exclusive = True
    MemoryTableAllocBy = 1000
    Left = 272
    Top = 312
  end
end
