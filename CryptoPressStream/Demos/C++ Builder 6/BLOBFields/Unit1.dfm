object Form1: TForm1
  Left = 192
  Top = 107
  Width = 696
  Height = 480
  Caption = 
    'BLOB fields demo. (c) AidAim Software, 2004. http://www.aida' +
    'im.com'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 0
    Top = 0
    Width = 688
    Height = 201
    Align = alTop
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Panel1: TPanel
    Left = 0
    Top = 412
    Width = 688
    Height = 41
    Align = alBottom
    TabOrder = 1
    object bnCompressTable: TButton
      Left = 8
      Top = 9
      Width = 97
      Height = 25
      Caption = 'Compress Table'
      TabOrder = 0
      OnClick = bnCompressTableClick
    end
    object bnBrowseCompressed: TButton
      Left = 120
      Top = 9
      Width = 153
      Height = 25
      Caption = 'Browse Compressed Table'
      TabOrder = 1
      OnClick = bnBrowseCompressedClick
    end
    object bnExit: TButton
      Left = 588
      Top = 9
      Width = 97
      Height = 25
      Caption = 'Exit'
      TabOrder = 2
      OnClick = bnExitClick
    end
    object DBNavigator1: TDBNavigator
      Left = 304
      Top = 9
      Width = 240
      Height = 25
      DataSource = DataSource1
      TabOrder = 3
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 201
    Width = 688
    Height = 211
    Align = alClient
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 230
      Top = 1
      Width = 4
      Height = 209
      Cursor = crHSplit
    end
    object Image2: TImage
      Left = 1
      Top = 1
      Width = 229
      Height = 209
      Align = alLeft
    end
    object RichEdit2: TRichEdit
      Left = 234
      Top = 1
      Width = 453
      Height = 209
      Align = alClient
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WantTabs = True
    end
  end
  object CPSManager1: TCPSManager
    CompressionAlgorithm = caBZIP
    CompressionMode = 9
    BlockSize = 1048576
    NumCachedBlocks = 1
    MaxTempBufferSize = 10485760
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'CPSpassword'
    CryptoParams.UseInitVector = False
    TempDir = 'C:\DOCUME~1\leo\LOCALS~1\Temp\'
    Left = 24
    Top = 72
  end
  object tSource: TTable
    DatabaseName = 'DBDEMOS'
    TableName = 'biolife.db'
    Left = 96
    Top = 48
  end
  object DataSource1: TDataSource
    DataSet = tDest
    Left = 152
    Top = 24
  end
  object DataSource2: TDataSource
    DataSet = tSource
    Left = 96
    Top = 16
  end
  object tDest: TTable
    AfterScroll = tDestAfterScroll
    ReadOnly = True
    TableName = 'biolife'
    Left = 144
    Top = 56
  end
end
