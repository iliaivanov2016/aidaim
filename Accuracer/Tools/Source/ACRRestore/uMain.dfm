object fmMain: TfmMain
  Left = 257
  Top = 101
  BorderIcons = [biSystemMenu]
  Caption = 
    'Accuracer Restore. (c) AidAim Software, 2000-2022. https://aidai' +
    'm.com'
  ClientHeight = 563
  ClientWidth = 504
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel
    Left = 8
    Top = 476
    Width = 64
    Height = 13
    Caption = 'InitVector file:'
    Enabled = False
  end
  object Label5: TLabel
    Left = 276
    Top = 476
    Width = 37
    Height = 13
    Caption = 'Key file:'
    Visible = False
  end
  object Label2: TLabel
    Left = 276
    Top = 278
    Width = 49
    Height = 13
    Alignment = taCenter
    Caption = 'Password:'
  end
  object Label14: TLabel
    Left = 8
    Top = 297
    Width = 48
    Height = 13
    Caption = 'InitVector:'
    Enabled = False
  end
  object Label13: TLabel
    Left = 276
    Top = 298
    Width = 21
    Height = 13
    Caption = 'Key:'
  end
  object Label1: TLabel
    Left = 8
    Top = 46
    Width = 97
    Height = 13
    Caption = 'Database file name: '
  end
  object Label8: TLabel
    Left = 8
    Top = 13
    Width = 88
    Height = 13
    Caption = 'Backup file name: '
  end
  object Label3: TLabel
    Left = 8
    Top = 72
    Width = 59
    Height = 13
    Caption = 'Description: '
  end
  object Label4: TLabel
    Left = 235
    Top = 72
    Width = 87
    Height = 13
    AutoSize = False
    Caption = 'Tables:  '
  end
  object Label7: TLabel
    Left = 277
    Top = 250
    Width = 42
    Height = 13
    Alignment = taCenter
    Caption = 'File Size:'
  end
  object Label9: TLabel
    Left = 277
    Top = 226
    Width = 45
    Height = 13
    Alignment = taCenter
    Caption = 'File Date:'
  end
  object tPassword: TEdit
    Left = 329
    Top = 274
    Width = 161
    Height = 21
    PasswordChar = '*'
    TabOrder = 0
  end
  object edKeyfile: TEdit
    Left = 276
    Top = 493
    Width = 185
    Height = 21
    TabOrder = 1
    OnEnter = edKeyfileEnter
  end
  object edInitVectorfile: TEdit
    Left = 8
    Top = 493
    Width = 185
    Height = 21
    Enabled = False
    TabOrder = 2
    OnEnter = edInitVectorfileEnter
  end
  object Button2: TButton
    Left = 464
    Top = 491
    Width = 26
    Height = 25
    Caption = '...'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 202
    Top = 491
    Width = 25
    Height = 25
    Caption = '...'
    Enabled = False
    TabOrder = 4
    OnClick = Button3Click
  end
  object InitVectorGrid: TStringGrid
    Left = 8
    Top = 317
    Width = 217
    Height = 144
    TabStop = False
    ColCount = 8
    DefaultColWidth = 32
    Enabled = False
    FixedCols = 0
    RowCount = 7
    FixedRows = 0
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goAlwaysShowEditor]
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 5
    OnEnter = InitVectorGridEnter
    OnGetEditMask = InitVectorGridGetEditMask
  end
  object KeyGrid: TStringGrid
    Left = 273
    Top = 318
    Width = 217
    Height = 145
    TabStop = False
    ColCount = 8
    DefaultColWidth = 32
    FixedCols = 0
    RowCount = 7
    FixedRows = 0
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goAlwaysShowEditor]
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 6
    OnEnter = KeyGridEnter
    OnGetEditMask = KeyGridGetEditMask
  end
  object IsInitVector: TCheckBox
    Left = 8
    Top = 277
    Width = 78
    Height = 14
    Caption = 'Initial vector'
    TabOrder = 7
    OnClick = IsInitVectorClick
  end
  object bnRestore: TButton
    Left = 200
    Top = 531
    Width = 75
    Height = 25
    Caption = 'Restore'
    TabOrder = 8
    OnClick = bnRestoreClick
  end
  object bnExit: TButton
    Left = 304
    Top = 531
    Width = 75
    Height = 25
    Caption = 'Exit'
    TabOrder = 9
    OnClick = bnExitClick
  end
  object edDBFileName: TEdit
    Left = 114
    Top = 44
    Width = 341
    Height = 21
    TabOrder = 10
    Text = 'Database1.adb'
  end
  object edBackupFileName: TEdit
    Left = 114
    Top = 11
    Width = 341
    Height = 21
    TabOrder = 11
    Text = 'Database1.abk'
  end
  object Button1: TButton
    Left = 465
    Top = 9
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 12
    OnClick = Button1Click
  end
  object Button6: TButton
    Left = 465
    Top = 41
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 13
  end
  object bnGetBackupInfo: TButton
    Left = 56
    Top = 532
    Width = 107
    Height = 25
    Caption = 'Get Backup Info'
    TabOrder = 14
    OnClick = bnGetBackupInfoClick
  end
  object reDesc: TRichEdit
    Left = 72
    Top = 72
    Width = 153
    Height = 168
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -10
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    PlainText = True
    ScrollBars = ssBoth
    TabOrder = 15
    WantTabs = True
  end
  object lbTables: TListBox
    Left = 328
    Top = 72
    Width = 162
    Height = 145
    ItemHeight = 13
    TabOrder = 16
  end
  object cbEncrypted: TCheckBox
    Left = 8
    Top = 248
    Width = 217
    Height = 17
    Caption = 'Encrypted Backup File'
    TabOrder = 17
  end
  object edFileSize: TEdit
    Left = 329
    Top = 247
    Width = 161
    Height = 21
    TabOrder = 18
  end
  object edFileDate: TEdit
    Left = 329
    Top = 223
    Width = 161
    Height = 21
    TabOrder = 19
  end
  object OpenDialog1: TOpenDialog
    Left = 8
    Top = 528
  end
  object Data: TACRDatabase
    FormatVersion = 19.000000000000000000
    DatabaseName = 'AccuracerDB_1017460875'
    InMemory = False
    SessionName = 'Default'
    Exclusive = False
    BackupParams.CompressionAlgorithm = caNone
    BackupParams.CompressionMode = 1
    BackupParams.CryptoParams.CryptoAlgorithm = craNone
    BackupParams.CryptoParams.CryptoMode = acmCTS
    BackupParams.CryptoParams.KeySize = 56
    BackupParams.CryptoParams.Password = 'ACRpassword'
    BackupParams.CryptoParams.UseInitVector = False
    BackupParams.CryptoParams.InitVectorSize = 0
    BackupParams.BlockSize = 102400
    ConnectionParams.DatabaseName = 'DBDemos'
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'ACRpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.CryptoParams.InitVectorSize = 0
    ConnectionParams.ServerID = 0
    ConnectionParams.Protocol = acrUDP
    ConnectionParams.RemoteHost = 'localhost'
    ConnectionParams.RemotePort = 6669
    ConnectionParams.MinCacheSize = 1429
    ConnectionParams.MaxCacheSize = 1048576
    LockParams.Delay = 500
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 5
    Options.PageSize = 4096
    Options.ExtentPageCount = 8
    Options.RandomSearchRetryCount = 10
    OnProgress = DataProgress
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    CryptoParams.InitVectorSize = 0
    CaseInsensitive = False
    Left = 168
    Top = 64
  end
  object OpenDialog2: TOpenDialog
    DefaultExt = '.abk'
    Filter = 'Accuracer backup files (*.abk)|*.abk|Any file (*.*)|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select Accuracer Backup File'
    Left = 224
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.adb'
    Filter = 'Accuracer database files (*.adb)|*.adb|Any file (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofNoReadOnlyReturn, ofEnableSizing]
    Title = 'Select Accuracer Database File'
    Left = 224
    Top = 40
  end
end
