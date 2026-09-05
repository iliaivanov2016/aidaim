object Form1: TForm1
  Left = 244
  Top = 111
  Width = 759
  Height = 623
  Caption = 'UnitTester'
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
    Left = 384
    Top = 81
    Width = 8
    Height = 515
    Align = alRight
    Beveled = True
  end
  object MainLog: TMemo
    Left = 0
    Top = 0
    Width = 751
    Height = 81
    Align = alTop
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Panel3: TPanel
    Left = 0
    Top = 81
    Width = 384
    Height = 515
    Align = alClient
    TabOrder = 0
    object Panel1: TPanel
      Left = 1
      Top = 1
      Width = 382
      Height = 15
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object Label1: TLabel
        Left = 1
        Top = 1
        Width = 58
        Height = 13
        Caption = 'Process log:'
      end
    end
    object ProcessLog: TMemo
      Left = 1
      Top = 16
      Width = 382
      Height = 498
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object Panel4: TPanel
    Left = 392
    Top = 81
    Width = 359
    Height = 515
    Align = alRight
    TabOrder = 1
    object Panel2: TPanel
      Left = 1
      Top = 1
      Width = 357
      Height = 15
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object Label2: TLabel
        Left = 1
        Top = 1
        Width = 42
        Height = 13
        Caption = 'Error log:'
      end
    end
    object ErrorLog: TMemo
      Left = 1
      Top = 16
      Width = 357
      Height = 498
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 1
    end
  end
end
