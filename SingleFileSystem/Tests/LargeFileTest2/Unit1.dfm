object Form1: TForm1
  Left = 286
  Top = 171
  Width = 500
  Height = 351
  Caption = 'Test FileWrite'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Indicator: TGauge
    Left = 128
    Top = 256
    Width = 217
    Height = 24
    ForeColor = clBlue
    Progress = 0
  end
  object Label2: TLabel
    Left = 8
    Top = 16
    Width = 90
    Height = 13
    Caption = 'Enter test file name'
  end
  object Label1: TLabel
    Left = 8
    Top = 48
    Width = 93
    Height = 13
    Caption = 'Enter SFS file name'
  end
  object Label3: TLabel
    Left = 8
    Top = 80
    Width = 124
    Height = 13
    Caption = 'Enter destination file name'
  end
  object Button1: TButton
    Left = 200
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Run Test'
    TabOrder = 0
    OnClick = Button1Click
  end
  object edTestFileName: TEdit
    Left = 192
    Top = 12
    Width = 257
    Height = 21
    TabOrder = 1
    Text = 'project1.exe'
  end
  object Button2: TButton
    Left = 456
    Top = 10
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Log: TMemo
    Left = 8
    Top = 115
    Width = 473
    Height = 129
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object Button3: TButton
    Left = 456
    Top = 42
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 4
    OnClick = Button3Click
  end
  object edSFSFileName: TEdit
    Left = 192
    Top = 44
    Width = 257
    Height = 21
    TabOrder = 5
    Text = 'test.sfs'
  end
  object Button4: TButton
    Left = 456
    Top = 74
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 6
    OnClick = Button4Click
  end
  object edDestFileName: TEdit
    Left = 192
    Top = 76
    Width = 257
    Height = 21
    TabOrder = 7
    Text = 'project_exported.exe'
  end
  object OpenDialog1: TOpenDialog
    Left = 416
    Top = 8
  end
end
