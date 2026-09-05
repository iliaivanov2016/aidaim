object Form1: TForm1
  Left = 450
  Top = 223
  Width = 335
  Height = 132
  Caption = 'MsgCommunicator: 2 servers demo'
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
  object GroupBox1: TGroupBox
    Left = 6
    Top = 0
    Width = 153
    Height = 89
    Caption = 'Server1'
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 17
      Width = 45
      Height = 13
      Caption = 'ServerID:'
    end
    object Label3: TLabel
      Left = 9
      Top = 41
      Width = 25
      Height = 13
      Caption = 'Host:'
    end
    object Label4: TLabel
      Left = 9
      Top = 65
      Width = 22
      Height = 13
      Caption = 'Port:'
    end
    object S1ServerID: TEdit
      Left = 59
      Top = 14
      Width = 86
      Height = 21
      TabOrder = 0
    end
    object S1Host: TEdit
      Left = 59
      Top = 38
      Width = 86
      Height = 21
      TabOrder = 1
    end
    object S1Port: TEdit
      Left = 59
      Top = 62
      Width = 86
      Height = 21
      TabOrder = 2
    end
  end
  object GroupBox3: TGroupBox
    Left = 167
    Top = 0
    Width = 153
    Height = 89
    Caption = 'Server2'
    TabOrder = 1
    object Label8: TLabel
      Left = 8
      Top = 17
      Width = 45
      Height = 13
      Caption = 'ServerID:'
    end
    object Label9: TLabel
      Left = 9
      Top = 41
      Width = 25
      Height = 13
      Caption = 'Host:'
    end
    object Label10: TLabel
      Left = 9
      Top = 65
      Width = 22
      Height = 13
      Caption = 'Port:'
    end
    object S2ServerID: TEdit
      Left = 59
      Top = 14
      Width = 86
      Height = 21
      TabOrder = 0
    end
    object S2Host: TEdit
      Left = 59
      Top = 38
      Width = 86
      Height = 21
      TabOrder = 1
    end
    object S2Port: TEdit
      Left = 59
      Top = 62
      Width = 86
      Height = 21
      TabOrder = 2
    end
  end
  object MsgServer1: TMsgServer
    CurrentVersion = '4.00 Pre-release #1'
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
    ConnectionParams.NetworkSettings.PacketSize = 8192
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
    ConnectionParams.NetworkSettings.PingClients = True
    ConnectionParams.NetworkSettings.KeepConnection = True
    ServerID = 1
    StoreMessageHistory = True
    MinUserID = 2
    UseConfigFile = False
    Left = 112
  end
  object MsgServer2: TMsgServer
    CurrentVersion = '4.00 Pre-release #1'
    MaxConnections = 2147483647
    Active = False
    ConfigFileName = 'MsgServer.ini'
    DataPath = '.\Data\'
    ConnectionParams.LocalPort = 12008
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.NetworkSettings.PacketSize = 8192
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
    ConnectionParams.NetworkSettings.PingClients = True
    ConnectionParams.NetworkSettings.KeepConnection = True
    ServerID = 2
    StoreMessageHistory = True
    MinUserID = 3
    UseConfigFile = False
    Left = 272
  end
end
