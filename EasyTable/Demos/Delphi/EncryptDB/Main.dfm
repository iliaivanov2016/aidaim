object Form1: TForm1
  Left = 209
  Top = 127
  Width = 584
  Height = 426
  Caption = 'EasyDatabase Encryption Demo. (c) AidAim Software, 2002.'
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
    Left = 121
    Top = 19
    Width = 350
    Height = 16
    Caption = 'This demo illustrates how to work with encrypted database. '
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
    Caption = 'EMPLOYEES: '
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
      Left = 15
      Top = 66
      Width = 85
      Height = 13
      Caption = 'Current password:'
    end
    object lbPass: TLabel
      Left = 109
      Top = 66
      Width = 45
      Height = 13
      Caption = 'password'
    end
    object btnCreate: TButton
      Left = 16
      Top = 14
      Width = 91
      Height = 25
      Caption = 'Create database'
      TabOrder = 0
      OnClick = bnCreateClick
    end
    object btnOpen: TButton
      Left = 118
      Top = 16
      Width = 91
      Height = 23
      Caption = 'Open database'
      TabOrder = 1
      OnClick = bnOpenClick
    end
    object btnSetPwd: TButton
      Left = 183
      Top = 62
      Width = 88
      Height = 25
      Caption = 'Set password'
      TabOrder = 2
      OnClick = bnSetClick
    end
    object btnDecrypt: TButton
      Left = 287
      Top = 62
      Width = 99
      Height = 25
      Caption = 'Decrypt database'
      TabOrder = 3
      OnClick = btnDecryptClick
    end
    object btnClose: TButton
      Left = 220
      Top = 14
      Width = 91
      Height = 25
      Caption = 'Close database'
      TabOrder = 4
      OnClick = btnCloseClick
    end
  end
  object EasyTable1: TEasyTable
    CurrentVersion = '3.03 '
    TableName = 'encryption'
    DatabaseName = 'DBDemos'
    FilterOptions = []
    InMemory = False
    Left = 8
    Top = 8
  end
  object EasyDatabase1: TEasyDatabase
    DatabaseFileName = '..\..\Data\CryptoDB.edb'
    DatabaseName = 'DBDemos'
    InMemory = False
    Password = 'password'
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
