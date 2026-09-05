object MainForm: TMainForm
  Left = 184
  Top = 220
  Anchors = []
  BorderIcons = [biMinimize, biHelp]
  Caption = 
    'Accuracer Database Server. (c) AidAim Software, 2000-2025. https' +
    '://aidaim.com'
  ClientHeight = 430
  ClientWidth = 619
  Color = clBtnFace
  DefaultMonitor = dmDesktop
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Position = poDesktopCenter
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object imgServerDown: TImage
    Left = 300
    Top = 2
    Width = 25
    Height = 25
    Center = True
    Picture.Data = {
      055449636F6E0000010001001010100000000000280100001600000028000000
      10000000200000000100040000000000C0000000000000000000000000000000
      0000000000000000000080000080000000808000800000008000800080800000
      80808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000
      FFFFFF0000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000990000000000000
      9990000000000000000000000000999000999000000099000099000000000009
      9000000000000099900000000000009000000000000000000000000000000000
      00000000FDFF0000FDFF0000FBFF0000FBFF0000FBFF0000F7810000F0010000
      F0030000E0030000E0030000E0070000C0070000C0070000C00F0000C1FF0000
      BFFF0000}
    Visible = False
  end
  object imgServerUp: TImage
    Left = 250
    Top = 2
    Width = 25
    Height = 25
    Center = True
    Picture.Data = {
      055449636F6E0000010001001010100000000000280100001600000028000000
      10000000200000000100040000000000C0000000000000000000000000000000
      0000000000000000000080000080000000808000800000008000800080800000
      80808000C0C0C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000
      FFFFFF0000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000AA00000000000002AAA
      000000000000000000000000000AAA000AAA00000000AA0000AA00000000000A
      A00000000000000AAA000000000000000A000000000000000000000000000000
      00000000FFBF0000FFBF0000FFDF0000FFDF0000FFDF000081EF0000800F0000
      C00F0000C0070000C0070000E0070000E0030000E0030000F0030000FF830000
      FFFD0000}
    Visible = False
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 386
    Width = 619
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 379
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 389
    Width = 619
    Height = 41
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 381
    ExplicitWidth = 617
    object bnStart: TButton
      Tag = 9
      Left = 5
      Top = 9
      Width = 75
      Height = 25
      Caption = '&Start'
      TabOrder = 0
      OnClick = bnStartClick
    end
    object bnStop: TButton
      Tag = 10
      Left = 89
      Top = 9
      Width = 75
      Height = 25
      Caption = 'S&top'
      Enabled = False
      TabOrder = 1
      OnClick = bnStopClick
    end
    object bnLoadSettings: TButton
      Tag = 9
      Left = 257
      Top = 9
      Width = 75
      Height = 25
      Caption = '&Load Settings'
      TabOrder = 2
      OnClick = bnLoadSettingsClick
    end
    object bnSaveSettings: TButton
      Tag = 10
      Left = 337
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Sa&ve Settings'
      TabOrder = 3
      OnClick = bnSaveSettingsClick
    end
    object bnAbout: TButton
      Tag = 12
      Left = 422
      Top = 9
      Width = 75
      Height = 25
      Cancel = True
      Caption = '&About'
      TabOrder = 4
      OnClick = AboutButtonClick
    end
    object bnClose: TButton
      Tag = 12
      Left = 530
      Top = 9
      Width = 75
      Height = 25
      Cancel = True
      Caption = '&Close'
      TabOrder = 5
      OnClick = bnCloseClick
    end
    object bnShutdown: TButton
      Tag = 12
      Left = 174
      Top = 9
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'S&hut Down'
      TabOrder = 6
      OnClick = bnShutdownClick
    end
  end
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 619
    Height = 386
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 617
    ExplicitHeight = 378
    object pgcntrlClient: TPageControl
      Left = 1
      Top = 1
      Width = 617
      Height = 384
      ActivePage = tsConnections
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 615
      ExplicitHeight = 376
      object tsServerSettings: TTabSheet
        Caption = 'Server Settings'
        object mServerSettings: TMemo
          Left = 0
          Top = 0
          Width = 609
          Height = 356
          Align = alClient
          ParentShowHint = False
          ReadOnly = True
          ScrollBars = ssVertical
          ShowHint = True
          TabOrder = 0
        end
      end
      object tsConnections: TTabSheet
        Caption = 'Connections'
        ImageIndex = 1
        object sgConnections: TStringGrid
          Left = 0
          Top = 0
          Width = 609
          Height = 356
          Align = alClient
          ColCount = 7
          DefaultRowHeight = 20
          FixedCols = 0
          RowCount = 1
          FixedRows = 0
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing]
          ScrollBars = ssVertical
          TabOrder = 0
          ExplicitWidth = 607
          ExplicitHeight = 348
        end
      end
    end
  end
  object pmTrayMenu: TPopupMenu
    Left = 378
    Top = 1
    object miViewSettings: TMenuItem
      Caption = '&View Settings'
      Default = True
      OnClick = miViewSettingsClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object miStartServer: TMenuItem
      Caption = '&Start Server'
      OnClick = bnStartClick
    end
    object miStopServer: TMenuItem
      Caption = 'S&top Server'
      OnClick = bnStopClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object miShutdown: TMenuItem
      Caption = 'S&hut Down Server'
      OnClick = miShutdownClick
    end
  end
  object tTimer: TTimer
    Enabled = False
    OnTimer = tTimerTimer
    Left = 456
    Top = 1
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.ini'
    Filter = 'Ini files(*.ini)|*.ini|Any file (*.*)|*.*'
    FilterIndex = 0
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Save Accuracer Database Server Settings'
    Left = 528
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.ini'
    Filter = 'Ini files(*.ini)|*.ini|Any file (*.*)|*.*'
    FilterIndex = 0
    Title = 'Load Accuracer Database Server Settings'
    Left = 488
  end
  object Server: TACRServer
    ConnectionParams.DatabaseName = 'DBDemos'
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 0
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'ACRpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.ServerID = 0
    ConnectionParams.Protocol = acrsTCPandUDP
    ConnectionParams.LocalPortTCP = 12008
    ConnectionParams.LocalPortUDP = 12007
    UseConfigFile = True
    Active = False
    CurrentVersion = '23.00 '
    DatabaseNames.Strings = (
      'DBDemos')
    DatabaseFileNames.Strings = (
      '..\..\Demos\Data\DBDemos.adb')
    ConfigFileName = 'AccuracerDatabaseServer.ini'
    AfterServerStart = ServerServerStart
    AfterServerStop = ServerServerStop
    OpenDatabasesInExclusiveMode = True
    MaxCommandExecutionTime = 1800
    Left = 296
    Top = 200
  end
end
