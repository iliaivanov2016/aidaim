object Form1: TForm1
  Left = 192
  Top = 107
  Width = 800
  Height = 600
  Caption = 
    'ChangesDetectionMultiUser demo. (c) AidAim Software, 2010. http:' +
    '//www.aidaim.com'
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
  object Splitter1: TSplitter
    Left = 401
    Top = 129
    Width = 3
    Height = 444
    Cursor = crHSplit
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 792
    Height = 129
    Align = alTop
    TabOrder = 0
    object Panel4: TPanel
      Left = 1
      Top = 42
      Width = 88
      Height = 86
      Align = alLeft
      TabOrder = 0
      object Button1: TButton
        Left = 6
        Top = 30
        Width = 75
        Height = 25
        Caption = 'Close'
        TabOrder = 0
        OnClick = Button1Click
      end
    end
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 790
      Height = 41
      Align = alTop
      TabOrder = 1
      object Label1: TLabel
        Left = 1
        Top = 1
        Width = 788
        Height = 39
        Align = alClient
        AutoSize = False
        Caption = 
          'This demo shows how to detect changes made by other users in Fil' +
          'e-Server (Multi-User) mode using GetTableState method of TACRDat' +
          'abase. Same technique can be used for client-server: set the Loc' +
          'alDatabase to False and setup the ConnectionParams in both TACRD' +
          'atabase components.'
        WordWrap = True
      end
    end
    object Panel6: TPanel
      Left = 89
      Top = 42
      Width = 702
      Height = 86
      Align = alClient
      TabOrder = 2
      object reLog: TRichEdit
        Left = 1
        Top = 1
        Width = 700
        Height = 84
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 129
    Width = 401
    Height = 444
    Align = alLeft
    TabOrder = 1
    object DBGrid1: TDBGrid
      Left = 1
      Top = 1
      Width = 399
      Height = 417
      Align = alClient
      DataSource = ds1
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object DBNavigator1: TDBNavigator
      Left = 1
      Top = 418
      Width = 399
      Height = 25
      DataSource = ds1
      Align = alBottom
      TabOrder = 1
    end
  end
  object Panel3: TPanel
    Left = 404
    Top = 129
    Width = 388
    Height = 444
    Align = alClient
    TabOrder = 2
    object DBGrid2: TDBGrid
      Left = 1
      Top = 1
      Width = 386
      Height = 417
      Align = alClient
      DataSource = ds2
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object DBNavigator2: TDBNavigator
      Left = 1
      Top = 418
      Width = 386
      Height = 25
      DataSource = ds2
      Align = alBottom
      TabOrder = 1
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 40
    Top = 105
  end
  object db1: TACRDatabase
    FormatVersion = 5.11
    DatabaseName = 'db1'
    InMemory = False
    SessionName = 'Default'
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
    ConnectionParams.LocalPort = 0
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
    ConnectionParams.NetworkSettings.PacketSize = 1492
    ConnectionParams.NetworkSettings.MaxThreadCount = 2147483647
    ConnectionParams.NetworkSettings.ConnectionParamsTunning = False
    ConnectionParams.NetworkSettings.TestPacketCount = 8
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 12
    ConnectionParams.NetworkSettings.DisconnectDelay = 300
    ConnectionParams.NetworkSettings.CommandRetryCount = 5
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 60000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 30000
    ConnectionParams.NetworkSettings.SendTimeOut = 300000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 300
    ConnectionParams.NetworkSettings.RequestDelay = 300
    ConnectionParams.NetworkSettings.WaitForTimeOut = 120000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 30000
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 30000
    ConnectionParams.NetworkSettings.RestoreDefaultSettings = ACRLocal
    ConnectionParams.NetworkSettings.ConnectRetryCount = 30
    ConnectionParams.NetworkSettings.ConnectDelay = 1000
    ConnectionParams.NetworkSettings.UseServerSettings = False
    LockParams.Delay = 1
    LockParams.RetryCount = 1000
    Options.MaxSessionCount = 405
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    Left = 112
    Top = 201
  end
  object db2: TACRDatabase
    FormatVersion = 5.11
    DatabaseName = 'db2'
    InMemory = False
    SessionName = 'Default'
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
    ConnectionParams.LocalPort = 0
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
    ConnectionParams.NetworkSettings.PacketSize = 1492
    ConnectionParams.NetworkSettings.MaxThreadCount = 2147483647
    ConnectionParams.NetworkSettings.ConnectionParamsTunning = False
    ConnectionParams.NetworkSettings.TestPacketCount = 8
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 12
    ConnectionParams.NetworkSettings.DisconnectDelay = 300
    ConnectionParams.NetworkSettings.CommandRetryCount = 5
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 60000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 30000
    ConnectionParams.NetworkSettings.SendTimeOut = 300000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 300
    ConnectionParams.NetworkSettings.RequestDelay = 300
    ConnectionParams.NetworkSettings.WaitForTimeOut = 120000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 30000
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 30000
    ConnectionParams.NetworkSettings.RestoreDefaultSettings = ACRLocal
    ConnectionParams.NetworkSettings.ConnectRetryCount = 30
    ConnectionParams.NetworkSettings.ConnectDelay = 1000
    ConnectionParams.NetworkSettings.UseServerSettings = False
    LockParams.Delay = 1
    LockParams.RetryCount = 1000
    Options.MaxSessionCount = 405
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    Left = 436
    Top = 193
  end
  object t1: TACRTable
    CurrentVersion = '5.11 '
    InMemory = False
    DatabaseName = 'db1'
    ReadOnly = False
    TableName = 'test'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 152
    Top = 201
  end
  object t2: TACRTable
    CurrentVersion = '5.11 '
    InMemory = False
    DatabaseName = 'db2'
    ReadOnly = False
    TableName = 'test'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 468
    Top = 193
  end
  object ds1: TDataSource
    DataSet = t1
    Left = 192
    Top = 201
  end
  object ds2: TDataSource
    DataSet = t2
    Left = 508
    Top = 193
  end
end
