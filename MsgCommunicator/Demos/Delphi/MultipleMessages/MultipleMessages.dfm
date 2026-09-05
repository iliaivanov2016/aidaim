object Form1: TForm1
  Left = 457
  Top = 272
  Width = 224
  Height = 455
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 200
    Width = 14
    Height = 13
    Caption = 'log'
  end
  object Memo1: TMemo
    Left = 16
    Top = 40
    Width = 185
    Height = 89
    Lines.Strings = (
      'Hello!')
    TabOrder = 0
  end
  object ServerSend: TButton
    Left = 72
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Server Send'
    TabOrder = 1
  end
  object Directly: TRadioButton
    Left = 16
    Top = 168
    Width = 80
    Height = 17
    Caption = 'Directly'
    TabOrder = 2
  end
  object RadioButton1: TRadioButton
    Left = 16
    Top = 144
    Width = 80
    Height = 17
    Caption = 'via Server'
    TabOrder = 3
  end
  object ClientSend: TButton
    Left = 128
    Top = 152
    Width = 75
    Height = 25
    Caption = 'Client Send'
    TabOrder = 4
  end
  object Memo2: TMemo
    Left = 16
    Top = 216
    Width = 185
    Height = 193
    ScrollBars = ssVertical
    TabOrder = 5
  end
end
