object Form1: TForm1
  Left = 133
  Top = 67
  Width = 584
  Height = 426
  Caption = 'EasyTable Encryption Demo. (c) AidAim Software, 2002.'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 121
    Top = 19
    Width = 329
    Height = 16
    Caption = 'This demo illustrates how to work with encrypted tables. '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 52
    Width = 576
    Height = 239
    Align = alBottom
    Caption = ' Encrypted table EMPLOYEES '
    TabOrder = 0
    object DBGrid1: TDBGrid
      Left = 7
      Top = 20
      Width = 384
      Height = 176
      DataSource = DataSource1
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -10
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'id'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Name'
          Width = 107
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Surname'
          Width = 115
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'Comments'
          Visible = True
        end>
    end
    object DBMemo1: TDBMemo
      Left = 403
      Top = 20
      Width = 163
      Height = 176
      DataField = 'Comments'
      DataSource = DataSource1
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object DBNavigator1: TDBNavigator
      Left = 8
      Top = 208
      Width = 240
      Height = 25
      DataSource = DataSource1
      TabOrder = 2
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 291
    Width = 576
    Height = 108
    Align = alBottom
    TabOrder = 1
    object Label2: TLabel
      Left = 7
      Top = 18
      Width = 49
      Height = 13
      Caption = 'Password:'
    end
    object edPass: TEdit
      Left = 72
      Top = 15
      Width = 111
      Height = 21
      TabOrder = 0
      Text = 'password'
    end
    object btnCreate: TButton
      Left = 192
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Create table'
      TabOrder = 1
      OnClick = bnCreateClick
    end
    object btnOpen: TButton
      Left = 6
      Top = 64
      Width = 75
      Height = 25
      Caption = 'Open table'
      TabOrder = 2
      OnClick = bnOpenClick
    end
    object btnSetPwd: TButton
      Left = 193
      Top = 64
      Width = 75
      Height = 25
      Caption = 'Set password'
      TabOrder = 3
      OnClick = bnSetClick
    end
    object btnDecrypt: TButton
      Left = 286
      Top = 64
      Width = 75
      Height = 25
      Caption = 'Decrypt table'
      TabOrder = 4
      OnClick = btnDecryptClick
    end
    object btnClose: TButton
      Left = 99
      Top = 64
      Width = 75
      Height = 25
      Caption = 'Close table'
      TabOrder = 5
      OnClick = btnCloseClick
    end
  end
  object EasyTable1: TEasyTable
    CurrentVersion = '3.00 '
    TableName = 'encryption'
    DatabaseName = 'DBDemos'
    FilterOptions = []
    InMemory = False
    Left = 8
    Top = 8
  end
  object EasyDatabase1: TEasyDatabase
    DatabaseFileName = '..\..\Data\DBDemos.edb'
    DatabaseName = 'DBDemos'
    InMemory = False
    ReadOnly = False
    Left = 48
    Top = 8
  end
  object DataSource1: TDataSource
    DataSet = EasyTable1
    Left = 88
    Top = 8
  end
end
