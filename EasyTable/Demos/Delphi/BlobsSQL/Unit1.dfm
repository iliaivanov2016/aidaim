object Form1: TForm1
  Left = 192
  Top = 107
  BorderStyle = bsDialog
  Caption = 'BLOBS SQL Demo. (c) AidAim Software LLC, 2000-2003'
  ClientHeight = 307
  ClientWidth = 541
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
  object DBGrid1: TDBGrid
    Left = 16
    Top = 72
    Width = 320
    Height = 120
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 48
    Top = 208
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object bnInsert: TButton
    Left = 16
    Top = 264
    Width = 145
    Height = 25
    Caption = 'Insert BLOB data'
    TabOrder = 2
    OnClick = bnInsertClick
  end
  object Button2: TButton
    Left = 192
    Top = 264
    Width = 145
    Height = 25
    Caption = 'Update BLOB data'
    TabOrder = 3
    OnClick = Button2Click
  end
  object DBMemo1: TDBMemo
    Left = 352
    Top = 72
    Width = 185
    Height = 121
    DataField = 'Text'
    DataSource = DataSource1
    TabOrder = 4
  end
  object bnClose: TButton
    Left = 368
    Top = 264
    Width = 145
    Height = 25
    Caption = 'Close'
    TabOrder = 5
    OnClick = bnCloseClick
  end
  object EasyQuery1: TEasyQuery
    RequestLive = True
    CurrentVersion = '5.61 '
    InMemory = True
    BDELikeFilter = False
    FilterOptions = []
    Left = 400
    Top = 208
  end
  object DataSource1: TDataSource
    DataSet = EasyQuery1
    Left = 352
    Top = 208
  end
end
