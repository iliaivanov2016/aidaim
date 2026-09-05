object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 
    'SQL demo for SQLMemTable. (c) AidAim Software, 2009. http://www.' +
    'aidaim.com'
  ClientHeight = 573
  ClientWidth = 792
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object reSQL: TRichEdit
    Left = 0
    Top = 0
    Width = 792
    Height = 265
    Align = alTop
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 265
    Width = 792
    Height = 48
    Align = alTop
    TabOrder = 1
    object lbRecCount: TLabel
      Left = 274
      Top = 20
      Width = 124
      Height = 13
      AutoSize = False
      Caption = 'RecordCount: '
    end
    object lbTime: TLabel
      Left = 408
      Top = 20
      Width = 124
      Height = 13
      AutoSize = False
      Caption = 'Time, seconds: '
    end
    object bnOpen: TButton
      Left = 8
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Open Query'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = bnOpenClick
    end
    object bnExecSQL: TButton
      Left = 100
      Top = 14
      Width = 75
      Height = 25
      Caption = 'ExecSQL'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = bnExecSQLClick
    end
    object bnClose: TButton
      Left = 192
      Top = 14
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 2
      OnClick = bnCloseClick
    end
    object DBNavigator1: TDBNavigator
      Left = 544
      Top = 14
      Width = 240
      Height = 25
      DataSource = DataSource1
      TabOrder = 3
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 313
    Width = 792
    Height = 260
    Align = alClient
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object DataSource1: TDataSource
    DataSet = SQLMemQuery1
    Left = 464
    Top = 208
  end
  object SQLMemQuery1: TSQLMemQuery
    CurrentVersion = '3.80 '
    ReadOnly = False
    SQL.Strings = (
      'drop table test1;'
      
        'create table test1 (id AutoInc(LargeInt, INITIALVALUE 3, INCREME' +
        'NT 3, MAXVALUE 7 minvalue 2 CYCLED),'
      '                    num Integer,'
      #9#9'    str'#9'varchar(100));'
      'insert into test1 (num, str) values (5,'#39'aaa'#39');'
      'insert into test1 (num) values (7);'
      'insert into test1 (num, str) values (5,'#39'bbb'#39');'
      'insert into test1 (num, str) values (4,'#39'test'#39');'
      'select * from test1 order by num desc,str asc;')
    Left = 304
    Top = 216
  end
end
