object Form1: TForm1
  Left = 192
  Top = 103
  Width = 935
  Height = 706
  Caption = 'MS SQL Server Console - ADO connection'
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
    Left = 0
    Top = 0
    Width = 927
    Height = 599
    Align = alClient
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Panel1: TPanel
    Left = 0
    Top = 599
    Width = 927
    Height = 80
    Align = alBottom
    TabOrder = 1
    object lbProg: TLabel
      Left = 256
      Top = 12
      Width = 145
      Height = 13
      AutoSize = False
    end
    object DBNavigator1: TDBNavigator
      Left = 8
      Top = 6
      Width = 240
      Height = 25
      DataSource = DataSource1
      TabOrder = 0
    end
    object reSQL: TRichEdit
      Left = 408
      Top = 1
      Width = 518
      Height = 78
      Align = alRight
      Lines.Strings = (
        'SELECT * '
        'FROM test')
      PlainText = True
      ScrollBars = ssBoth
      TabOrder = 1
    end
    object bnOpen: TButton
      Left = 8
      Top = 44
      Width = 75
      Height = 24
      Caption = 'Open Query'
      TabOrder = 2
      OnClick = bnOpenClick
    end
    object bnExec: TButton
      Left = 96
      Top = 44
      Width = 75
      Height = 24
      Caption = 'ExecSQL'
      TabOrder = 3
      OnClick = bnExecClick
    end
    object Button1: TButton
      Left = 184
      Top = 44
      Width = 65
      Height = 25
      Caption = 'Exit'
      TabOrder = 4
      OnClick = Button1Click
    end
  end
  object ADOQuery1: TADOQuery
    AutoCalcFields = False
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'select * from test')
    Left = 128
    Top = 80
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security In' +
      'fo=False;Initial Catalog=TestDB;Data Source=MONSTER-COMP'
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 72
    Top = 48
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 40
    Top = 152
  end
end
