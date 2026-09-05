object DSNsetupForm: TDSNsetupForm
  Left = 291
  Top = 345
  BorderStyle = bsDialog
  Caption = 'EasyTable ODBC DSN Setup'
  ClientHeight = 113
  ClientWidth = 439
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 94
    Height = 13
    Caption = 'Data Source Name:'
  end
  object Label2: TLabel
    Left = 8
    Top = 43
    Width = 56
    Height = 13
    Caption = 'Description:'
  end
  object Label3: TLabel
    Left = 8
    Top = 85
    Width = 83
    Height = 13
    Caption = 'Datasource Path:'
  end
  object OK: TBitBtn
    Left = 360
    Top = 8
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = OKClick
  end
  object Cancel: TBitBtn
    Left = 360
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = CancelClick
  end
  object Help: TBitBtn
    Left = 360
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Help'
    TabOrder = 2
    OnClick = HelpClick
  end
  object DSN: TEdit
    Left = 112
    Top = 8
    Width = 233
    Height = 21
    TabOrder = 3
  end
  object Description: TEdit
    Left = 112
    Top = 40
    Width = 233
    Height = 21
    TabOrder = 4
    Text = 'EasyTable database'
  end
  object Dir: TBitBtn
    Left = 320
    Top = 80
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 5
    OnClick = DirClick
  end
  object DatabaseFile: TEdit
    Left = 112
    Top = 82
    Width = 201
    Height = 21
    TabOrder = 6
  end
  object SelectDatabase: TOpenDialog
    DefaultExt = '.edb'
    Filter = 'EasyTable database file (*.edb)|*.edb|All files (*.*)|*.*'
    Title = 'Select Database File'
    Left = 72
    Top = 48
  end
end
