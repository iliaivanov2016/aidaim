object FormProgress: TFormProgress
  Left = 192
  Top = 107
  ActiveControl = CancelBtn
  BorderIcons = []
  BorderStyle = bsDialog
  ClientHeight = 161
  ClientWidth = 303
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Indicator: TGauge
    Left = 23
    Top = 32
    Width = 253
    Height = 24
    Color = clWhite
    ForeColor = clBlue
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Progress = 0
  end
  object Label1: TLabel
    Left = 23
    Top = 14
    Width = 253
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = ' '
  end
  object Label2: TLabel
    Left = 23
    Top = 73
    Width = 253
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'Overall progress'
  end
  object Indicator2: TGauge
    Left = 23
    Top = 91
    Width = 253
    Height = 24
    Color = clWhite
    ForeColor = clBlue
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Progress = 0
  end
  object CancelBtn: TButton
    Left = 114
    Top = 126
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 0
    OnClick = CancelBtnClick
  end
end
