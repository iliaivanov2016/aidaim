object Form1: TForm1
  Left = 239
  Top = 158
  Width = 562
  Height = 394
  Caption = 
    'Memo Search Demo. (c) AidAim Software LLC, 2004. http://www.aida' +
    'im.com'
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
  object Label1: TLabel
    Left = 16
    Top = 192
    Width = 53
    Height = 13
    Caption = 'SQL query:'
  end
  object Label2: TLabel
    Left = 344
    Top = 16
    Width = 57
    Height = 13
    Caption = 'Memo Field:'
  end
  object Label3: TLabel
    Left = 344
    Top = 128
    Width = 82
    Height = 13
    Caption = 'WideMemo Field:'
  end
  object Label4: TLabel
    Left = 344
    Top = 256
    Width = 74
    Height = 13
    Caption = 'FmtMemo Field:'
  end
  object DBGrid1: TDBGrid
    Left = 16
    Top = 16
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
    Top = 152
    Width = 240
    Height = 25
    DataSource = DataSource1
    TabOrder = 1
  end
  object Button1: TButton
    Left = 16
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Run Query'
    TabOrder = 2
    OnClick = Button1Click
  end
  object DBMemo1: TDBMemo
    Left = 344
    Top = 40
    Width = 185
    Height = 73
    DataField = 'text'
    DataSource = DataSource1
    TabOrder = 3
  end
  object DBMemo2: TDBMemo
    Left = 344
    Top = 152
    Width = 185
    Height = 89
    DataField = 'wtext'
    DataSource = DataSource1
    TabOrder = 4
  end
  object DBRichEdit1: TDBRichEdit
    Left = 344
    Top = 280
    Width = 185
    Height = 73
    DataField = 'ftext'
    DataSource = DataSource1
    TabOrder = 5
  end
  object Button2: TButton
    Left = 246
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Exit'
    TabOrder = 6
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 16
    Top = 224
    Width = 305
    Height = 89
    Lines.Strings = (
      'SELECT * FROM table1 WHERE wtext like "%aa"')
    TabOrder = 7
  end
  object Button3: TButton
    Left = 128
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Locate'
    TabOrder = 8
    OnClick = Button3Click
  end
  object DataSource1: TDataSource
    DataSet = SQLMemQuery1
    Left = 128
    Top = 88
  end
  object SQLMemQuery1: TSQLMemQuery
    CurrentVersion = '2.30 Prerelease Version #1'
    ReadOnly = False
    SQL.Strings = (
      'DROP TABLE table1;'
      
        'CREATE TABLE table1 (id autoinc, text memo, wtext widememo, ftex' +
        't FormattedMemo);'
      'insert into table1(text,wtext,ftext) values ('#39'aaa'#39','#39'aaa'#39','#39'aaa'#39');'
      'insert into table1(text,wtext,ftext) values ('#39'baa'#39','#39'baa'#39','#39'baa'#39');'
      'insert into table1(text,wtext,ftext) values ('#39'bbb'#39','#39'bbb'#39','#39'bbb'#39');'
      'SELECT * FROM table1;')
    Left = 8
    Top = 144
  end
end
