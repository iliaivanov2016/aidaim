object Form1: TForm1
  Left = 276
  Top = 103
  Width = 870
  Height = 500
  Caption = 'Form1'
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
  object Label1: TLabel
    Left = 264
    Top = 432
    Width = 226
    Height = 13
    Caption = 'Edit data in the left grid and click on Post button'
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 393
    Height = 401
    DataSource = dsMain
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 8
    Top = 424
    Width = 240
    Height = 25
    DataSource = dsMain
    TabOrder = 1
  end
  object DBNavigator2: TDBNavigator
    Left = 504
    Top = 424
    Width = 240
    Height = 25
    DataSource = dsInout
    TabOrder = 2
  end
  object DBGrid2: TDBGrid
    Left = 432
    Top = 8
    Width = 393
    Height = 401
    DataSource = dsInout
    TabOrder = 3
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 4.200000000000000000
    DatabaseFileName = 'test.adb'
    DatabaseName = 'AccuracerDB_1445839525'
    Exclusive = False
    SessionName = 'Default'
    BackupParams.CompressionAlgorithm = caNone
    BackupParams.CompressionMode = 1
    BackupParams.CryptoParams.CryptoAlgorithm = craNone
    BackupParams.CryptoParams.CryptoMode = acmCTS
    BackupParams.CryptoParams.KeySize = 56
    BackupParams.CryptoParams.Password = 'ACRpassword'
    BackupParams.CryptoParams.UseInitVector = False
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
    ConnectionParams.ServerID = 0
    ConnectionParams.NetworkSettings.PacketSize = 8192
    ConnectionParams.NetworkSettings.MaxThreadCount = 100
    ConnectionParams.NetworkSettings.ConnectionParamsTunning = False
    ConnectionParams.NetworkSettings.TestPacketCount = 8
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 12
    ConnectionParams.NetworkSettings.DisconnectDelay = 300
    ConnectionParams.NetworkSettings.ConnectRetryCount = 20
    ConnectionParams.NetworkSettings.ConnectDelay = 500
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 60000
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 600000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 10000
    ConnectionParams.NetworkSettings.SendTimeOut = 180000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 300
    ConnectionParams.NetworkSettings.RequestDelay = 300
    ConnectionParams.NetworkSettings.WaitForTimeOut = 120000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 30000
    LockParams.Delay = 500
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 367
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    Left = 136
    Top = 72
  end
  object tMain: TACRTable
    CurrentVersion = '4.20 '
    DatabaseName = 'AccuracerDB_1445839525'
    InMemory = False
    ReadOnly = False
    AfterPost = tMainAfterPost
    TableName = 'main'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 120
    Top = 280
  end
  object tInout: TACRTable
    CurrentVersion = '4.20 '
    DatabaseName = 'AccuracerDB_1445839525'
    InMemory = False
    ReadOnly = False
    TableName = 'InOut'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 232
    Top = 280
  end
  object dsMain: TDataSource
    DataSet = tMain
    Left = 112
    Top = 248
  end
  object dsInout: TDataSource
    DataSet = tInout
    Left = 232
    Top = 240
  end
end
