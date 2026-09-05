object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 
    'TwoMemoryDatabases demo. (c) AidAim Software, 2009. http://www.a' +
    'idaim.com'
  ClientHeight = 533
  ClientWidth = 792
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 385
    Top = 0
    Height = 392
  end
  object Panel1: TPanel
    Left = 0
    Top = 392
    Width = 792
    Height = 141
    Align = alBottom
    TabOrder = 0
    object Panel2: TPanel
      Left = 1
      Top = 99
      Width = 790
      Height = 41
      Align = alBottom
      TabOrder = 0
      object Button1: TButton
        Left = 7
        Top = 8
        Width = 99
        Height = 25
        Caption = 'Create Databases'
        TabOrder = 0
        OnClick = Button1Click
      end
      object Button2: TButton
        Left = 108
        Top = 8
        Width = 85
        Height = 25
        Caption = 'SELECT from #1'
        Enabled = False
        TabOrder = 1
        OnClick = Button2Click
      end
      object Button3: TButton
        Left = 194
        Top = 8
        Width = 85
        Height = 25
        Caption = 'SELECT from #2'
        Enabled = False
        TabOrder = 2
        OnClick = Button3Click
      end
      object bnExit: TButton
        Left = 744
        Top = 8
        Width = 41
        Height = 25
        Caption = 'Exit'
        TabOrder = 3
        OnClick = bnExitClick
      end
      object Button4: TButton
        Left = 284
        Top = 8
        Width = 95
        Height = 25
        Caption = 'SELECTwith JOIN'
        Enabled = False
        TabOrder = 4
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 492
        Top = 8
        Width = 46
        Height = 25
        Caption = 'Update'
        Enabled = False
        TabOrder = 5
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 539
        Top = 8
        Width = 42
        Height = 25
        Caption = 'Delete'
        Enabled = False
        TabOrder = 6
        OnClick = Button6Click
      end
      object Button7: TButton
        Left = 587
        Top = 8
        Width = 90
        Height = 25
        Caption = 'Drop Databases'
        Enabled = False
        TabOrder = 7
        OnClick = Button7Click
      end
      object bnRunSQL: TButton
        Left = 681
        Top = 8
        Width = 59
        Height = 25
        Caption = 'Run SQL'
        TabOrder = 8
        OnClick = bnRunSQLClick
      end
      object Button8: TButton
        Left = 383
        Top = 8
        Width = 105
        Height = 25
        Caption = 'SELECTwith UNION'
        Enabled = False
        TabOrder = 9
        OnClick = Button8Click
      end
    end
    object reSQL: TRichEdit
      Left = 1
      Top = 1
      Width = 790
      Height = 98
      Align = alClient
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
  object gbDB1: TGroupBox
    Left = 0
    Top = 0
    Width = 385
    Height = 392
    Align = alLeft
    Caption = ' Database #1: '
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 137
      Top = 15
      Height = 350
    end
    object lbTables1: TListBox
      Left = 2
      Top = 15
      Width = 135
      Height = 350
      Align = alLeft
      ItemHeight = 13
      TabOrder = 0
    end
    object DBGrid1: TDBGrid
      Left = 140
      Top = 15
      Width = 243
      Height = 350
      Align = alClient
      DataSource = DS1
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object DBNavigator1: TDBNavigator
      Left = 2
      Top = 365
      Width = 381
      Height = 25
      DataSource = DS1
      Align = alBottom
      TabOrder = 2
    end
  end
  object gbDB2: TGroupBox
    Left = 388
    Top = 0
    Width = 404
    Height = 392
    Align = alClient
    Caption = ' Database #2: '
    TabOrder = 2
    object Splitter3: TSplitter
      Left = 137
      Top = 15
      Height = 350
    end
    object lbTables2: TListBox
      Left = 2
      Top = 15
      Width = 135
      Height = 350
      Align = alLeft
      ItemHeight = 13
      TabOrder = 0
    end
    object DBGrid2: TDBGrid
      Left = 140
      Top = 15
      Width = 262
      Height = 350
      Align = alClient
      DataSource = DS2
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object DBNavigator2: TDBNavigator
      Left = 2
      Top = 365
      Width = 400
      Height = 25
      DataSource = DS2
      Align = alBottom
      TabOrder = 2
    end
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 4.950000000000000000
    DatabaseName = 'Database #1'
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
    Left = 336
    Top = 24
  end
  object ACRDatabase2: TACRDatabase
    FormatVersion = 4.950000000000000000
    DatabaseName = 'Database #2'
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
    Left = 404
    Top = 24
  end
  object ACRQuery1: TACRQuery
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
    DatabaseName = 'Database #1'
    ReadOnly = False
    Left = 336
    Top = 72
  end
  object ACRTable1: TACRTable
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
    DatabaseName = 'Database #1'
    ReadOnly = False
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 336
    Top = 112
  end
  object ACRTable2: TACRTable
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
    DatabaseName = 'Database #2'
    ReadOnly = False
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 404
    Top = 112
  end
  object ACRQuery2: TACRQuery
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = False
    DatabaseName = 'Database #2'
    ReadOnly = False
    Left = 404
    Top = 72
  end
  object DS1: TDataSource
    Left = 344
    Top = 160
  end
  object DS2: TDataSource
    Left = 404
    Top = 160
  end
  object ACRQuery3: TACRQuery
    CurrentVersion = '4.95 Prerelease Version #4'
    InMemory = True
    DatabaseName = 'MEMORY'
    ReadOnly = False
    Left = 664
    Top = 448
  end
end
