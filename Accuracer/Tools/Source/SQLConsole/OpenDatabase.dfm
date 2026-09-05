object fmOpenDatabase: TfmOpenDatabase
  Left = 282
  Top = 222
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
    Top = 64
    Width = 233
    Height = 129
    Caption = ' Remote Database Connection Parameters: '
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 24
      Width = 80
      Height = 13
      Caption = 'DatabaseName: '
    end
    object Label2: TLabel
      Left = 8
      Top = 48
      Width = 68
      Height = 13
      Caption = 'Remote Host: '
    end
    object Label3: TLabel
      Left = 8
      Top = 72
      Width = 65
      Height = 13
      Caption = 'Remote Port: '
    end
    object Label4: TLabel
      Left = 8
      Top = 96
      Width = 54
      Height = 13
      Caption = 'Local Port: '
    end
    object edDBName: TEdit
      Left = 93
      Top = 22
      Width = 121
      Height = 21
      TabOrder = 0
    end
    object edRemoteHost: TEdit
      Left = 93
      Top = 46
      Width = 121
      Height = 21
      TabOrder = 1
    end
    object edRemotePort: TEdit
      Left = 93
      Top = 70
      Width = 121
      Height = 21
      TabOrder = 2
    end
    object edLocalPort: TEdit
      Left = 93
      Top = 94
      Width = 121
      Height = 21
      TabOrder = 3
    end
  end
  object BitBtn1: TBitBtn
    Left = 112
    Top = 208
    Width = 75
    Height = 25
    TabOrder = 1
    Kind = bkOK
  end
  object bnCancel: TBitBtn
    Left = 280
    Top = 208
    Width = 75
    Height = 25
    TabOrder = 2
    Kind = bkCancel
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
    Top = 64
    Width = 233
    Height = 129
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
    Filter = 'Accuracer database files(*.adb)|*.adb|Any file (*.*)|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Open Database File'
    Left = 400
    Top = 408
  end
end
