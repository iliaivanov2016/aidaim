object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 
    'SQL demo for SQLMemTable. (c) AidAim Software, 2009. http://www.' +
    'aidaim.com'
  ClientHeight = 573
  ClientWidth = 792
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
  object reSQL: TRichEdit
    Left = 0
    Top = 0
    Width = 792
    Height = 265
    Align = alTop
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 265
    Width = 792
    Height = 48
    Align = alTop
    TabOrder = 1
    object lbRecCount: TLabel
      Left = 274
      Top = 20
      Width = 124
      Height = 13
      AutoSize = False
      Caption = 'RecordCount: '
    end
    object lbTime: TLabel
      Left = 408
      Top = 20
      Width = 124
      Height = 13
      AutoSize = False
      Caption = 'Time, seconds: '
    end
    object bnOpen: TButton
      Left = 8
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Open Query'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = bnOpenClick
    end
    object bnExecSQL: TButton
      Left = 100
      Top = 14
      Width = 75
      Height = 25
      Caption = 'ExecSQL'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = bnExecSQLClick
    end
    object bnClose: TButton
      Left = 192
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 2
      OnClick = bnCloseClick
    end
    object DBNavigator1: TDBNavigator
      Left = 544
      Top = 14
      Width = 240
      Height = 25
      DataSource = DataSource1
      TabOrder = 3
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 313
    Width = 792
    Height = 260
    Align = alClient
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object ACRQuery1: TACRQuery
    CurrentVersion = '4.80 '
    DatabaseName = 'AccuracerDB_312760951'
    InMemory = False
    ReadOnly = True
    SQL.Strings = (
      'SELECT * FROM orders '
      'WHERE YEAR(SaleDate) > 1990'
      'ORDER BY CustNo')
    Left = 392
    Top = 208
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 4.800000000000000000
    DatabaseFileName = '.\..\..\Data\DBDemos.adb'
    DatabaseName = 'AccuracerDB_312760951'
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
    ConnectionParams.NetworkSettings.CommandRetryCount = 10
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 600000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 10000
    ConnectionParams.NetworkSettings.SendTimeOut = 180000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 300
    ConnectionParams.NetworkSettings.RequestDelay = 300
    ConnectionParams.NetworkSettings.WaitForTimeOut = 120000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 30000
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 60000
    ConnectionParams.NetworkSettings.ConnectRetryCount = 20
    ConnectionParams.NetworkSettings.ConnectDelay = 500
    ConnectionParams.NetworkSettings.UseServerSettings = True
    LockParams.Delay = 500
    LockParams.RetryCount = 20
    Options.MaxSessionCount = 2
    Options.PageSize = 4096
    Options.ExtentPageCount = 4
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    Left = 296
    Top = 208
  end
  object DataSource1: TDataSource
    DataSet = ACRQuery1
    Left = 464
    Top = 208
  end
end
