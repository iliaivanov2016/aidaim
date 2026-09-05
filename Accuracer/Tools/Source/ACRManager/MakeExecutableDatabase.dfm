object fmMakeExeDatabase: TfmMakeExeDatabase
  Left = 325
  Top = 457
  BorderStyle = bsDialog
  Caption = 'Make Executable Database'
  ClientHeight = 109
  ClientWidth = 465
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label5: TLabel
    Left = 8
    Top = 21
    Width = 78
    Height = 13
    Caption = 'Executable File: '
  end
  object Label1: TLabel
    Left = 240
    Top = 20
    Width = 183
    Height = 13
    Caption = 'Destination Executable Database File: '
  end
  object Button1: TButton
    Left = 8
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 0
    OnClick = Button1Click
  end
  object edDBfile: TEdit
    Left = 8
    Top = 40
    Width = 217
    Height = 21
    TabOrder = 1
  end
  object edExeDBFile: TEdit
    Left = 240
    Top = 39
    Width = 217
    Height = 21
    TabOrder = 2
  end
  object Button2: TButton
    Left = 384
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Browse'
    TabOrder = 3
    OnClick = Button2Click
  end
  object BitBtn1: TBitBtn
    Left = 240
    Top = 72
    Width = 75
    Height = 25
    TabOrder = 4
    OnClick = BitBtn1Click
    Kind = bkCancel
  end
  object bnOK: TBitBtn
    Left = 150
    Top = 72
    Width = 75
    Height = 25
    TabOrder = 5
    OnClick = bnOKClick
    Kind = bkOK
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.exe'
    Filter = 'Executable file (*.exe)|*.exe|Any file (*.*)|*.*'
    FilterIndex = 0
    Title = 'Select executable file to merge with current database file:'
    Left = 400
    Top = 408
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.exe'
    Filter = 'Executable database file (*.exe)|*.exe|Any file (*.*)|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Select destination executable database file name: '
    Left = 328
    Top = 72
  end
end
