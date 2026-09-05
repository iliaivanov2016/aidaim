object DatabaseInfo: TDatabaseInfo
  Left = 373
  Top = 257
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Database information'
  ClientHeight = 384
  ClientWidth = 345
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object bnOk: TBitBtn
    Left = 130
    Top = 345
    Width = 74
    Height = 26
    DoubleBuffered = True
    Kind = bkOK
    ParentDoubleBuffered = False
    TabOrder = 0
  end
  object GroupBox1: TGroupBox
    Left = 7
    Top = 7
    Width = 331
    Height = 218
    Caption = 'Options'
    TabOrder = 1
    object Label8: TLabel
      Left = 14
      Top = 40
      Width = 49
      Height = 13
      Caption = 'Page size:'
    end
    object Label9: TLabel
      Left = 14
      Top = 59
      Width = 132
      Height = 13
      Caption = 'Maximum count of sessions:'
    end
    object lPageSize: TLabel
      Left = 155
      Top = 39
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lPageSize'
    end
    object lMaxCon: TLabel
      Left = 155
      Top = 59
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lMaxCon'
    end
    object Label1: TLabel
      Left = 13
      Top = 78
      Width = 56
      Height = 13
      Caption = 'Free pages:'
    end
    object Label5: TLabel
      Left = 13
      Top = 98
      Width = 59
      Height = 13
      Caption = 'Total pages:'
    end
    object Label6: TLabel
      Left = 13
      Top = 117
      Width = 60
      Height = 13
      Caption = 'Used pages:'
    end
    object Label7: TLabel
      Left = 13
      Top = 137
      Width = 38
      Height = 13
      Caption = 'Density:'
    end
    object lFreePages: TLabel
      Left = 155
      Top = 78
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lFreePages'
    end
    object lTotalPages: TLabel
      Left = 155
      Top = 98
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lTotalPages'
    end
    object lUsedPages: TLabel
      Left = 155
      Top = 117
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lUsedPages'
    end
    object lDensity: TLabel
      Left = 155
      Top = 137
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lDensity'
    end
    object CompactNeeded: TLabel
      Left = 7
      Top = 155
      Width = 317
      Height = 12
      Alignment = taCenter
      AutoSize = False
      Caption = 'It is recommended to compact the database !'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label10: TLabel
      Left = 13
      Top = 20
      Width = 72
      Height = 13
      Caption = 'Format version:'
    end
    object lFormatVersion: TLabel
      Left = 155
      Top = 20
      Width = 100
      Height = 13
      AutoSize = False
      Caption = 'lFormatVersion'
    end
    object labStoredFunctionManager: TLabel
      Left = 7
      Top = 174
      Width = 317
      Height = 36
      Alignment = taCenter
      AutoSize = False
      Caption = 'Use CREATE FUNCTION to create new stored function.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object GroupBox2: TGroupBox
    Left = 7
    Top = 234
    Width = 331
    Height = 105
    Caption = 'Encryption'
    TabOrder = 2
    object Label2: TLabel
      Left = 15
      Top = 20
      Width = 65
      Height = 13
      Alignment = taCenter
      Caption = 'Encrypted by:'
    end
    object Label3: TLabel
      Left = 14
      Top = 40
      Width = 46
      Height = 13
      Caption = 'Algorithm:'
    end
    object Label4: TLabel
      Left = 14
      Top = 59
      Width = 30
      Height = 13
      Caption = 'Mode:'
    end
    object Label14: TLabel
      Left = 13
      Top = 79
      Width = 61
      Height = 13
      Caption = 'Initial Vector:'
    end
    object lEncrypt: TLabel
      Left = 155
      Top = 20
      Width = 105
      Height = 13
      AutoSize = False
      Caption = 'lEncrypt'
    end
    object lAlg: TLabel
      Left = 155
      Top = 39
      Width = 105
      Height = 13
      AutoSize = False
      Caption = 'lAlg'
    end
    object lMode: TLabel
      Left = 155
      Top = 59
      Width = 105
      Height = 13
      AutoSize = False
      Caption = 'lMode'
    end
    object lInv: TLabel
      Left = 155
      Top = 78
      Width = 105
      Height = 13
      AutoSize = False
      Caption = 'lInv'
    end
  end
end
