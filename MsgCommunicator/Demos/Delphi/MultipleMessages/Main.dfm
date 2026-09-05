object Form1: TForm1
  Left = 457
  Top = 272
  Width = 224
  Height = 455
  Caption = 
    'MsgCommunicator: Multiple Messages Demo. (C) 2010 AidAim Softwar' +
    'e'
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
    Left = 16
    Top = 200
    Width = 14
    Height = 13
    Caption = 'log'
  end
  object Memo1: TMemo
    Left = 16
    Top = 40
    Width = 185
    Height = 89
    Lines.Strings = (
      'Hello!')
    TabOrder = 0
  end
  object ServerSend: TButton
    Left = 72
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Server Send'
    TabOrder = 1
    OnClick = ServerSendClick
  end
  object Directly: TRadioButton
    Left = 16
    Top = 168
    Width = 80
    Height = 17
    Caption = 'Directly'
    TabOrder = 2
  end
  object RadioButton1: TRadioButton
    Left = 16
    Top = 144
    Width = 80
    Height = 17
    Caption = 'via Server'
    Checked = True
    TabOrder = 3
    TabStop = True
  end
  object ClientSend: TButton
    Left = 128
    Top = 152
    Width = 75
    Height = 25
    Caption = 'Client Send'
    TabOrder = 4
    OnClick = ClientSendClick
  end
  object Memo2: TMemo
    Left = 16
    Top = 216
    Width = 185
    Height = 193
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object MsgServer1: TMsgServer
    CurrentVersion = '4.50 '
    MaxConnections = 2147483647
    Active = False
    ConfigFileName = 'MsgServer.ini'
    DataPath = 'C:\compilers\Delphi7\Bin\Data\'
    ConnectionParams.LocalPort = 12007
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ServerID = 0
    StoreMessageHistory = True
    MinUserID = 1
    UseConfigFile = False
    Left = 80
    Top = 256
  end
  object MsgClient1: TMsgClient
    CurrentVersion = '4.50 '
    IncomingPath = 'C:\compilers\Delphi7\Bin\Incoming\'
    OnReceiveTextMessage = MsgClient1ReceiveTextMessage
    UserID = -1
    StoreMessageHistory = True
    Logged = False
    ConnectionParams.LocalPort = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.RemoteHost = '127.0.0.1'
    ConnectionParams.RemotePort = 12007
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.ServerID = 0
    Left = 40
    Top = 304
  end
  object MsgClient2: TMsgClient
    CurrentVersion = '4.50 '
    IncomingPath = 'C:\compilers\Delphi7\Bin\Incoming\'
    OnReceiveTextMessage = MsgClient2ReceiveTextMessage
    UserID = -1
    StoreMessageHistory = True
    Logged = False
    ConnectionParams.LocalPort = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.RemoteHost = '127.0.0.1'
    ConnectionParams.RemotePort = 12007
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.ServerID = 0
    Left = 80
    Top = 304
  end
  object MsgClient3: TMsgClient
    CurrentVersion = '4.50 '
    IncomingPath = 'C:\compilers\Delphi7\Bin\Incoming\'
    OnReceiveTextMessage = MsgClient3ReceiveTextMessage
    UserID = -1
    StoreMessageHistory = True
    Logged = False
    ConnectionParams.LocalPort = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'Msgpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.RemoteHost = '127.0.0.1'
    ConnectionParams.RemotePort = 12007
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.ServerID = 0
    Left = 120
    Top = 304
  end
end
