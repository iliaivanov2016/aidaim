object Form1: TForm1
  Left = 339
  Top = 153
  Width = 442
  Height = 295
  Caption = 'Custom Commands: MsgCommunicator Demo. (c) 2005 AidAim Software'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 23
    Width = 90
    Height = 13
    Caption = 'Command Number:'
  end
  object Label2: TLabel
    Left = 90
    Top = 0
    Width = 40
    Height = 16
    Caption = 'Client'
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object Label3: TLabel
    Left = 9
    Top = 44
    Width = 76
    Height = 13
    Caption = 'Command Data:'
  end
  object Label4: TLabel
    Left = 226
    Top = 23
    Width = 90
    Height = 13
    Caption = 'Command Number:'
  end
  object Label5: TLabel
    Left = 309
    Top = 0
    Width = 47
    Height = 16
    Caption = 'Server'
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object Label6: TLabel
    Left = 227
    Top = 44
    Width = 76
    Height = 13
    Caption = 'Command Data:'
  end
  object Label7: TLabel
    Left = 8
    Top = 184
    Width = 37
    Height = 13
    Caption = 'Sent at:'
  end
  object Label8: TLabel
    Left = 8
    Top = 209
    Width = 61
    Height = 13
    Caption = 'Received at:'
  end
  object Label9: TLabel
    Left = 225
    Top = 184
    Width = 37
    Height = 13
    Caption = 'Sent at:'
  end
  object Label10: TLabel
    Left = 225
    Top = 209
    Width = 61
    Height = 13
    Caption = 'Received at:'
  end
  object Edit1: TEdit
    Left = 104
    Top = 20
    Width = 106
    Height = 21
    TabOrder = 0
    Text = '1'
  end
  object Memo1: TMemo
    Left = 8
    Top = 63
    Width = 203
    Height = 113
    Lines.Strings = (
      'Text1')
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Button1: TButton
    Left = 58
    Top = 232
    Width = 105
    Height = 25
    Caption = 'Send To Server'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Edit2: TEdit
    Left = 324
    Top = 20
    Width = 103
    Height = 21
    TabOrder = 3
    Text = '22'
  end
  object Memo2: TMemo
    Left = 227
    Top = 63
    Width = 201
    Height = 113
    Lines.Strings = (
      'Text2')
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object Button2: TButton
    Left = 282
    Top = 232
    Width = 105
    Height = 25
    Caption = 'Send To Client'
    TabOrder = 5
    OnClick = Button2Click
  end
  object ClientReceivedTime: TEdit
    Left = 72
    Top = 206
    Width = 140
    Height = 21
    TabOrder = 6
  end
  object ClientSentTime: TEdit
    Left = 72
    Top = 181
    Width = 140
    Height = 21
    TabOrder = 7
  end
  object ServerSentTime: TEdit
    Left = 289
    Top = 181
    Width = 140
    Height = 21
    TabOrder = 8
  end
  object ServerReceivedTime: TEdit
    Left = 289
    Top = 206
    Width = 140
    Height = 21
    TabOrder = 9
  end
  object MsgClient1: TMsgClient
    CurrentVersion = '4.00 Pre-release #1'
    IncomingPath = 'F:\Compilers\Delphi7\Bin\Incoming\'
    OnReceiveCommand = MsgClient1ReceiveCommand
    UserID = -1
    StoreMessageHistory = True
    Logged = False
    ConnectionParams.LocalPort = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.RemoteHost = '127.0.0.1'
    ConnectionParams.RemotePort = 12007
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.ServerID = 0
    ConnectionParams.NetworkSettings.PacketSize = 1500
    ConnectionParams.NetworkSettings.MaxThreadCount = 100
    ConnectionParams.NetworkSettings.ConnectionParamsTunning = False
    ConnectionParams.NetworkSettings.TestPacketCount = 8
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 5
    ConnectionParams.NetworkSettings.DisconnectDelay = 300
    ConnectionParams.NetworkSettings.RestoreDefaultSettings = msgLAN
    ConnectionParams.NetworkSettings.ConnectRetryCount = 5
    ConnectionParams.NetworkSettings.ConnectDelay = 500
    ConnectionParams.NetworkSettings.StartReceiveTimeOut = 60000
    ConnectionParams.NetworkSettings.ReceiveTimeOut = 600000
    ConnectionParams.NetworkSettings.ReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinSendTimeOut = 10000
    ConnectionParams.NetworkSettings.SendTimeOut = 10000
    ConnectionParams.NetworkSettings.WaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ResendDelay = 300
    ConnectionParams.NetworkSettings.RequestDelay = 300
    ConnectionParams.NetworkSettings.WaitForTimeOut = 5000
    ConnectionParams.NetworkSettings.ThreadsTerminateDelay = 3000
    ConnectionParams.NetworkSettings.UseServerSettings = False
    Left = 88
    Top = 112
  end
  object MsgServer1: TMsgServer
    CurrentVersion = '4.00 Pre-release #1'
    OnReceiveCommand = MsgServer1ReceiveCommand
    MaxConnections = 2147483647
    Active = False
    ConfigFileName = 'MsgServer.ini'
    DataPath = '.\Data\'
    ConnectionParams.LocalPort = 12007
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.NetworkSettings.PacketSize = 1500
    ConnectionParams.NetworkSettings.MaxThreadCount = 100
    ConnectionParams.NetworkSettings.ConnectionParamsTunning = False
    ConnectionParams.NetworkSettings.TestPacketCount = 8
    ConnectionParams.NetworkSettings.DisconnectRetryCount = 12
    ConnectionParams.NetworkSettings.DisconnectDelay = 300
    ConnectionParams.NetworkSettings.RestoreDefaultSettings = msgLAN
    ConnectionParams.NetworkSettings.ServerReceiveTimeOut = 300000
    ConnectionParams.NetworkSettings.ServerReceiveSleep = 1
    ConnectionParams.NetworkSettings.MinServerSendTimeOut = 60000
    ConnectionParams.NetworkSettings.ServerSendTimeOut = 600000
    ConnectionParams.NetworkSettings.ServerWaitForSendSleep = 0
    ConnectionParams.NetworkSettings.ServerResendDelay = 200
    ConnectionParams.NetworkSettings.ServerRequestDelay = 100
    ConnectionParams.NetworkSettings.WaitForMessagesSend = 300000
    ConnectionParams.NetworkSettings.WaitForServerSessionThreadTimeOut = 120000
    ConnectionParams.NetworkSettings.ServerThreadsTerminateDelay = 1000
    ConnectionParams.NetworkSettings.ServerSessionTerminatorSleep = 100
    ConnectionParams.NetworkSettings.PingCount = 8
    ConnectionParams.NetworkSettings.WaitForPingAnswer = 30000
    ConnectionParams.NetworkSettings.ServerPingSleep = 20
    ConnectionParams.NetworkSettings.PingClients = False
    ConnectionParams.NetworkSettings.KeepConnection = True
    ServerID = 0
    StoreMessageHistory = True
    MinUserID = 1
    UseConfigFile = False
    Left = 312
    Top = 112
  end
end
