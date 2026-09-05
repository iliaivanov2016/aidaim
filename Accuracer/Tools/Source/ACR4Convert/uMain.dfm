object fmMain: TfmMain
  Left = 40
  Top = 150
  Caption = 
    'Accuracer Converter 4 <=> 5. (c) AidAim Software, 2009-2011. htt' +
    'p://www.aidaim.com'
  ClientHeight = 473
  ClientWidth = 792
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
  object Splitter1: TSplitter
    Left = 385
    Top = 0
    Height = 288
  end
  object Panel1: TPanel
    Left = 0
    Top = 288
    Width = 792
    Height = 185
    Align = alBottom
    TabOrder = 0
    object gIndicator: TGauge
      Left = 581
      Top = 5
      Width = 200
      Height = 24
      ForeColor = clBlue
      Progress = 0
    end
    object bn4To5Beta: TButton
      Left = 96
      Top = 5
      Width = 121
      Height = 25
      Caption = 'Accuracer 4 => 5'
      TabOrder = 0
      OnClick = bn4To5BetaClick
    end
    object bn4OpenClose: TButton
      Left = 6
      Top = 5
      Width = 75
      Height = 25
      Caption = 'ACR4 Open'
      TabOrder = 1
      OnClick = bn4OpenCloseClick
    end
    object bnExit: TButton
      Left = 341
      Top = 5
      Width = 44
      Height = 25
      Caption = 'Exit'
      TabOrder = 2
      OnClick = bnExitClick
    end
    object bn5BetaOpenClose: TButton
      Left = 392
      Top = 5
      Width = 73
      Height = 25
      Caption = 'ACR5 Open'
      TabOrder = 3
      OnClick = bn5BetaOpenCloseClick
    end
    object bn5BetaTo4: TButton
      Left = 472
      Top = 5
      Width = 97
      Height = 25
      Caption = 'Accuracer 5 => 4'
      TabOrder = 4
      OnClick = bn5BetaTo4Click
    end
    object reLog: TRichEdit
      Left = 1
      Top = 34
      Width = 790
      Height = 150
      Align = alBottom
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 5
    end
    object cbTransactions: TCheckBox
      Left = 224
      Top = 9
      Width = 105
      Height = 17
      Caption = 'Use Transactions'
      Checked = True
      State = cbChecked
      TabOrder = 6
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 385
    Height = 288
    Align = alLeft
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 122
      Top = 42
      Height = 245
    end
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 383
      Height = 41
      Align = alTop
      TabOrder = 0
      object Label1: TLabel
        Left = 6
        Top = 11
        Width = 50
        Height = 13
        Caption = 'ACR 4 file:'
      end
      object eDB4File: TEdit
        Left = 64
        Top = 7
        Width = 270
        Height = 21
        TabOrder = 0
      end
      object bn4Browse: TButton
        Left = 344
        Top = 5
        Width = 33
        Height = 25
        Caption = '...'
        TabOrder = 1
        OnClick = bn4BrowseClick
      end
    end
    object lb4Tables: TListBox
      Left = 1
      Top = 42
      Width = 121
      Height = 245
      Align = alLeft
      ItemHeight = 13
      MultiSelect = True
      TabOrder = 1
      OnClick = lb4TablesClick
    end
    object Panel6: TPanel
      Left = 125
      Top = 42
      Width = 259
      Height = 245
      Align = alClient
      TabOrder = 2
      object DBGrid1: TDBGrid
        Left = 1
        Top = 1
        Width = 257
        Height = 218
        Align = alClient
        DataSource = ds4
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
      object DBNavigator1: TDBNavigator
        Left = 1
        Top = 219
        Width = 257
        Height = 25
        DataSource = ds4
        Align = alBottom
        TabOrder = 1
      end
    end
  end
  object Panel3: TPanel
    Left = 388
    Top = 0
    Width = 404
    Height = 288
    Align = alClient
    TabOrder = 2
    object Splitter3: TSplitter
      Left = 122
      Top = 42
      Height = 245
    end
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 402
      Height = 41
      Align = alTop
      TabOrder = 0
      object Label2: TLabel
        Left = 6
        Top = 11
        Width = 50
        Height = 13
        Caption = 'ACR 5 file:'
      end
      object eDB5File: TEdit
        Left = 64
        Top = 7
        Width = 270
        Height = 21
        TabOrder = 0
      end
      object bn5Browse: TButton
        Left = 344
        Top = 5
        Width = 33
        Height = 25
        Caption = '...'
        TabOrder = 1
        OnClick = bn5BrowseClick
      end
    end
    object lb5Tables: TListBox
      Left = 1
      Top = 42
      Width = 121
      Height = 245
      Align = alLeft
      ItemHeight = 13
      MultiSelect = True
      TabOrder = 1
      OnClick = lb5TablesClick
    end
    object Panel7: TPanel
      Left = 125
      Top = 42
      Width = 278
      Height = 245
      Align = alClient
      TabOrder = 2
      object DBGrid2: TDBGrid
        Left = 1
        Top = 1
        Width = 276
        Height = 218
        Align = alClient
        DataSource = ds5
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
      object DBNavigator2: TDBNavigator
        Left = 1
        Top = 219
        Width = 276
        Height = 25
        DataSource = ds5
        Align = alBottom
        TabOrder = 1
      end
    end
  end
  object ds4: TDataSource
    DataSet = ACR4Table
    Left = 341
    Top = 170
  end
  object ds5: TDataSource
    DataSet = ACR5Table
    Left = 404
    Top = 168
  end
  object ACR5DB: TACRDatabase
    FormatVersion = 5.900000000000000000
    DatabaseName = 'ACR5'
    InMemory = False
    SessionName = 'Default'
    Exclusive = True
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
    LockParams.Delay = 1
    LockParams.RetryCount = 120000
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
    CaseInsensitive = False
    Left = 468
    Top = 168
  end
  object ACR5Table: TACRTable
    CurrentVersion = '5.90 '
    InMemory = False
    DatabaseName = 'ACR5'
    ReadOnly = False
    AfterOpen = ACR5TableAfterOpen
    AfterClose = ACR5TableAfterClose
    CaseInsensitive = False
    Exclusive = True
    MemoryTableAllocBy = 1000
    OnProgress = ACR5TableProgress
    Left = 468
    Top = 208
  end
  object ACR4Table: TAC4Table
    CurrentVersion = '4.97 '
    InMemory = False
    DatabaseName = 'ACR4'
    ReadOnly = False
    AfterOpen = ACR4TableAfterOpen
    AfterClose = ACR4TableAfterClose
    Exclusive = True
    MemoryTableAllocBy = 1000
    Left = 349
    Top = 218
  end
  object ACR4DB: TAC4Database
    FormatVersion = 4.970000000000000000
    DatabaseName = 'ACR4'
    InMemory = False
    SessionName = 'Default'
    Exclusive = True
    BackupParams.CompressionAlgorithm = caNone
    BackupParams.CompressionMode = 1
    BackupParams.CryptoParams.CryptoAlgorithm = craNone
    BackupParams.CryptoParams.CryptoMode = acmCTS
    BackupParams.CryptoParams.KeySize = 56
    BackupParams.CryptoParams.Password = 'AC4password'
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
    ConnectionParams.CryptoParams.Password = 'AC4password'
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
    Options.MaxSessionCount = 1
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'AC4password'
    CryptoParams.UseInitVector = False
    Left = 301
    Top = 218
  end
  object od4: TOpenDialog
    Filter = 'Accuracer files (*.adb)|*.adb|Any files (*.*)|Any files (*.*)'
    Title = 'Select Accuracer 4 file'
    Left = 305
    Top = 17
  end
  object od5: TOpenDialog
    Filter = 'Accuracer files (*.adb)|*.adb|Any files (*.*)|Any files (*.*)'
    Title = 'Select Accuracer 5 file'
    Left = 593
    Top = 25
  end
end
