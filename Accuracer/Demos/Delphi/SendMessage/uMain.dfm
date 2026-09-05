object Form2: TForm2
  Left = 136
  Top = 205
  Width = 564
  Height = 367
  Caption = 'Form2'
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
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 556
    Height = 273
    Align = alTop
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 272
    Top = 296
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object Button1: TButton
    Left = 32
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Send Text'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 32
    Top = 311
    Width = 75
    Height = 25
    Caption = 'Send Stream'
    TabOrder = 3
    OnClick = Button2Click
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 5.500000000000000000
    OnReceiveTextMessage = ACRDatabase1ReceiveTextMessage
    DatabaseName = 'AccuracerDB_876924974'
    InMemory = False
    SessionName = 'Default'
    LocalDatabase = False
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
    ConnectionParams.RemoteHost = '127.0.0.1'
    ConnectionParams.RemotePort = 12007
    ConnectionParams.LocalPort = 12008
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
    ConnectionParams.MinCacheSize = 1429
    ConnectionParams.MaxCacheSize = 1048576
    LockParams.Delay = 500
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 2
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    Left = 304
    Top = 240
  end
  object ACRServer1: TACRServer
    ConnectionParams.RemotePort = 0
    ConnectionParams.LocalPort = 12007
    ConnectionParams.DatabaseName = 'DBDemos'
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'ACRpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.ServerID = 0
    UseConfigFile = False
    Active = False
    CurrentVersion = '5.50 '
    DatabaseNames.Strings = (
      'DBDemos')
    DatabaseFileNames.Strings = (
      '..\..\Demos\Data\DBDemos.adb')
    ConfigFileName = 'AccuracerDatabaseServer.ini'
    OpenDatabasesInExclusiveMode = True
    OnReceiveTextMessage = ACRServer1ReceiveTextMessage
    OnReceiveStreamMessage = ACRServer1ReceiveStreamMessage
    MaxCommandExecutionTime = 1800
    Left = 248
    Top = 240
  end
  object ACRTable1: TACRTable
    CurrentVersion = '5.50 '
    InMemory = False
    DatabaseName = 'AccuracerDB_876924974'
    ReadOnly = False
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 352
    Top = 240
  end
  object DataSource1: TDataSource
    DataSet = ACRTable1
    Left = 400
    Top = 240
  end
end
