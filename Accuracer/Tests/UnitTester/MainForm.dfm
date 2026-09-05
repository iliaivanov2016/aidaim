object Form1: TForm1
  Left = 352
  Top = 438
  Width = 928
  Height = 556
  Caption = 'UnitTester'
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
  object Splitter1: TSplitter
    Left = 324
    Top = 18
    Height = 450
    Align = alNone
  end
  object MainLog: TMemo
    Left = 0
    Top = 0
    Width = 920
    Height = 89
    Align = alTop
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object ProcessLog: TMemo
    Left = 0
    Top = 104
    Width = 600
    Height = 425
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 89
    Width = 920
    Height = 15
    Align = alTop
    AutoSize = True
    TabOrder = 1
    object Label1: TLabel
      Left = 1
      Top = 1
      Width = 58
      Height = 13
      Caption = 'Process log:'
    end
    object Label2: TLabel
      Left = 604
      Top = 1
      Width = 42
      Height = 13
      Caption = 'Error log:'
    end
  end
  object ErrorLog: TMemo
    Left = 600
    Top = 104
    Width = 320
    Height = 425
    Align = alRight
    ScrollBars = ssBoth
    TabOrder = 2
  end
end
