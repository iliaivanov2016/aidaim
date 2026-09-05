object Form1: TForm1
  Left = 314
  Top = 232
  Width = 537
  Height = 204
  Caption = 
    'FastMemoryStream demo. (c) AidAim Software, 2009. http://www.aid' +
    'aim.com'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 8
    Width = 460
    Height = 16
    Caption = 
      'This demo shows how to store data in fastest way using TCPSMemor' +
      'yStream.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object bnRunTest: TButton
    Left = 128
    Top = 140
    Width = 75
    Height = 25
    Caption = 'Run Test'
    TabOrder = 0
    OnClick = bnRunTestClick
  end
  object bnClose: TButton
    Left = 288
    Top = 140
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 1
    OnClick = bnCloseClick
  end
  object reLog: TRichEdit
    Left = 32
    Top = 32
    Width = 457
    Height = 97
    PlainText = True
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object CPSManager1: TCPSManager
    CurrentVersion = '2.00 '
    CompressionAlgorithm = caZLIB
    CompressionMode = 1
    BlockSize = 1048576
    NumCachedBlocks = 1
    MaxTempBufferSize = 10485760
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'CPSpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    TempDirAnsi = 'C:\DOCUME~1\leo\LOCALS~1\Temp\'
    TempDirUnicode = 'C:\DOCUME~1\leo\LOCALS~1\Temp\'
    TempDir = 'C:\DOCUME~1\leo\LOCALS~1\Temp\'
    Left = 40
    Top = 72
  end
end
