object Form1: TForm1
  Left = 317
  Top = 123
  Caption = 'UnitTester'
  ClientHeight = 478
  ClientWidth = 651
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
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
    Width = 651
    Height = 89
    Align = alTop
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object ProcessLog: TMemo
    Left = 0
    Top = 104
    Width = 320
    Height = 374
    Align = alLeft
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 89
    Width = 651
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
      Left = 332
      Top = 1
      Width = 42
      Height = 13
      Caption = 'Error log:'
    end
  end
  object ErrorLog: TMemo
    Left = 331
    Top = 104
    Width = 320
    Height = 374
    Align = alRight
    ScrollBars = ssBoth
    TabOrder = 2
  end
end
