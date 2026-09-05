object Form1: TForm1
  Left = 260
  Top = 300
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Creating test databases ... '
  ClientHeight = 292
  ClientWidth = 307
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Indicator: TGauge
    Left = 8
    Top = 231
    Width = 289
    Height = 22
    ForeColor = clBlue
    Progress = 0
  end
  object BitBtn1: TBitBtn
    Left = 176
    Top = 260
    Width = 75
    Height = 25
    TabOrder = 0
    OnClick = BitBtn1Click
    Kind = bkCancel
  end
  object Log: TMemo
    Left = 8
    Top = 8
    Width = 289
    Height = 215
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object bnStart: TBitBtn
    Left = 40
    Top = 260
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 2
    OnClick = bnStartClick
    Kind = bkOK
  end
end
