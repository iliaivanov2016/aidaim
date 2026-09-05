object Form1: TForm1
  Left = 192
  Top = 103
  Width = 696
  Height = 498
  Caption = 
    'Network ServerTCP demo. (c) AidAim Software, 2009. http://www.ai' +
    'daim.com'
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 688
    Height = 97
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 670
      Height = 48
      Caption = 
        'This demo shows how to transmit data in fast and secure way. The' +
        ' data should be saved to TCPSMemoryStream at first to save time ' +
        'if it consists of many short blocks. After that it should be com' +
        'pressed, encrypted and sent to remote machine. Received data sho' +
        'uld be decrypted and decompressed.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object RichEdit1: TRichEdit
    Left = 0
    Top = 97
    Width = 688
    Height = 337
    Align = alTop
    TabOrder = 1
  end
  object bnClose: TButton
    Left = 288
    Top = 441
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 2
    OnClick = bnCloseClick
  end
  object CPSManager1: TCPSManager
    CurrentVersion = '2.00 '
    CompressionAlgorithm = caZLIB
    CompressionMode = 6
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
    Left = 80
    Top = 136
  end
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    DefaultPort = 44444
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    OnExecute = IdTCPServer1Execute
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    TerminateWaitTime = 500000
    Left = 136
    Top = 136
  end
end
