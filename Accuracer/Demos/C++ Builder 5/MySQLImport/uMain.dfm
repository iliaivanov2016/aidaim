object Form1: TForm1
  Left = 214
  Top = 412
  Width = 696
  Height = 480
  Caption = 'Form1'
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
  object Panel1: TPanel
    Left = 0
    Top = 22
    Width = 688
    Height = 187
    Hint = 'Scroll grid below to see other fish'
    Align = alTop
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    object lbField1: TLabel
      Left = 2
      Top = 176
      Width = 45
      Height = 13
      Caption = 'Graphic'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBMemo1: TDBMemo
      Left = 297
      Top = 1
      Width = 390
      Height = 185
      Align = alClient
      Ctl3D = False
      DataField = 'Notes'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object DBImage1: TDBImage
      Left = 1
      Top = 1
      Width = 296
      Height = 185
      Align = alLeft
      DataField = 'graphic'
      DataSource = DataSource1
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 688
    Height = 22
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object DBLabel2: TDBText
      Left = 19
      Top = 4
      Width = 69
      Height = 16
      AutoSize = True
      DataField = 'Common_name'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 209
    Width = 688
    Height = 244
    Align = alClient
    BevelOuter = bvNone
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    object Panel5: TPanel
      Left = 587
      Top = 0
      Width = 101
      Height = 219
      Align = alRight
      BevelInner = bvRaised
      BevelOuter = bvLowered
      TabOrder = 0
      object ConnectBtn: TBitBtn
        Left = 6
        Top = 127
        Width = 89
        Height = 25
        Hint = 'Set connection parameters'
        Caption = '&Connect...'
        Default = True
        TabOrder = 0
        OnClick = ConnectBtnClick
        Glyph.Data = {
          76010000424D7601000000000000760000002800000020000000100000000100
          04000000000000010000120B0000120B00001000000000000000000000000000
          800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333000000000
          00333FF777777777773F0000FFFFFFFFFF0377773F3F3F3F3F7308880F0F0F0F
          0FF07F33737373737337088880FFFFFFFFF07F3337FFFFFFFFF7088880000000
          00037F3337777777777308888033330F03337F3337F3FF7F7FFF088880300000
          00007F3337F7777777770FFFF030FFFFFFF07F3FF7F7F3FFFFF708008030F000
          00F07F7737F7F77777F70FFFF030F0AAE0F07F3FF7F7F7F337F708008030F0DA
          D0F07F7737F7F7FFF7F70FFFF030F00000F07F33F7F7F77777370FF9F030FFFF
          FFF07F3737F7FFFFFFF70FFFF030000000007FFFF7F777777777000000333333
          3333777777333333333333333333333333333333333333333333}
        NumGlyphs = 2
      end
      object btnExit: TBitBtn
        Left = 6
        Top = 165
        Width = 89
        Height = 25
        Hint = 'Close Fish Facts'
        Caption = 'e&Xit'
        TabOrder = 1
        Kind = bkClose
      end
      object ImportBtn: TBitBtn
        Left = 6
        Top = 88
        Width = 89
        Height = 25
        Caption = 'Import Data'
        TabOrder = 2
        OnClick = ImportBtnClick
        Kind = bkOK
      end
      object RadioGroup1: TRadioGroup
        Left = 7
        Top = 7
        Width = 87
        Height = 72
        Caption = ' Show From: '
        ItemIndex = 0
        Items.Strings = (
          'MySQL'
          'Accuracer')
        TabOrder = 3
        OnClick = RadioGroup1Click
      end
    end
    object DBGrid1: TDBGrid
      Left = 0
      Top = 0
      Width = 587
      Height = 219
      Hint = 'Scroll up/down to see other fish!'
      Align = alClient
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clBlack
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object DBNavigator1: TDBNavigator
      Left = 0
      Top = 219
      Width = 688
      Height = 25
      DataSource = DataSource1
      Align = alBottom
      Flat = True
      TabOrder = 2
    end
  end
  object DataSource1: TDataSource
    DataSet = Table1
    Left = 39
    Top = 65
  end
  object Database1: TmySQLDatabase
    DatabaseName = 'dbdemos'
    Host = '<Enter Your Host>'
    ConnectOptions = []
    Params.Strings = (
      'Port=3306'
      'DatabaseName=dbdemos'
      'Host=<Enter Your Host>')
    ReadOnly = True
    Left = 7
    Top = 118
  end
  object Table1: TmySQLTable
    AutoRefresh = True
    Database = Database1
    IndexFieldNames = 'Species_no'
    TableName = 'biolife'
    Left = 7
    Top = 49
  end
  object dlgOpen1: TOpenDialog
    Filter = '*.bmp||*.jpg'
    InitialDir = 'Images'
    Options = [ofReadOnly, ofPathMustExist, ofFileMustExist, ofShareAware, ofEnableSizing]
    Title = 'Load image from an existing file'
    Left = 187
    Top = 113
  end
  object dlgSave1: TSaveDialog
    DefaultExt = 'BMP'
    Filter = 'Bitmap (*.bmp)|*.bmp'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofCreatePrompt, ofEnableSizing]
    Left = 228
    Top = 109
  end
  object ACRDatabase1: TACRDatabase
    DatabaseFileName = 'import.adb'
    DatabaseName = 'DBImport'
    Exclusive = False
    SessionName = 'Default'
    LockParams.Delay = 500
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 2
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    Left = 344
    Top = 88
  end
  object ACRTable1: TACRTable
    CurrentVersion = '2.10 '
    DatabaseName = 'DBImport'
    InMemory = False
    ReadOnly = False
    TableName = 'test'
    Exclusive = False
    Left = 344
    Top = 128
  end
end
