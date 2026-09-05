object MainForm: TMainForm
  Left = 182
  Top = 174
  Width = 544
  Height = 375
  ActiveControl = Button1
  Caption = 'MainForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Info: TMemo
    Left = 0
    Top = 0
    Width = 536
    Height = 307
    Align = alClient
    Lines.Strings = (
      'DBEngine Test Batch'
      '')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 307
    Width = 536
    Height = 41
    Align = alBottom
    TabOrder = 1
    object Button1: TButton
      Left = 16
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Start'
      Default = True
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object TestDS: TEasyTable
    CurrentVersion = '6.30 Prerelease version #2'
    TableName = 'test'
    DatabaseName = 'TestDB'
    BLOBCompression = clFastest
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Left = 280
    Top = 80
  end
  object EasyDatabase1: TEasyDatabase
    DatabaseFileName = 's:\test.edb'
    DatabaseName = 'TestDB'
    InMemory = False
    HandleShared = True
    SessionName = 'Default'
    Left = 248
    Top = 80
  end
end
