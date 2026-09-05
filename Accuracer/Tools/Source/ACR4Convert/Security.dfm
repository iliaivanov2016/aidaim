object FormSecurity: TFormSecurity
  Left = 256
  Top = 309
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'FormSecurity'
  ClientHeight = 300
  ClientWidth = 621
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel
    Left = 15
    Top = 217
    Width = 64
    Height = 13
    Caption = 'InitVector file:'
    Enabled = False
  end
  object lbKeyFile: TLabel
    Left = 320
    Top = 217
    Width = 37
    Height = 13
    Caption = 'Key file:'
    Visible = False
  end
  object lbPassword: TLabel
    Left = 268
    Top = 14
    Width = 49
    Height = 13
    Alignment = taCenter
    Caption = 'Password:'
    Visible = False
  end
  object Label14: TLabel
    Left = 9
    Top = 33
    Width = 48
    Height = 13
    Caption = 'InitVector:'
    Enabled = False
  end
  object lbKey: TLabel
    Left = 268
    Top = 34
    Width = 21
    Height = 13
    Caption = 'Key:'
    Visible = False
  end
  object bnOk: TBitBtn
    Left = 216
    Top = 267
    Width = 75
    Height = 26
    DoubleBuffered = True
    Kind = bkOK
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = bnOkClick
  end
  object bnCancel: TBitBtn
    Left = 310
    Top = 267
    Width = 75
    Height = 26
    DoubleBuffered = True
    Kind = bkCancel
    ParentDoubleBuffered = False
    TabOrder = 1
    OnClick = bnCancelClick
  end
  object tPassword: TEdit
    Left = 323
    Top = 8
    Width = 290
    Height = 21
    PasswordChar = '*'
    TabOrder = 2
    Visible = False
  end
  object edKeyfile: TEdit
    Left = 323
    Top = 234
    Width = 257
    Height = 21
    TabOrder = 3
    Visible = False
    OnEnter = edKeyfileEnter
  end
  object edInitVectorfile: TEdit
    Left = 18
    Top = 234
    Width = 257
    Height = 21
    Enabled = False
    TabOrder = 4
    OnEnter = edInitVectorfileEnter
  end
  object bnKeyFile: TButton
    Left = 587
    Top = 234
    Width = 26
    Height = 25
    Caption = '...'
    TabOrder = 5
    Visible = False
    OnClick = bnKeyFileClick
  end
  object Button3: TButton
    Left = 282
    Top = 234
    Width = 25
    Height = 25
    Caption = '...'
    Enabled = False
    TabOrder = 6
    OnClick = Button3Click
  end
  object InitVectorGrid: TStringGrid
    Left = 11
    Top = 53
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
    TabOrder = 7
    OnEnter = InitVectorGridEnter
    OnGetEditMask = InitVectorGridGetEditMask
  end
  object KeyGrid: TStringGrid
    Left = 271
    Top = 54
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
    TabOrder = 8
    Visible = False
    OnEnter = KeyGridEnter
    OnGetEditMask = KeyGridGetEditMask
  end
  object IsInitVector: TCheckBox
    Left = 7
    Top = 13
    Width = 78
    Height = 14
    Caption = 'Initial vector'
    TabOrder = 9
    OnClick = IsInitVectorClick
  end
  object OpenDialog1: TOpenDialog
    Top = 232
  end
end
