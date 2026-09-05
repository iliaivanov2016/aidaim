object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 
    'LoadSaveMemoryDatabase demo. (c) AidAim Software, 2009. http://w' +
    'ww.aidaim.com'
  ClientHeight = 460
  ClientWidth = 700
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
  object Splitter1: TSplitter
    Left = 350
    Top = 0
    Height = 419
  end
  object Panel1: TPanel
    Left = 0
    Top = 419
    Width = 700
    Height = 41
    Align = alBottom
    TabOrder = 0
    object bnLoadDB: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Load Database'
      TabOrder = 0
      OnClick = bnLoadDBClick
    end
    object bnSaveDB: TButton
      Left = 120
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Save Database'
      TabOrder = 1
      OnClick = bnSaveDBClick
    end
    object bnClose: TButton
      Left = 232
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Close'
      TabOrder = 2
      OnClick = bnCloseClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 350
    Height = 419
    Align = alLeft
    TabOrder = 1
    object DBGrid1: TDBGrid
      Left = 1
      Top = 1
      Width = 348
      Height = 392
      Align = alClient
      DataSource = DataSource1
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object DBNavigator1: TDBNavigator
      Left = 1
      Top = 393
      Width = 348
      Height = 25
      DataSource = DataSource1
      Align = alBottom
      TabOrder = 1
    end
  end
  object Panel3: TPanel
    Left = 353
    Top = 0
    Width = 347
    Height = 419
    Align = alClient
    TabOrder = 2
    object DBGrid2: TDBGrid
      Left = 1
      Top = 1
      Width = 345
      Height = 392
      Align = alClient
      DataSource = DataSource2
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object DBNavigator2: TDBNavigator
      Left = 1
      Top = 393
      Width = 345
      Height = 25
      DataSource = DataSource2
      Align = alBottom
      TabOrder = 1
    end
  end
  object tDept: TSQLMemTable
    CurrentVersion = '4.00 '
    DatabaseName = 'MemDBLoadSave'
    ReadOnly = False
    TableName = 'dept'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 64
    Top = 88
  end
  object db: TSQLMemDatabase
    DatabaseName = 'MemDBLoadSave'
    InMemory = True
    Left = 280
    Top = 88
  end
  object tEmp: TSQLMemTable
    CurrentVersion = '4.00 '
    DatabaseName = 'MemDBLoadSave'
    ReadOnly = False
    TableName = 'emp'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 368
    Top = 88
  end
  object DataSource1: TDataSource
    DataSet = tDept
    Left = 96
    Top = 88
  end
  object DataSource2: TDataSource
    DataSet = tEmp
    Left = 400
    Top = 88
  end
end
