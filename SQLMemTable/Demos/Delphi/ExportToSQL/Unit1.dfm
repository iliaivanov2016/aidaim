object Form1: TForm1
  Left = 254
  Top = 103
  Width = 722
  Height = 548
  Caption = 'ExportToSQL demo. (c) AidAim Software LLC, 2004.'
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 714
    Height = 55
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 467
      Height = 13
      Caption = 
        'This demo shows how to export tables to SQL Script. Result SQL S' +
        'cript will be saved to file test.sql.'
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 480
    Width = 714
    Height = 41
    Align = alBottom
    TabOrder = 1
    object Button1: TButton
      Left = 6
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Export Tables'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button3: TButton
      Left = 260
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Execute SQL'
      TabOrder = 1
      OnClick = Button3Click
    end
    object Button2: TButton
      Left = 400
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 2
      OnClick = Button2Click
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 55
    Width = 714
    Height = 425
    Align = alClient
    TabOrder = 2
    object Splitter1: TSplitter
      Left = 258
      Top = 1
      Height = 423
    end
    object gbSQL: TGroupBox
      Left = 261
      Top = 1
      Width = 452
      Height = 423
      Align = alClient
      Caption = ' SQL Script '
      TabOrder = 0
      object Memo1: TRichEdit
        Left = 2
        Top = 15
        Width = 448
        Height = 406
        Align = alClient
        PlainText = True
        ScrollBars = ssBoth
        TabOrder = 0
        WantTabs = True
      end
    end
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 257
      Height = 423
      ActivePage = tsTables
      Align = alLeft
      TabOrder = 1
      object tsTables: TTabSheet
        Caption = 'Tables'
        object gbTables: TGroupBox
          Left = 0
          Top = 0
          Width = 249
          Height = 395
          Align = alClient
          Caption = ' Tables '
          TabOrder = 0
          object lbTables: TListBox
            Left = 2
            Top = 15
            Width = 245
            Height = 378
            Align = alClient
            ItemHeight = 13
            MultiSelect = True
            TabOrder = 0
          end
        end
      end
      object tsExportOptions: TTabSheet
        Caption = 'Export Options'
        ImageIndex = 1
        object gbExportOptions: TGroupBox
          Left = 0
          Top = 0
          Width = 249
          Height = 395
          Align = alClient
          Caption = ' Export Options '
          TabOrder = 0
          object GroupBox3: TGroupBox
            Left = 10
            Top = 16
            Width = 228
            Height = 65
            Caption = ' Export Structure Options '
            TabOrder = 0
            object cbExportStructure: TCheckBox
              Left = 8
              Top = 22
              Width = 97
              Height = 17
              Caption = 'Export Structure'
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object cbAddDROPTable: TCheckBox
              Left = 8
              Top = 39
              Width = 162
              Height = 17
              Caption = 'Add DROP TABLE command'
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
          end
          object GroupBox4: TGroupBox
            Left = 10
            Top = 176
            Width = 228
            Height = 65
            Caption = ' Export Data'
            TabOrder = 1
            object cbExportData: TCheckBox
              Left = 8
              Top = 20
              Width = 90
              Height = 17
              Caption = 'Export Data'
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object cbExportBLOBFields: TCheckBox
              Left = 8
              Top = 40
              Width = 110
              Height = 17
              Caption = 'Export BLOB fields'
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
          end
          object GroupBox5: TGroupBox
            Left = 10
            Top = 88
            Width = 228
            Height = 81
            Caption = ' Export Indexes Options '
            TabOrder = 2
            object cbExportIndexes: TCheckBox
              Left = 8
              Top = 24
              Width = 159
              Height = 17
              Caption = 'Export Indexes'
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object cbAddDROPIndex: TCheckBox
              Left = 8
              Top = 48
              Width = 161
              Height = 17
              Caption = 'Add DROP INDEX command'
              TabOrder = 1
            end
          end
          object cbUseBrackets: TCheckBox
            Left = 8
            Top = 256
            Width = 236
            Height = 17
            Caption = 'Use square brackets for names ([Field Name])'
            TabOrder = 3
          end
        end
      end
    end
  end
  object SQLMemTable1: TSQLMemTable
    CurrentVersion = '2.50 Prerelease Version #1'
    ReadOnly = False
    TableName = 'Table918857202'
    MemoryTableAllocBy = 1000
    Left = 168
    Top = 55
  end
  object SQLMemQuery1: TSQLMemQuery
    CurrentVersion = '2.50 Prerelease Version #1'
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
      ''
      'DROP TABLE Test;'
      
        'CREATE TABLE Test (id AutoInc, str CHAR(100) DEFAULT "aaa", num ' +
        'Integer);'
      'INSERT INTO Test(num) VALUES(5);'
      'SELECT * FROM Test;')
    Left = 464
    Top = 40
  end
end
