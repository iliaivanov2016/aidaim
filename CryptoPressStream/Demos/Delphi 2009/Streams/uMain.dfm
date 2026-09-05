object fmMain: TfmMain
  Left = 192
  Top = 103
  BorderStyle = bsDialog
  Caption = 
    'Streams demo. (c) AidAim Software, 2004-2008. http://www.aidaim.' +
    'com'
  ClientHeight = 410
  ClientWidth = 432
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
  object Gauge1: TGauge
    Left = 8
    Top = 311
    Width = 408
    Height = 24
    ForeColor = clBlue
    Progress = 0
  end
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 24
    Height = 13
    Caption = 'Log: '
  end
  object Label2: TLabel
    Left = 216
    Top = 8
    Width = 27
    Height = 13
    Caption = 'Text: '
  end
  object lbOperation: TLabel
    Left = 8
    Top = 289
    Width = 385
    Height = 13
    Alignment = taCenter
    AutoSize = False
  end
  object reLog: TRichEdit
    Left = 8
    Top = 28
    Width = 185
    Height = 249
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
    WantTabs = True
  end
  object bnFileStream: TButton
    Left = 8
    Top = 378
    Width = 75
    Height = 25
    Caption = 'FileStream'
    TabOrder = 1
    OnClick = bnFileStreamClick
  end
  object bnMemoryStream: TButton
    Left = 100
    Top = 378
    Width = 89
    Height = 25
    Caption = 'MemoryStream'
    TabOrder = 2
    OnClick = bnMemoryStreamClick
  end
  object Button3: TButton
    Left = 207
    Top = 378
    Width = 107
    Height = 25
    Caption = 'CompressedStream'
    TabOrder = 3
    OnClick = Button3Click
  end
  object bnClose: TButton
    Left = 333
    Top = 378
    Width = 81
    Height = 25
    Caption = 'Exit'
    TabOrder = 4
    OnClick = bnCloseClick
  end
  object reText: TRichEdit
    Left = 215
    Top = 28
    Width = 198
    Height = 249
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 5
    WantTabs = True
  end
  object bnAbort: TBitBtn
    Left = 171
    Top = 343
    Width = 75
    Height = 25
    Caption = 'Abort'
    DoubleBuffered = True
    Kind = bkCancel
    ParentDoubleBuffered = False
    TabOrder = 6
    OnClick = bnAbortClick
  end
  object CPSManager1: TCPSManager
    CompressionAlgorithm = caPPM
    CompressionMode = 9
    BlockSize = 100000
    NumCachedBlocks = 1
    MaxTempBufferSize = 10485760
    CryptoParams.CryptoAlgorithm = craBlowfish
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'password'
    CryptoParams.UseInitVector = False
    OnProgress = CPSManager1Progress
    TempDir = 'C:\DOCUME~1\leo\LOCALS~1\Temp\'
    Left = 8
    Top = 345
  end
end
