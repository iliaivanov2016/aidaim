object Form2: TForm2
  Left = 390
  Top = 391
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'AutoInc field parameters'
  ClientHeight = 218
  ClientWidth = 267
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 7
    Top = 46
    Width = 27
    Height = 13
    Caption = 'Type:'
  end
  object Label2: TLabel
    Left = 143
    Top = 137
    Width = 50
    Height = 13
    Caption = 'Increment:'
  end
  object Label3: TLabel
    Left = 7
    Top = 91
    Width = 74
    Height = 13
    Caption = 'Minimum Value:'
  end
  object Label4: TLabel
    Left = 7
    Top = 137
    Width = 77
    Height = 13
    Caption = 'Maximum Value:'
  end
  object Label5: TLabel
    Left = 143
    Top = 91
    Width = 57
    Height = 13
    Caption = 'Initial Value:'
  end
  object Label6: TLabel
    Left = 7
    Top = 20
    Width = 31
    Height = 13
    Caption = 'Name:'
  end
  object ComboBox1: TComboBox
    Left = 46
    Top = 39
    Width = 208
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    Items.Strings = (
      'AutoInc'
      'AutoIncShortint'
      'AutoIncSmallint'
      'AutoIncInteger'
      'AutoIncLargeint'
      'AutoIncByte'
      'AutoIncWord'
      'AutoIncCardinal')
  end
  object SpinEdit1: TSpinEdit
    Left = 13
    Top = 150
    Width = 105
    Height = 26
    MaxValue = 1000000
    MinValue = 0
    TabOrder = 1
    Value = 0
  end
  object SpinEdit2: TSpinEdit
    Left = 150
    Top = 104
    Width = 104
    Height = 26
    MaxValue = 1000000
    MinValue = -1
    TabOrder = 2
    Value = -1
  end
  object SpinEdit3: TSpinEdit
    Left = 150
    Top = 150
    Width = 104
    Height = 26
    MaxValue = 1000000
    MinValue = 1
    TabOrder = 3
    Value = 1
  end
  object SpinEdit4: TSpinEdit
    Left = 13
    Top = 104
    Width = 105
    Height = 26
    MaxValue = 1000000
    MinValue = -1
    TabOrder = 4
    Value = -1
  end
  object CheckBox1: TCheckBox
    Left = 13
    Top = 72
    Width = 79
    Height = 13
    Caption = 'Cycled'
    TabOrder = 5
  end
  object BitBtn1: TBitBtn
    Left = 46
    Top = 182
    Width = 72
    Height = 25
    TabOrder = 6
    Kind = bkOK
  end
  object BitBtn2: TBitBtn
    Left = 150
    Top = 182
    Width = 72
    Height = 25
    TabOrder = 7
    Kind = bkCancel
  end
  object Edit1: TEdit
    Left = 46
    Top = 13
    Width = 208
    Height = 24
    TabOrder = 8
    Text = 'ID'
  end
end
