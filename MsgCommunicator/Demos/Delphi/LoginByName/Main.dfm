object Form1: TForm1
  Left = 370
  Top = 287
  Width = 209
  Height = 155
  Caption = 
    'LoginByName: MsgCommunicator Demo. (c) 2007 - 2011 AidAim Softwa' +
    're'
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
    Left = 6
    Top = 13
    Width = 29
    Height = 13
    Caption = 'Login:'
  end
  object Label2: TLabel
    Left = 6
    Top = 40
    Width = 49
    Height = 13
    Caption = 'Password:'
  end
  object lbUserID: TLabel
    Left = 8
    Top = 104
    Width = 36
    Height = 13
    Caption = 'UserID:'
  end
  object cbLogin: TComboBox
    Left = 63
    Top = 9
    Width = 131
    Height = 21
    ItemHeight = 13
    TabOrder = 0
  end
  object Password: TEdit
    Left = 63
    Top = 37
    Width = 131
    Height = 21
    TabOrder = 1
    Text = 'msgpassword'
  end
  object btnLogin: TButton
    Left = 64
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Login'
    TabOrder = 2
    OnClick = btnLoginClick
  end
  object MsgClient1: TMsgClient
    CurrentVersion = '4.50 '
    IncomingPath = 'D:\Program Files\Borland\Delphi7\Bin\Incoming\'
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
    Left = 8
    Top = 64
  end
end
