object Form1: TForm1
  Left = 260
  Top = 214
  Caption = 'Form1'
  ClientHeight = 333
  ClientWidth = 547
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 9
    Top = 97
    Width = 241
    Height = 153
    DataSource = dsTable
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 9
    Top = 259
    Width = 240
    Height = 25
    DataSource = dsTable
    TabOrder = 1
  end
  object DBGrid2: TDBGrid
    Left = 293
    Top = 97
    Width = 241
    Height = 153
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator2: TDBNavigator
    Left = 293
    Top = 259
    Width = 240
    Height = 25
    TabOrder = 3
  end
  object Button1: TButton
    Left = 320
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Run Query'
    TabOrder = 4
    OnClick = Button1Click
  end
  object GroupBox1: TGroupBox
    Left = 294
    Top = 0
    Width = 240
    Height = 83
    Caption = ' Query Text '
    TabOrder = 5
    object mQuery: TMemo
      Left = 2
      Top = 15
      Width = 236
      Height = 66
      Align = alClient
      Lines.Strings = (
        'Select * from Table1 where id >= 2')
      TabOrder = 0
    end
  end
  object GroupBox2: TGroupBox
    Left = 10
    Top = 0
    Width = 240
    Height = 83
    TabOrder = 6
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 225
      Height = 65
      AutoSize = False
      Caption = 
        'This demo shows how you can use IProvider interface of TClientDa' +
        'taset with Accuracer components.'
      WordWrap = True
    end
  end
  object Button2: TButton
    Left = 72
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 7
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 416
    Top = 296
    Width = 89
    Height = 25
    Caption = 'Execute Query'
    TabOrder = 8
    OnClick = Button3Click
  end
  object ACRTable1: TACRTable
    CurrentVersion = '15.00 '
    InMemory = False
    DatabaseName = 'TestDB'
    ReadOnly = False
    CaseInsensitive = False
    TableName = 'customer_Findkey'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 73
    Top = 176
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 15.000000000000000000
    DatabaseName = 'TestDB'
    InMemory = False
    SessionName = 'Default'
    DatabaseFileNameUnicode = '..\..\Data\DBDemos.adb'
    DatabaseFileName = '..\..\Data\DBDemos.adb'
    Exclusive = False
    BackupParams.CompressionAlgorithm = caNone
    BackupParams.CompressionMode = 1
    BackupParams.CryptoParams.CryptoAlgorithm = craNone
    BackupParams.CryptoParams.CryptoMode = acmCTS
    BackupParams.CryptoParams.KeySize = 56
    BackupParams.CryptoParams.Password = 'ACRpassword'
    BackupParams.CryptoParams.UseInitVector = False
    BackupParams.CryptoParams.InitVectorSize = 0
    BackupParams.BlockSize = 102400
    ConnectionParams.DatabaseName = 'DBDemos'
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'ACRpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.ServerID = 0
    ConnectionParams.Protocol = acrUDP
    ConnectionParams.RemoteHost = 'localhost'
    ConnectionParams.RemotePort = 6669
    ConnectionParams.MinCacheSize = 1429
    ConnectionParams.MaxCacheSize = 1048576
    LockParams.Delay = 100
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 1
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    CaseInsensitive = False
    Left = 256
    Top = 128
  end
  object ACRQuery1: TACRQuery
    CurrentVersion = '15.00 '
    InMemory = True
    DatabaseName = 'MEMORY'
    ReadOnly = False
    CaseInsensitive = False
    Left = 456
    Top = 80
  end
  object cdsQuery: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <>
    Params = <>
    ProviderName = 'dspQueryProvider'
    StoreDefs = True
    Left = 416
    Top = 80
  end
  object cdsTable: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'Company'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'Address'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'Phone'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'FAX'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'TaxRate'
        DataType = ftFloat
      end
      item
        Name = 'LastInvoiceDate'
        DataType = ftDateTime
      end
      item
        Name = 'CustNo'
        Attributes = [faReadonly]
        DataType = ftAutoInc
      end>
    IndexDefs = <>
    Params = <>
    ProviderName = 'dsTableProvider'
    StoreDefs = True
    AfterPost = cdsTableAfterPost
    AfterDelete = cdsTableAfterDelete
    Left = 113
    Top = 176
  end
  object dsTable: TDataSource
    DataSet = cdsTable
    Left = 200
    Top = 176
  end
  object dsTableProvider: TDataSetProvider
    DataSet = ACRTable1
    ResolveToDataSet = True
    Options = [poIncFieldProps, poAutoRefresh, poPropogateChanges, poAllowCommandText]
    UpdateMode = upWhereKeyOnly
    Left = 153
    Top = 176
  end
  object dspQueryProvider: TDataSetProvider
    DataSet = ACRQuery1
    ResolveToDataSet = True
    Options = [poIncFieldProps, poAutoRefresh, poPropogateChanges, poAllowCommandText]
    UpdateMode = upWhereKeyOnly
    Left = 376
    Top = 80
  end
  object DataSource1: TDataSource
    DataSet = cdsQuery
    Left = 336
    Top = 80
  end
  object ACRTable2: TACRTable
    CurrentVersion = '15.00 '
    InMemory = True
    DatabaseName = 'MEMORY'
    ReadOnly = False
    CaseInsensitive = False
    TableName = 'Table1'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 520
    Top = 80
  end
end
