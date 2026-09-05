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
  object tDept: TACRTable
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
    DatabaseName = 'MemDBLoadSave'
    ReadOnly = False
    TableName = 'dept'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 64
    Top = 88
  end
  object db: TACRDatabase
    FormatVersion = 4.950000000000000000
    DatabaseName = 'MemDBLoadSave'
    InMemory = True
    SessionName = 'Default'
    Exclusive = False
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
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 10
    ConnectionParams.NetworkSettings.DisconnectDelay = 3000
    ConnectionParams.NetworkSettings.CommandRetryCount = 10
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 600000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 60000
    ConnectionParams.NetworkSettings.SendTimeOut = 180000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 6000
    ConnectionParams.NetworkSettings.RequestDelay = 5000
    ConnectionParams.NetworkSettings.WaitForTimeOut = 120000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 30000
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 1800000
    ConnectionParams.NetworkSettings.ConnectRetryCount = 10
    ConnectionParams.NetworkSettings.ConnectDelay = 60000
    ConnectionParams.NetworkSettings.UseServerSettings = True
    LockParams.Delay = 16
    LockParams.RetryCount = 20000
    Options.MaxSessionCount = 367
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    Left = 280
    Top = 88
  end
  object tEmp: TACRTable
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
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
