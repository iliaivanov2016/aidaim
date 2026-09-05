object fmOpenDatabase: TfmOpenDatabase
  Left = 282
  Top = 222
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Open Database'
  ClientHeight = 244
  ClientWidth = 501
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 256
    Top = 56
    Width = 233
    Height = 150
    Caption = ' Remote Database Connection Parameters: '
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 25
      Width = 80
      Height = 13
      Caption = 'DatabaseName: '
    end
    object Label2: TLabel
      Left = 8
      Top = 73
      Width = 68
      Height = 13
      Caption = 'Remote Host: '
    end
    object Label3: TLabel
      Left = 8
      Top = 97
      Width = 65
      Height = 13
      Caption = 'Remote Port: '
    end
    object Label4: TLabel
      Left = 8
      Top = 121
      Width = 54
      Height = 13
      Caption = 'Local Port: '
    end
    object lProtocol: TLabel
      Left = 8
      Top = 49
      Width = 42
      Height = 13
      Caption = 'Protocol:'
    end
    object edDBName: TEdit
      Left = 88
      Top = 22
      Width = 136
      Height = 21
      TabOrder = 0
    end
    object edRemoteHost: TEdit
      Left = 87
      Top = 70
      Width = 136
      Height = 21
      TabOrder = 1
    end
    object edRemotePort: TEdit
      Left = 87
      Top = 94
      Width = 136
      Height = 21
      TabOrder = 2
    end
    object edLocalPort: TEdit
      Left = 87
      Top = 118
      Width = 136
      Height = 21
      TabOrder = 3
    end
    object cbProtocol: TComboBox
      Left = 88
      Top = 46
      Width = 136
      Height = 21
      ItemIndex = 1
      TabOrder = 4
      Text = 'UDP'
      Items.Strings = (
        'TCP'
        'UDP')
    end
  end
  object BitBtn1: TBitBtn
    Left = 112
    Top = 213
    Width = 75
    Height = 25
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 1
  end
  object bnCancel: TBitBtn
    Left = 280
    Top = 213
    Width = 75
    Height = 25
    Kind = bkCancel
    NumGlyphs = 2
    TabOrder = 2
  end
  object rgLocalDatabase: TRadioGroup
    Left = 8
    Top = 8
    Width = 481
    Height = 41
    Caption = ' Local or Remote Database '
    Columns = 2
    ItemIndex = 0
    Items.Strings = (
      'Local (Multi-User)'
      'Remote (Client-Server)')
    TabOrder = 3
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 56
    Width = 233
    Height = 150
    Caption = ' Local Database Parameters '
    TabOrder = 4
    object Label5: TLabel
      Left = 8
      Top = 21
      Width = 74
      Height = 13
      Caption = ' Database File: '
    end
    object edDatabaseFile: TEdit
      Left = 8
      Top = 40
      Width = 217
      Height = 21
      TabOrder = 0
    end
    object Button1: TButton
      Left = 8
      Top = 72
      Width = 75
      Height = 25
      Caption = 'Browse'
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.adb'
    Filter = 
      'Accuracer database file (*.adb)|*.adb|Executable database file (' +
      '*.exe)|*.exe|Any file (*.*)|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Open Database File'
    Left = 400
    Top = 408
  end
end
