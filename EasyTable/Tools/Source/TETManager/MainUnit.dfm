object MainForm: TMainForm
  Left = 106
  Top = 119
  Caption = 'EasyTable Manager - Welcome'
  ClientHeight = 512
  ClientWidth = 788
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCanResize = FormCanResize
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 0
    Width = 772
    Height = 3
    Shape = bsBottomLine
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 788
    Height = 26
    AutoSize = True
    BorderWidth = 1
    Color = clBtnFace
    Images = ImageList1
    Indent = 5
    ParentColor = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Wrapable = False
    ExplicitWidth = 786
    object NewTableButton: TToolButton
      Left = 5
      Top = 0
      Hint = 'Create a new database'
      Caption = '&New database'
      ImageIndex = 0
      OnClick = FileNewExecute
    end
    object ToolButton1: TToolButton
      Left = 28
      Top = 0
      Hint = 'Open existing database'
      Caption = '&Open database'
      ImageIndex = 1
      OnClick = FileOpenExecute
    end
    object RepairButton: TToolButton
      Left = 51
      Top = 0
      Action = FileRepair
    end
    object ToolButton9: TToolButton
      Left = 74
      Top = 0
      Action = FileCompact
    end
    object ToolButton2: TToolButton
      Left = 97
      Top = 0
      Action = FileClose
    end
    object ToolButton3: TToolButton
      Left = 120
      Top = 0
      Width = 1
      Caption = 'ToolButton3'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton4: TToolButton
      Left = 121
      Top = 0
      Width = 8
      Caption = 'ToolButton4'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ToolButton5: TToolButton
      Left = 129
      Top = 0
      Action = acCreateTable
    end
    object ToolButton6: TToolButton
      Left = 152
      Top = 0
      Action = acOpenTable
    end
    object ToolButton7: TToolButton
      Left = 175
      Top = 0
      Action = acRestructureTable
    end
    object ToolButton8: TToolButton
      Left = 198
      Top = 0
      Action = acRepairTable
    end
    object ToolButton11: TToolButton
      Left = 221
      Top = 0
      Action = acRenameTable
    end
    object ToolButton12: TToolButton
      Left = 244
      Top = 0
      Action = acCopyTable
    end
    object ToolButton10: TToolButton
      Left = 267
      Top = 0
      Action = acEmptyTable
    end
    object ToolButton13: TToolButton
      Left = 290
      Top = 0
      Action = acDeleteTable
    end
    object ToolButton14: TToolButton
      Left = 313
      Top = 0
      Action = acCloseTable
    end
    object ToolButton15: TToolButton
      Left = 336
      Top = 0
      Width = 8
      Caption = 'ToolButton15'
      ImageIndex = 12
      Style = tbsSeparator
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 26
    Width = 788
    Height = 464
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 786
    ExplicitHeight = 456
    object Splitter1: TSplitter
      Left = 172
      Top = 0
      Height = 464
      ExplicitHeight = 460
    end
    object Notebook: TNotebook
      Left = 175
      Top = 0
      Width = 613
      Height = 464
      Align = alClient
      Color = clBtnFace
      PageIndex = 1
      ParentColor = False
      TabOrder = 0
      ExplicitWidth = 611
      ExplicitHeight = 456
      object TPage
        Left = 0
        Top = 0
        Caption = 'Welcome'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label4: TLabel
          Left = 264
          Top = 120
          Width = 50
          Height = 13
          Caption = 'Main page'
          Visible = False
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'CreateTable'
        ExplicitWidth = 611
        ExplicitHeight = 456
        object CreateTableControl: TPageControl
          Left = 0
          Top = 0
          Width = 613
          Height = 423
          ActivePage = StructureTab
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 611
          ExplicitHeight = 415
          object StructureTab: TTabSheet
            Caption = 'Table structure'
            OnShow = StructureTabShow
            object GroupBox1: TGroupBox
              Left = 0
              Top = 0
              Width = 605
              Height = 81
              Align = alTop
              TabOrder = 0
              TabStop = True
              ExplicitWidth = 603
              object Label2: TLabel
                Left = 5
                Top = 49
                Width = 120
                Height = 13
                Caption = 'BLOB Compression mode'
              end
              object Label3: TLabel
                Left = 247
                Top = 49
                Width = 78
                Height = 13
                Caption = 'BLOB block size'
              end
              object Label5: TLabel
                Left = 425
                Top = 49
                Width = 92
                Height = 13
                Caption = 'Last AutoInc value:'
              end
              object Compression_mode: TComboBox
                Left = 129
                Top = 45
                Width = 100
                Height = 21
                Style = csDropDownList
                TabOrder = 3
                Items.Strings = (
                  'clNone'
                  'clFastest'
                  'clDefault'
                  'clMax')
              end
              object Block_size: TSpinEdit
                Left = 339
                Top = 44
                Width = 81
                Height = 22
                Increment = 512
                MaxValue = 2147483647
                MinValue = 1
                TabOrder = 4
                Value = 512
              end
              object Encrypted: TCheckBox
                Left = 5
                Top = 14
                Width = 73
                Height = 17
                Caption = 'Encrypted'
                TabOrder = 0
                OnClick = EncryptedClick
              end
              object Password: TEdit
                Left = 129
                Top = 12
                Width = 290
                Height = 21
                Color = clSilver
                Enabled = False
                PasswordChar = '*'
                TabOrder = 1
              end
              object spAutoInc: TSpinEdit
                Left = 520
                Top = 44
                Width = 81
                Height = 22
                Hint = 
                  'This is a last value for auto incrment field in table. It will b' +
                  'e incremented before next adding record.'
                MaxValue = 2147483647
                MinValue = 0
                ParentShowHint = False
                ShowHint = True
                TabOrder = 5
                Value = 0
              end
              object CreateAutoIndexes: TCheckBox
                Left = 425
                Top = 14
                Width = 121
                Height = 17
                Caption = 'Create auto-indexes'
                TabOrder = 2
              end
            end
            object Panel1: TPanel
              Left = 0
              Top = 81
              Width = 605
              Height = 314
              Align = alClient
              BevelOuter = bvNone
              TabOrder = 1
              ExplicitWidth = 603
              ExplicitHeight = 306
              object FieldsGrid: TDBGrid
                Left = 0
                Top = 0
                Width = 567
                Height = 314
                Align = alClient
                DataSource = FieldsDataSource
                TabOrder = 0
                TitleFont.Charset = DEFAULT_CHARSET
                TitleFont.Color = clWindowText
                TitleFont.Height = -11
                TitleFont.Name = 'MS Sans Serif'
                TitleFont.Style = []
                Columns = <
                  item
                    Expanded = False
                    FieldName = 'Name'
                    Width = 212
                    Visible = True
                  end
                  item
                    Expanded = False
                    FieldName = 'Type'
                    Width = 134
                    Visible = True
                  end
                  item
                    Expanded = False
                    FieldName = 'Size'
                    Visible = True
                  end
                  item
                    Expanded = False
                    FieldName = 'Required'
                    Visible = True
                  end>
              end
              object Panel6: TPanel
                Left = 567
                Top = 0
                Width = 38
                Height = 314
                Align = alRight
                TabOrder = 1
                ExplicitLeft = 565
                ExplicitHeight = 306
                object SpinButton1: TSpinButton
                  Left = 7
                  Top = 127
                  Width = 26
                  Height = 40
                  Hint = 'Move field'
                  DownGlyph.Data = {
                    4E010000424D4E010000000000004E0000002800000010000000100000000100
                    08000000000000010000120B0000120B00000600000006000000FF0000008000
                    0000C8D0D40080808000FFFFFF00000000000202020202020202020202020202
                    0202020202020202020202020202020202020202020202020202020302020202
                    0202020202020202020201030302020202020202020202020200000103030202
                    0202020202020202000000000103030202020202020202000000000000010303
                    0202020202020000000000000101010202020202020202020000000001030202
                    0202020202020202000000000103020202020202020202020000000001030202
                    0202020202020202000000000103020202020202020202020000000001030202
                    0202020202020202000000000102020202020202020202020202020202020202
                    020202020202020202020202020202020202}
                  TabOrder = 0
                  UpGlyph.Data = {
                    4E010000424D4E010000000000004E0000002800000010000000100000000100
                    08000000000000010000120B0000120B00000600000006000000FF0000008000
                    0000C8D0D40080808000FFFFFF00000000000202020202020202020202020202
                    0202020202020202020303030303020202020202020202020101010101030202
                    0202020202020202000000000103020202020202020202020000000001030202
                    0202020202020202000000000103020202020202020202020000000001030202
                    0202020202020202000000000103030302020202020200000000000000000002
                    0202020202020200000000000000020202020202020202020000000000020202
                    0202020202020202020000000202020202020202020202020202000202020202
                    0202020202020202020202020202020202020202020202020202020202020202
                    020202020202020202020202020202020202}
                  OnDownClick = SpinButton1DownClick
                  OnUpClick = SpinButton1UpClick
                end
              end
            end
          end
          object IndexesTab: TTabSheet
            Caption = 'Indexes'
            ImageIndex = 1
            OnShow = IndexesTabShow
            object IndexGrid: TDBGrid
              Left = 0
              Top = 0
              Width = 605
              Height = 395
              Align = alClient
              DataSource = IndexDataSource
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -11
              TitleFont.Name = 'MS Sans Serif'
              TitleFont.Style = []
              OnCellClick = IndexGridCellClick
              OnColEnter = IndexGridColEnter
              OnDblClick = IndexGridDblClick
              OnEditButtonClick = IndexGridEditButtonClick
              Columns = <
                item
                  Expanded = False
                  FieldName = 'index_name'
                  Width = 75
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'Primary'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 41
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'Unique'
                  PickList.Strings = (
                    'True'
                    'False')
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'descending'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 66
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'case_insensitive'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 82
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'index_fields'
                  ReadOnly = True
                  Width = 70
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'desc_fields'
                  ReadOnly = True
                  Width = 94
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'case_ins_fields'
                  ReadOnly = True
                  Width = 111
                  Visible = True
                end>
            end
          end
        end
        object Panel8: TPanel
          Left = 0
          Top = 423
          Width = 613
          Height = 41
          Align = alBottom
          TabOrder = 1
          ExplicitTop = 415
          ExplicitWidth = 611
          object lbCreateQty: TLabel
            Left = 275
            Top = 13
            Width = 54
            Height = 13
            Hint = 'Fields'
            Alignment = taCenter
            AutoSize = False
            Caption = '0 / 0'
            ParentShowHint = False
            ShowHint = True
          end
          object Button1: TButton
            Left = 211
            Top = 7
            Width = 42
            Height = 25
            Caption = 'Clear'
            TabOrder = 0
            OnClick = Button1Click
          end
          object dbnCreateTable: TDBNavigator
            Left = 5
            Top = 7
            Width = 200
            Height = 25
            DataSource = FieldsDataSource
            TabOrder = 1
          end
          object btnOk: TBitBtn
            Left = 395
            Top = 7
            Width = 70
            Height = 25
            Kind = bkOK
            NumGlyphs = 2
            TabOrder = 2
            OnClick = btnOkClick
          end
          object btnCancel: TBitBtn
            Left = 475
            Top = 7
            Width = 70
            Height = 25
            Hint = 'Cancel'
            Caption = 'Cancel'
            Glyph.Data = {
              DE010000424DDE01000000000000760000002800000024000000120000000100
              0400000000006801000000000000000000001000000000000000000000000000
              80000080000000808000800000008000800080800000C0C0C000808080000000
              FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
              333333333333333333333333000033338833333333333333333F333333333333
              0000333911833333983333333388F333333F3333000033391118333911833333
              38F38F333F88F33300003339111183911118333338F338F3F8338F3300003333
              911118111118333338F3338F833338F3000033333911111111833333338F3338
              3333F8330000333333911111183333333338F333333F83330000333333311111
              8333333333338F3333383333000033333339111183333333333338F333833333
              00003333339111118333333333333833338F3333000033333911181118333333
              33338333338F333300003333911183911183333333383338F338F33300003333
              9118333911183333338F33838F338F33000033333913333391113333338FF833
              38F338F300003333333333333919333333388333338FFF830000333333333333
              3333333333333333333888330000333333333333333333333333333333333333
              0000}
            ModalResult = 2
            NumGlyphs = 2
            TabOrder = 3
            OnClick = btnCancelClick
          end
          object bnBorrow: TButton
            Left = 555
            Top = 7
            Width = 45
            Height = 25
            Hint = 'Borrow structure from another table'
            Caption = 'Borrow'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 4
            OnClick = bnBorrowClick
          end
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'EditTableData'
        object Panel4: TPanel
          Left = 0
          Top = 404
          Width = 613
          Height = 60
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 0
          object RecQty: TLabel
            Left = 273
            Top = 9
            Width = 88
            Height = 13
            Hint = 'Re'#241'No in current table / query'
            AutoSize = False
            ParentShowHint = False
            ShowHint = True
          end
          object lHindex: TLabel
            Left = 212
            Top = 9
            Width = 45
            Height = 13
            Hint = 'SQL history'
            AutoSize = False
            Caption = '0/0'
            ParentShowHint = False
            ShowHint = True
          end
          object Bevel2: TBevel
            Left = 264
            Top = 3
            Width = 2
            Height = 55
            Shape = bsRightLine
          end
          object RecQtyAll: TLabel
            Left = 273
            Top = 38
            Width = 88
            Height = 13
            Hint = 'Re'#241'ordCount in current table / query'
            AutoSize = False
            ParentShowHint = False
            ShowHint = True
          end
          object lbStructureQty: TLabel
            Left = 212
            Top = 38
            Width = 45
            Height = 13
            Hint = 'RecNo / RecordCount in fields, indexes or foreign keys tables'
            AutoSize = False
            Caption = '0/0'
            ParentShowHint = False
            ShowHint = True
          end
          object Label12: TLabel
            Left = 6
            Top = 38
            Width = 56
            Height = 13
            Caption = 'Set RecNo:'
          end
          object bnSetRecNo: TSpeedButton
            Left = 183
            Top = 33
            Width = 23
            Height = 22
            Glyph.Data = {
              76010000424D7601000000000000760000002800000020000000100000000100
              04000000000000010000120B0000120B00001000000000000000000000000000
              800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
              FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0033BBBBBBBBBB
              BB33337777777777777F33BB00BBBBBBBB33337F77333333F37F33BB0BBBBBB0
              BB33337F73F33337FF7F33BBB0BBBB000B33337F37FF3377737F33BBB00BB00B
              BB33337F377F3773337F33BBBB0B00BBBB33337F337F7733337F33BBBB000BBB
              BB33337F33777F33337F33EEEE000EEEEE33337F3F777FFF337F33EE0E80000E
              EE33337F73F77773337F33EEE0800EEEEE33337F37377F33337F33EEEE000EEE
              EE33337F33777F33337F33EEEEE00EEEEE33337F33377FF3337F33EEEEEE00EE
              EE33337F333377F3337F33EEEEEE00EEEE33337F33337733337F33EEEEEEEEEE
              EE33337FFFFFFFFFFF7F33EEEEEEEEEEEE333377777777777773}
            NumGlyphs = 2
            OnClick = bnSetRecNoClick
          end
          object dbnView: TDBNavigator
            Left = 6
            Top = 3
            Width = 200
            Height = 25
            DataSource = CurrentDataSource
            TabOrder = 0
          end
          object BitBtn6: TBitBtn
            Left = 520
            Top = 3
            Width = 84
            Height = 25
            Hint = 'Close table'
            Caption = '&Close table'
            Glyph.Data = {
              DE010000424DDE01000000000000760000002800000024000000120000000100
              0400000000006801000000000000000000001000000000000000000000000000
              80000080000000808000800000008000800080800000C0C0C000808080000000
              FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00388888888877
              F7F787F8888888888333333F00004444400888FFF444448888888888F333FF8F
              000033334D5007FFF4333388888888883338888F0000333345D50FFFF4333333
              338F888F3338F33F000033334D5D0FFFF43333333388788F3338F33F00003333
              45D50FEFE4333333338F878F3338F33F000033334D5D0FFFF43333333388788F
              3338F33F0000333345D50FEFE4333333338F878F3338F33F000033334D5D0FFF
              F43333333388788F3338F33F0000333345D50FEFE4333333338F878F3338F33F
              000033334D5D0EFEF43333333388788F3338F33F0000333345D50FEFE4333333
              338F878F3338F33F000033334D5D0EFEF43333333388788F3338F33F00003333
              4444444444333333338F8F8FFFF8F33F00003333333333333333333333888888
              8888333F00003333330000003333333333333FFFFFF3333F00003333330AAAA0
              333333333333888888F3333F00003333330000003333333333338FFFF8F3333F
              0000}
            NumGlyphs = 2
            ParentShowHint = False
            ShowHint = True
            TabOrder = 1
            OnClick = acCloseTableExecute
          end
          object bnOpenQuery: TButton
            Left = 366
            Top = 3
            Width = 75
            Height = 25
            Caption = 'Open Query'
            TabOrder = 2
            OnClick = OpenQuery1Click
          end
          object bnExecuteSQL: TButton
            Left = 443
            Top = 3
            Width = 75
            Height = 25
            Caption = 'Execute SQL'
            TabOrder = 3
            OnClick = ExecuteSQLscript1Click
          end
          object cbLiveQuery: TCheckBox
            Left = 368
            Top = 36
            Width = 73
            Height = 17
            Caption = 'Live Query'
            TabOrder = 4
          end
          object bnSQL: TButton
            Left = 443
            Top = 32
            Width = 75
            Height = 25
            Hint = 'Export current table structure to SQL'
            Caption = 'Struc. to SQL'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 5
            OnClick = bnSQLClick
          end
          object bnPrint: TBitBtn
            Left = 520
            Top = 32
            Width = 84
            Height = 25
            Hint = 'Print current SQL statement'
            Caption = 'Print SQL'
            Glyph.Data = {
              76010000424D7601000000000000760000002800000020000000100000000100
              04000000000000010000130B0000130B00001000000000000000000000000000
              800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
              FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00300000000000
              00033FFFFFFFFFFFFFFF0888888888888880777777777777777F088888888888
              8880777777777777777F0000000000000000FFFFFFFFFFFFFFFF0F8F8F8F8F8F
              8F80777777777777777F08F8F8F8F8F8F9F0777777777777777F0F8F8F8F8F8F
              8F807777777777777F7F0000000000000000777777777777777F3330FFFFFFFF
              03333337F3FFFF3F7F333330F0000F0F03333337F77773737F333330FFFFFFFF
              03333337F3FF3FFF7F333330F00F000003333337F773777773333330FFFF0FF0
              33333337F3FF7F3733333330F08F0F0333333337F7737F7333333330FFFF0033
              33333337FFFF7733333333300000033333333337777773333333}
            NumGlyphs = 2
            ParentShowHint = False
            ShowHint = True
            TabOrder = 6
            OnClick = bnPrintClick
          end
          object seRecNo: TSpinEdit
            Left = 68
            Top = 33
            Width = 110
            Height = 22
            Increment = 1000
            MaxValue = 0
            MinValue = 0
            TabOrder = 7
            Value = 0
          end
        end
        object pcDataSQL: TPageControl
          Left = 0
          Top = 0
          Width = 613
          Height = 404
          Hint = 'Switch Panels (Shift F12)'
          ActivePage = tsData
          Align = alClient
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          object tsData: TTabSheet
            Caption = 'Data'
            OnShow = tsDataShow
            object OpenGrid: TDBGrid
              Left = 0
              Top = 0
              Width = 605
              Height = 376
              Hint = 
                'If you want to order table data by some field click on correspon' +
                'ding column header.'
              Align = alClient
              DataSource = CurrentDataSource
              ParentShowHint = False
              ShowHint = True
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -11
              TitleFont.Name = 'MS Sans Serif'
              TitleFont.Style = []
              OnCellClick = OpenGridCellClick
              OnTitleClick = OpenGridTitleClick
            end
          end
          object tsViewFields: TTabSheet
            Caption = 'Fields'
            ImageIndex = 1
            OnShow = tsViewFieldsShow
            object DBGrid1: TDBGrid
              Left = 0
              Top = 0
              Width = 605
              Height = 376
              Align = alClient
              DataSource = FieldsDataSource
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -11
              TitleFont.Name = 'MS Sans Serif'
              TitleFont.Style = []
              Columns = <
                item
                  Expanded = False
                  FieldName = 'Name'
                  Width = 320
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'Type'
                  Width = 134
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'Size'
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'Required'
                  Visible = True
                end>
            end
          end
          object tsViewIndexes: TTabSheet
            Caption = 'Indexes'
            ImageIndex = 2
            OnShow = tsViewIndexesShow
            object DBGrid2: TDBGrid
              Left = 0
              Top = 0
              Width = 605
              Height = 376
              Align = alClient
              DataSource = IndexDataSource
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -11
              TitleFont.Name = 'MS Sans Serif'
              TitleFont.Style = []
              OnCellClick = IndexGridCellClick
              OnColEnter = IndexGridColEnter
              OnDblClick = IndexGridDblClick
              OnEditButtonClick = IndexGridEditButtonClick
              Columns = <
                item
                  Expanded = False
                  FieldName = 'index_name'
                  Width = 75
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'Primary'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 41
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'Unique'
                  PickList.Strings = (
                    'True'
                    'False')
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'descending'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 66
                  Visible = True
                end
                item
                  DropDownRows = 2
                  Expanded = False
                  FieldName = 'case_insensitive'
                  PickList.Strings = (
                    'True'
                    'False')
                  Width = 82
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'index_fields'
                  ReadOnly = True
                  Width = 70
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'desc_fields'
                  ReadOnly = True
                  Width = 94
                  Visible = True
                end
                item
                  Expanded = False
                  FieldName = 'case_ins_fields'
                  ReadOnly = True
                  Width = 111
                  Visible = True
                end>
            end
          end
          object tsSQL: TTabSheet
            Caption = 'SQL'
            ImageIndex = 3
            OnShow = tsSQLShow
            object mSQL: TRichEdit
              Left = 0
              Top = 0
              Width = 605
              Height = 376
              Hint = 'Click on right mouse button to open SQL History menu'
              Align = alClient
              Font.Charset = RUSSIAN_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Pitch = fpFixed
              Font.Style = []
              ParentFont = False
              PlainText = True
              PopupMenu = PopupMenuSQL
              ScrollBars = ssBoth
              TabOrder = 0
              WantTabs = True
              OnChange = mSQLChange
            end
          end
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Manage database'
        ExplicitWidth = 0
        ExplicitHeight = 0
      end
    end
    object Panel5: TPanel
      Left = 0
      Top = 0
      Width = 172
      Height = 464
      Align = alLeft
      TabOrder = 1
      OnCanResize = Panel5CanResize
      ExplicitHeight = 456
      object lbSelectedTables: TLabel
        Left = 1
        Top = 1
        Width = 170
        Height = 13
        Align = alTop
        Alignment = taCenter
        Caption = 'Selected tables: 0 of 0'
        ExplicitWidth = 106
      end
      object lbTableList: TListBox
        Left = 1
        Top = 14
        Width = 170
        Height = 203
        Align = alClient
        ItemHeight = 13
        MultiSelect = True
        Sorted = True
        TabOrder = 0
        OnClick = lbTableListClick
        OnDblClick = acOpenTableExecute
        ExplicitHeight = 211
      end
      object ScrollBox1: TScrollBox
        Left = 1
        Top = 217
        Width = 170
        Height = 246
        Align = alBottom
        Anchors = [akLeft, akTop, akRight, akBottom]
        AutoSize = True
        TabOrder = 1
        ExplicitTop = 225
        DesignSize = (
          166
          242)
        object BitBtn1: TBitBtn
          Left = 17
          Top = 0
          Width = 120
          Height = 24
          Action = acCreateTable
          Anchors = [akBottom]
          Caption = '&New table'
          ImageIndex = 0
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            0000FFFFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00000000000000000000000000000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 0
        end
        object BitBtn2: TBitBtn
          Left = 17
          Top = 24
          Width = 120
          Height = 24
          Action = acOpenTable
          Anchors = [akBottom]
          Caption = '&Open table'
          ImageIndex = 1
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000008484000084840000848400008484000084840000848400008484000084
            84000084840000000000FF00FF00FF00FF00FF00FF00FF00FF000000000000FF
            FF00000000000084840000848400008484000084840000848400008484000084
            8400008484000084840000000000FF00FF00FF00FF00FF00FF0000000000FFFF
            FF0000FFFF000000000000848400008484000084840000848400008484000084
            840000848400008484000084840000000000FF00FF00FF00FF000000000000FF
            FF00FFFFFF0000FFFF0000000000008484000084840000848400008484000084
            84000084840000848400008484000084840000000000FF00FF0000000000FFFF
            FF0000FFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
            00000000000000000000000000000000000000000000000000000000000000FF
            FF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FF
            FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000FFFF
            FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFF
            FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FF
            FF00FFFFFF0000FFFF0000000000000000000000000000000000000000000000
            000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            00000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00000000000000000000000000FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF000000000000000000FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000FF00
            FF00FF00FF00FF00FF0000000000FF00FF0000000000FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            00000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 1
        end
        object BitBtn3: TBitBtn
          Left = 17
          Top = 48
          Width = 120
          Height = 24
          Action = acRestructureTable
          Anchors = [akBottom]
          Caption = 'Re&structure'
          ImageIndex = 5
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF0000000000FFFFFF00FFFFFF0000000000FF00
            FF00FF00FF000000FF00000080000000FF00FF00FF0000000000FF00FF007F7F
            7F00000000000000000000000000FFFFFF00FFFFFF0000000000FF00FF00FF00
            FF00FF00FF000000FF00000080000000FF0000000000008080007F7F7F000000
            0000FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00
            FF00FF00FF000000FF00000080000000FF00008080000080800000000000FFFF
            FF000000000000000000FFFFFF00FFFFFF0000000000FF00FF00FF00FF00FF00
            FF00FF00FF000000FF00000080000000FF000080800000808000000000000000
            0000FF00FF00FF00FF0000000000FFFFFF0000000000FF00FF00FF00FF00FF00
            FF00FF00FF000000FF00000080000000FF0000808000FF00FF00000000007F7F
            7F00FF00FF00FF00FF0000000000FFFFFF0000000000FF00FF00FF00FF00FF00
            FF000000FF000000FF000000FF000000FF000000FF00FF00FF00FF00FF00FF00
            FF007F7F7F0000000000FFFFFF00000000007F7F7F00FF00FF00FF00FF000000
            00000000800000008000000080000000800000008000FF00FF00FF00FF00FF00
            FF000000000000000000000000007F7F7F00FF00FF00FF00FF00000000000080
            8000008080000080800000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000008080000080
            800000808000FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000FF00FF00FF00FF000000000000808000008080000080
            8000FF00FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00FF000000
            0000FF00FF0000000000FF00FF0000000000008080000080800000808000FF00
            FF00FF00FF00FF00FF0000000000FF00FF00FF00FF00FF00FF0000000000FF00
            FF00000000000000000000000000008080000080800000808000FF00FF00FF00
            FF00FF00FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00000000000000
            00000000000000000000000000000000000000808000FF00FF00FF00FF00FF00
            FF00FF00FF007F7F7F00000000007F7F7F00FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000000000000000000000000000FF00FF00FF00FF00FF00
            FF00FF00FF007F7F7F00000000007F7F7F00FF00FF00FF00FF00FF00FF00FF00
            FF0000808000000000000000000000000000000000007F7F7F00FF00FF00FF00
            FF00FF00FF007F7F7F00000000007F7F7F00FF00FF00FF00FF00FF00FF00FF00
            FF000080800000808000FF00FF00000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 2
        end
        object BitBtn10: TBitBtn
          Left = 17
          Top = 73
          Width = 120
          Height = 24
          Action = acChangePasswordOfTable
          Anchors = [akBottom]
          Caption = '&Change password'
          ImageIndex = 16
          Glyph.Data = {
            36030000424D3603000000000000360000002800000010000000100000000100
            1800000000000003000000000000000000000000000000000000FF00FFFF00FF
            FF00FFFF00FFFF00FFFF00FF000000000000000000000000000000FF00FFFF00
            FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF000000000000BFBFBFBF
            BFBFBFBFBFBFBFBFBFBFBF000000000000FF00FFFF00FFFF00FFFF00FFFF00FF
            FF00FF0000007F7F7F7F7F7FBFBFBF7F7F7F0000007F7F7FBFBFBF7F7F7F7F7F
            7F000000FF00FFFF00FFFF00FFFF00FF000000BFBFBFBFBFBFBFBFBFBFBFBF7F
            7F7F0000007F7F7FBFBFBFBFBFBFBFBFBFBFBFBF000000FF00FFFF00FFFF00FF
            0000007F7F7F7F7F7F7F7F7FBFBFBFBFBFBF000000BFBFBFBFBFBF7F7F7F7F7F
            7F7F7F7F000000FF00FFFF00FFFF00FF000000BFBFBFBFBFBFBFBFBFBFBFBF00
            0000000000000000BFBFBFBFBFBFBFBFBFBFBFBF000000FF00FFFF00FFFF00FF
            0000007F7F7F7F7F7F7F7F7F7F7F7F0000000000000000007F7F7F7F7F7F7F7F
            7F7F7F7F000000FF00FFFF00FFFF00FF000000BFBFBFBFBFBFBFBFBFBFBFBFBF
            BFBFBFBFBFBFBFBFBFBFBFBFBFBFBFBFBFBFBFBF000000FF00FFFF00FFFF00FF
            FF00FF0000000000000000000000000000000000000000000000000000000000
            00000000FF00FFFF00FFFF00FFFF00FFFF00FFFF00FF000000BFBFBF000000FF
            00FFFF00FFFF00FF000000BFBFBF000000FF00FFFF00FFFF00FFFF00FFFF00FF
            FF00FFFF00FF000000BFBFBF000000FF00FFFF00FFFF00FF000000BFBFBF0000
            00FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF000000BFBFBF000000FF
            00FFFF00FFFF00FF000000BFBFBF000000FF00FFFF00FFFF00FFFF00FFFF00FF
            FF00FFFF00FF7F7F7F7F7F7FBFBFBF000000000000000000BFBFBF7F7F7F7F7F
            7FFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF000000BFBFBFBF
            BFBFBFBFBFBFBFBFBFBFBF000000FF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
            FF00FFFF00FFFF00FFFF00FF000000000000000000000000000000FF00FFFF00
            FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
            00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
          Margin = 3
          TabOrder = 3
        end
        object BitBtn5: TBitBtn
          Left = 17
          Top = 97
          Width = 120
          Height = 24
          Action = acRepairTable
          Anchors = [akBottom]
          Caption = '&Repair tables'
          ImageIndex = 6
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF000000000000000000FF00FF00FF00FF00FF00FF000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000000000000000000000000000FF00FF00000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            000000000000000000000000000000000000000000000000000000000000FFFF
            FF00BFBFBF00BFBFBF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00BFBFBF00FFFF
            FF00FFFFFF00FFFFFF00BFBFBF00BFBFBF00FFFFFF000000000000000000FFFF
            FF00FFFFFF00FFFFFF000000FF00FFFFFF00FFFFFF00FFFFFF00BFBFBF00FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF007F7F7F000000000000000000FFFF
            FF00FFFFFF000000FF000000FF000000FF00FFFFFF00FFFFFF00BFBFBF000000
            00000000000000000000000000000000000000000000FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF000000FF00FFFFFF00FFFFFF00FFFFFF0000000000BFBF
            BF00BFBFBF00BFBFBF00BFBFBF0000000000FF00FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000BFBF
            BF00BFBFBF00BFBFBF0000000000FF00FF00FF00FF00FF00FF007F7F7F000000
            0000000000000000000000000000000000000000000000000000000000000000
            00000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000FF00FF00FF000000
            FF000000FF000000FF00FF00FF000000FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000FF00FF00
            FF00FF00FF00FF00FF000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 4
        end
        object BitBtn7: TBitBtn
          Left = 17
          Top = 121
          Width = 120
          Height = 24
          Action = acRenameTable
          Anchors = [akBottom]
          Caption = 'R&ename tables'
          ImageIndex = 8
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF000000
            0000000000000000000000000000000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
            FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF0000000000FFFF
            FF00FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000000000000000
            0000000000000000000000000000FF00FF00000000000000000000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000000000FFFF00FFFF
            FF0000FFFF00FFFFFF0000FFFF000000000000000000FFFF000000000000FFFF
            FF0000000000FFFF0000FFFF0000FFFF0000FFFF000000000000000000000000
            0000FFFFFF0000FFFF00FFFFFF0000FFFF0000000000FFFF000000000000FFFF
            FF00FFFFFF000000000000000000FFFFFF0000000000FFFFFF0000FFFF00FFFF
            FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000000000FFFF000000000000FFFF
            FF00FFFF00000000000000FFFF00000000000000000000000000000000000000
            0000FFFFFF0000FFFF00FFFFFF0000FFFF0000000000FFFF000000000000FFFF
            FF00FFFFFF00FFFFFF0000000000FFFFFF0000FFFF00FFFFFF0000FFFF00FFFF
            FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000000000FFFF000000000000FFFF
            FF00FFFF0000FFFF0000FFFF0000000000000000000000000000000000000000
            00000000000000000000FFFFFF0000FFFF0000000000FFFF000000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000000000FFFF00000000000000
            000000FFFF00FFFFFF0000FFFF0000000000000000000000000000000000FFFF
            FF00FFFF0000FFFF0000FFFF0000FFFF0000FFFF00000000000000FFFF000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000000000FF
            FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000FFFFFF0000000000FFFFFF0000000000FFFFFF0000000000FFFFFF000000
            000000FFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            00007F7F7F00000000007F7F7F00000000007F7F7F00000000007F7F7F000000
            00000000000000FFFF0000000000FF00FF00FF00FF00FF00FF00FF00FF000000
            00007F7F7F00000000007F7F7F00000000007F7F7F00000000007F7F7F000000
            0000FF00FF00000000000000FF0000000000FF00FF00FF00FF0000000000FF00
            FF0000000000FF00FF0000000000FF00FF0000000000FF00FF0000000000FF00
            FF00FF00FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 5
        end
        object BitBtn8: TBitBtn
          Left = 17
          Top = 145
          Width = 120
          Height = 24
          Action = acCopyTable
          Anchors = [akBottom]
          Caption = 'Co&py tables'
          ImageIndex = 7
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FFFF007F7F7F00FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000FFFF0000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FFFF007F7F7F00FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000FFFF0000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FFFF007F7F7F00FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000FFFF0000000000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FFFF007F7F7F00FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000FFFF0000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000000
            00007F7F7F007F7F7F0000000000000000007F7F7F000000000000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            000000000000000000007F7F7F007F7F7F0000FFFF000000000000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            000000000000000000007F7F7F0000FFFF0000FFFF000000000000000000FFFF
            FF000000000000000000FFFFFF00000000000000000000000000FFFFFF000000
            000000000000000000000000FF0000000000000000007F7F7F0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            0000FF00FF000000FF000000FF000000FF00FF00FF00FF00FF0000000000FFFF
            FF0000000000000000000000000000000000FFFFFF0000000000FFFFFF000000
            00000000FF000000FF000000FF000000FF000000FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
            FF000000FF000000FF000000FF000000FF000000FF000000FF0000000000FFFF
            FF000000000000000000FFFFFF00000000000000000000000000000000000000
            0000FF00FF000000FF000000FF000000FF00FF00FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF0000000000FFFFFF00FFFFFF0000000000FF00
            FF00FF00FF000000FF000000FF000000FF00FF00FF00FF00FF0000000000FFFF
            FF0000000000BFBFBF00FFFFFF0000000000FFFFFF0000000000FF00FF00FF00
            FF007F7F7F000000FF000000FF000000FF00FF00FF00FF00FF0000000000FFFF
            FF00FFFFFF00FFFFFF00FFFFFF000000000000000000FF00FF000000FF000000
            FF000000FF000000FF000000FF00FF00FF00FF00FF00FF00FF00000000000000
            000000000000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 6
        end
        object BitBtn9: TBitBtn
          Left = 17
          Top = 170
          Width = 120
          Height = 24
          Action = acEmptyTable
          Anchors = [akBottom]
          Caption = 'E&mpty tables'
          ImageIndex = 13
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF000000
            0000000000000000000000000000FF00FF00000000000000000000000000FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000000000000000000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000FF00FF00FF00FF00000000000000000000000000FF00FF00FF00FF000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00000000000000
            0000FF00FF00FF00FF00FF00FF000000000000000000FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            000000000000FF00FF00FF00FF000000000000000000FF00FF00000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000FF00FF0000000000FF00FF0000000000000080000000
            800000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF0000000000FF00FF00000000000000FF000000FF000000
            FF000000800000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            000000000000FF00FF00FF00FF00FF00FF00000000000000FF000000FF000000
            FF000000FF000000800000000000FF00FF00FF00FF00FF00FF00FF00FF000000
            000000000000FF00FF0000000000FF00FF00FF00FF00000000000000FF000000
            FF000000FF00000000000080800000000000FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000FF00FF0000000000FF00FF00FF00FF00000000000000
            FF000000000000FFFF00000000000080800000000000FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            000000FFFF000000000000FFFF00000000000080800000000000FF00FF00FF00
            FF00FF00FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF000000000000FFFF000000000000FFFF000080800000808000FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF000000000000FFFF0000FFFF0000FFFF0000808000FF00FF00FF00
            FF00FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF000000000000FFFF0000FFFF0000FFFF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF000000000000FFFF0000FFFF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF000000000000FFFF00}
          Margin = 3
          TabOrder = 7
        end
        object BitBtn4: TBitBtn
          Left = 17
          Top = 194
          Width = 120
          Height = 24
          Action = acDeleteTable
          Anchors = [akBottom]
          Caption = '&Delete tables'
          ImageIndex = 12
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF00FF00
            FF00FF00FF000000000000000000000000000000000000000000000000000000
            00000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF007F7F7F007F7F7F007F7F7F007F7F7F007F7F
            7F007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF0000000000BFBFBF000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF00000000007F7F7F000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF0000000000BFBFBF000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF00000000007F7F7F000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF0000000000BFBFBF000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF000000
            0000FF00FF0000000000FFFFFF0000000000BFBFBF00000000007F7F7F000000
            00007F7F7F0000000000FF00FF0000000000FF00FF00FF00FF00FF00FF00FF00
            FF000000000000000000FFFFFF0000000000BFBFBF0000000000BFBFBF000000
            00007F7F7F000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0000000000FFFFFF0000000000BFBFBF00000000007F7F7F000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00000000007F7F7F00000000007F7F7F00000000007F7F7F000000
            00007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF0000000000FFFFFF00BFBFBF00BFBFBF00BFBFBF007F7F7F007F7F7F007F7F
            7F007F7F7F007F7F7F0000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00000000000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00000000007F7F7F007F7F7F007F7F7F000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 8
        end
        object BitBtn11: TBitBtn
          Left = 17
          Top = 218
          Width = 120
          Height = 24
          Action = acCloseTable
          Anchors = [akBottom]
          Caption = '&Close table'
          ImageIndex = 14
          Glyph.Data = {
            36040000424D3604000000000000360000002800000010000000100000000100
            2000000000000004000000000000000000000000000000000000FF00FF008080
            8000808080008080800080808000808080008080800080808000C0C0C000C0C0
            C000C0C0C000FFFFFF00C0C0C00080808000FFFFFF0080808000800000008000
            0000800000008000000000000000000000008080800080808000FFFFFF00FFFF
            FF00800000008000000080000000800000008080800080808000FF00FF00FF00
            FF00FF00FF0080000000FF00FF008000800000000000C0C0C000FFFFFF00FFFF
            FF0080000000FF00FF00FF00FF00FF00FF008080800080808000FF00FF00FF00
            FF00FF00FF008000000080008000FF00FF0000000000FFFFFF00FFFFFF00FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF008000000080008000FF00FF0000000000FFFFFF00FFFF0000FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0080000000FF00FF008000800000000000FFFFFF00FFFFFF00FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF008000000080008000FF00FF0000000000FFFFFF00FFFF0000FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0080000000FF00FF008000800000000000FFFFFF00FFFFFF00FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF008000000080008000FF00FF0000000000FFFFFF00FFFF0000FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0080000000FF00FF008000800000000000FFFF0000FFFFFF00FFFF
            000080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF008000000080008000FF00FF0000000000FFFFFF00FFFF0000FFFF
            FF0080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF0080000000FF00FF008000800000000000FFFF0000FFFFFF00FFFF
            000080000000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF000000000000FF000000FF000000FF00000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
            FF00FF00FF00FF00FF00FF00FF00000000000000000000000000000000000000
            0000FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
          Margin = 3
          TabOrder = 9
        end
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 490
    Width = 788
    Height = 22
    AutoHint = True
    Panels = <>
    SimplePanel = True
    ExplicitTop = 482
    ExplicitWidth = 786
  end
  object ImageList1: TImageList
    Left = 496
    Top = 376
    Bitmap = {
      494C010113001800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000005000000001002000000000000050
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBDBD000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00007B7B7B007B7B7B00BDBDBD007B7B7B00000000007B7B7B00BDBDBD007B7B
      7B007B7B7B00000000000000000000000000C6C6C60084848400848484008484
      8400848484008484840084848400848484008484840084848400848484008484
      8400000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF000000
      00000000000000000000FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000BDBD
      BD00BDBDBD00BDBDBD00BDBDBD007B7B7B00000000007B7B7B00BDBDBD00BDBD
      BD00BDBDBD00BDBDBD000000000000000000FFFFFF00C6C6C600C6C6C600C6C6
      C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C6008484
      840000000000000000000000000000000000FFFF00000000000000000000FFFF
      FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF0000000000FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B7B
      7B007B7B7B007B7B7B00BDBDBD00BDBDBD0000000000BDBDBD00BDBDBD007B7B
      7B007B7B7B007B7B7B000000000000000000FFFFFF00C6C6C600C6C6C600C6C6
      C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C6008484
      840000000000000000000000000000000000FFFF000000000000FFFFFF0000FF
      FF00FFFFFF0000FFFF000000000000000000000000000000000000000000FFFF
      FF00FFFFFF0000000000FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000BDBD
      BD00BDBDBD00BDBDBD00BDBDBD00000000000000000000000000BDBDBD00BDBD
      BD00BDBDBD00BDBDBD000000000000000000FFFFFF00C6C6C6000000FF000000
      FF00C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C6008484
      840000000000000000000000000000000000FFFF00000000000000FFFF00FFFF
      FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF000000
      0000FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B7B
      7B007B7B7B007B7B7B007B7B7B000000000000000000000000007B7B7B007B7B
      7B007B7B7B007B7B7B000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00C6C6
      C60000000000000000000000000000000000FFFF000000000000FFFFFF0000FF
      FF00FFFFFF0000FFFF000000000000000000000000000000000000000000FFFF
      FF00FFFFFF0000000000FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000BDBD
      BD00BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBD
      BD00BDBDBD00BDBDBD0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFF00000000000000FFFF00FFFF
      FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF000000
      0000FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFF000000000000FFFFFF0000FF
      FF0000000000000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF0000000000FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000BDBDBD000000000000000000000000000000000000000000BDBD
      BD00000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFFFF0000FFFF00FFFFFF0000FF
      FF00FFFFFF0000FFFF00FFFFFF0000000000000000000000000000000000FFFF
      FF0000FFFF0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000BDBDBD000000000000000000000000000000000000000000BDBD
      BD00000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF00FFFFFF0000FFFF00FFFF
      FF0000FFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
      00000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000BDBDBD000000000000000000000000000000000000000000BDBD
      BD00000000000000000000000000000000000000000000000000848484000000
      000000000000000000000000000000000000FFFFFF0000FFFF00FFFFFF0000FF
      FF00FFFFFF0000FFFF00FFFFFF00000000000000000000000000000000000000
      00000000000000000000FFFFFF00000000000000000000000000FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00007B7B7B007B7B7B00BDBDBD00000000000000000000000000BDBDBD007B7B
      7B007B7B7B000000000000000000000000008484840000000000000000000000
      00000000000000000000000000000000000000FFFF00FFFFFF0000FFFF00FFFF
      FF0000FFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
      00000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0000000000FFFFFF00FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000BDBDBD00BDBDBD00BDBDBD00BDBDBD00BDBDBD000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000000FF
      FF00FFFFFF0000FFFF00FFFFFF00000000000000000000000000000000000000
      00000000000000000000FF000000FF000000FF000000FF000000FF000000FF00
      000000000000FFFFFF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF00FFFFFF0000FFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000084848400848484008484
      840084848400848484008484840084848400C6C6C600C6C6C600C6C6C600FFFF
      FF00C6C6C60084848400FFFFFF00848484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF007B7B7B007B7B7B007B7B7B007B7B7B007B7B7B007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008400000084000000840000008400
      000000000000000000008484840084848400FFFFFF00FFFFFF00840000008400
      0000840000008400000084848400848484008484840084848400848484008484
      8400848484008484840084848400848484008484840084848400848484000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD0000000000BDBDBD00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008400
      0000FF00FF008400840000000000C6C6C600FFFFFF00FFFFFF00840000000000
      0000000000000000000084848400848484008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF00848484008484
      8400000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD00000000007B7B7B00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008400
      000084008400FF00FF0000000000FFFFFF00FFFFFF00FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF008484840000FF
      FF00848484000000000000000000000000000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD0000000000BDBDBD00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008400
      000084008400FF00FF0000000000FFFFFF00FFFF0000FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF008484840000FF
      FF0000FFFF008484840000000000000000000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD00000000007B7B7B00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000840000008400000000000000
      0000000000000000000000000000000000000000000000000000000000008400
      0000FF00FF008400840000000000FFFFFF00FFFFFF00FFFFFF00840000000000
      0000000000000000000000000000000000008484840084848400848484008484
      84008484840084848400848484008484840084848400848484008484840000FF
      FF0000FFFF008484840084848400000000000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD0000000000BDBDBD00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF000000FF000000FF00000084000000
      0000000000000000000000000000000000000000000000000000000000008400
      000084008400FF00FF0000000000FFFFFF00FFFF0000FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF00848484008484
      840000FFFF008484840000FFFF00848484000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD00000000007B7B7B00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF000000FF000000FF000000FF000000
      8400000000000000000000000000000000000000000000000000000000008400
      0000FF00FF008400840000000000FFFFFF00FFFFFF00FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF008484840000FF
      FF00848484008484840000FFFF00848484000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD0000000000BDBDBD00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000FF000000FF000000FF000000
      0000008484000000000000000000000000000000000000000000000000008400
      000084008400FF00FF0000000000FFFFFF00FFFF0000FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF008484840000FF
      FF0000FFFF008484840000FFFF00848484000000000000000000000000000000
      0000FFFFFF0000000000BDBDBD00000000007B7B7B00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000FF000000000000FF
      FF00000000000084840000000000000000000000000000000000000000008400
      0000FF00FF008400840000000000FFFF0000FFFFFF00FFFF0000840000000000
      0000000000000000000000000000000000008484840084848400848484008484
      84008484840084848400848484008484840084848400848484008484840000FF
      FF0000FFFF008484840084848400848484000000000000000000000000000000
      00007B7B7B00000000007B7B7B00000000007B7B7B00000000007B7B7B000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000FFFF000000
      000000FFFF000000000000848400000000000000000000000000000000008400
      000084008400FF00FF0000000000FFFFFF00FFFF0000FFFFFF00840000000000
      0000000000000000000000000000000000008484840000FFFF0000FFFF0000FF
      FF0000FFFF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FFFF008484
      840000FFFF008484840000FFFF00848484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000000FF
      FF000000000000FFFF0000848400008484000000000000000000000000008400
      0000FF00FF008400840000000000FFFF0000FFFFFF00FFFF0000840000000000
      000000000000000000000000000000000000000000008484840000FFFF0000FF
      FF0000FFFF0000FFFF0000FFFF008484840000FFFF0000FFFF0000FFFF0000FF
      FF00848484008484840000FFFF0084848400000000000000000000000000FFFF
      FF00BDBDBD00BDBDBD00BDBDBD007B7B7B007B7B7B007B7B7B007B7B7B007B7B
      7B00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FFFF0000FFFF0000FFFF00008484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000848484008484
      8400848484008484840084848400848484008484840084848400848484008484
      8400848484008484840000FFFF00848484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FFFF0000FFFF0000FFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008484
      840000FFFF0000FFFF0000FFFF0000FFFF0000FFFF008484840000FFFF0000FF
      FF0000FFFF0000FFFF0084848400848484000000000000000000000000000000
      000000000000000000007B7B7B007B7B7B007B7B7B0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FFFF0000FFFF000000000000000000000000000000
      0000000000000000000000FF000000FF000000FF000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000848484008484840084848400848484008484840084848400848484008484
      8400848484008484840084848400848484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF0000000000000000000000
      000000000000000000000000000000FFFF0000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FFFF00000000000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      0000000000000000000000FFFF000000000000000000FFFFFF00FFFF0000FFFF
      0000FFFF0000FFFF0000FFFF0000FFFF00000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      FF000000FF0000000000000000007B7B7B00000000007B7B7B00000000000000
      00000000FF000000FF000000FF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FFFF0000FFFF000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      00000000000000FFFF0000FFFF000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF000000000000FFFF00FFFFFF0000FFFF00FFFF
      FF0000FFFF000000000000000000FFFF00000000000000000000000000000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      FF000000FF000000FF000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF00000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000FFFF0000FF
      FF007B7B7B007B7B7B007B7B7B0000FFFF0000FFFF007B7B7B007B7B7B007B7B
      7B0000FFFF0000FFFF00000000000000000000000000FFFFFF0000000000FFFF
      0000FFFF0000FFFF0000FFFF0000000000000000000000000000FFFFFF0000FF
      FF00FFFFFF0000FFFF0000000000FFFF00000000000000000000000000000000
      00000000FF000000FF000000FF007B7B7B00000000007B7B7B000000FF000000
      FF000000FF00000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FFFF0000000000000000000000000000000000FFFFFF00FFFFFF000000
      000000000000FFFFFF0000000000FFFFFF0000FFFF00FFFFFF0000FFFF00FFFF
      FF0000FFFF00FFFFFF0000000000FFFF00000000000000000000000000000000
      0000000000000000FF000000FF000000FF00000000000000FF000000FF000000
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
      00000000000000000000000000000000000000000000FFFFFF00FFFF00000000
      000000FFFF000000000000000000000000000000000000000000FFFFFF0000FF
      FF00FFFFFF0000FFFF0000000000FFFF00000000000000000000000000000000
      000000000000000000000000FF000000FF00000000000000FF000000FF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000FFFF
      FF000000000000000000FFFFFF00000000000000000000000000FFFFFF000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF0000000000FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFF
      FF0000FFFF00FFFFFF0000000000FFFF00000000000000000000000000000000
      0000000000000000000000000000000084000000000000008400000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF0000FFFF0000000000FFFF
      FF00FFFFFF00FFFFFF00BDBDBD00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000
      000000FFFF0000FFFF0000FFFF000000000000000000FFFFFF00FFFF0000FFFF
      0000FFFF00000000000000000000000000000000000000000000000000000000
      0000FFFFFF0000FFFF0000000000FFFF00000000000000000000000000000000
      000000000000000000000000FF000000840000000000000084000000FF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FF0000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FFFF0000000000FFFF
      FF0000000000BDBDBD007B7B7B00000000000000000000000000000000000000
      000000000000000000000000000000FFFF0000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF000000000000FFFF00000000000000000000FFFF00FFFF
      FF0000FFFF000000000000000000000000000000000000000000000000000000
      0000000000000000FF000000FF000000000000000000000000000000FF000000
      FF0000000000000000000000000000000000000000000000000000000000FF00
      0000FF0000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000BDBD
      BD00BDBDBD00BDBDBD0000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF0000000000000000000000000000000000FFFFFF00FFFF0000FFFF
      0000FFFF0000FFFF0000FFFF00000000000000FFFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000FF000000FF000000FF000000000000000000000000000000FF000000
      FF000000FF0000000000000000000000000000000000FF000000FF000000FF00
      0000FF000000FF000000FF000000FF000000FF000000FF000000FF0000000000
      00000000FF000000FF000000000000000000000000000000000000000000BDBD
      BD00000000007B7B7B00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00BDBD
      BD000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000000000FFFF00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      FF000000FF000000FF00000000000000000000000000FF000000FF000000FF00
      0000FF000000FF000000FF000000FF000000FF000000FF000000FF0000000000
      00000000FF000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FFFF000000000000000000000000000000000000000000FFFFFF000000
      0000FFFFFF0000000000FFFFFF0000000000FFFFFF000000000000FFFF000000
      00000000000000000000000000000000000000000000000000000000FF000000
      FF000000FF0000000000000000007B7B7B00000000007B7B7B00000000000000
      00000000FF000000FF000000FF0000000000000000000000000000000000FF00
      0000FF0000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000FFFF0000FF
      FF0000000000000000000000000000FFFF0000FFFF0000000000000000000000
      000000FFFF0000FFFF00000000000000000000000000000000007B7B7B000000
      00007B7B7B00000000007B7B7B00000000007B7B7B00000000000000000000FF
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FF0000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FFFF0000FFFF000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      00000000000000FFFF0000FFFF000000000000000000000000007B7B7B000000
      00007B7B7B00000000007B7B7B00000000007B7B7B0000000000000000000000
      00000000FF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FFFF00000000000000
      000000000000000000000000000000FFFF0000FFFF0000000000000000000000
      0000000000000000000000FFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FFFF0000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      000000000000000000000000000000FFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000FFFFFF00FFFFFF000000000000000000000000000000
      FF00000084000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FFFF007B7B7B00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      000000000000000000000000000000000000000000007B7B7B00000000000000
      000000000000FFFFFF00FFFFFF00000000000000000000000000000000000000
      FF00000084000000FF0000000000008484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FFFF007B7B7B00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      FF00000000000000000000000000000000007B7B7B0000000000FFFFFF00FFFF
      FF00FFFFFF00FFFFFF0000000000000000000000000000000000000000000000
      FF00000084000000FF0000848400008484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FFFF007B7B7B00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF0000FFFF00000000000000000000000000000000000000
      000000000000000000000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF0000000000000000000000000000000000FFFFFF00000000000000
      0000FFFFFF00FFFFFF0000000000000000000000000000000000000000000000
      FF00000084000000FF0000848400008484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FFFF007B7B7B00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF0000FFFF000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00000000000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      000000000000FFFFFF0000000000000000000000000000000000000000000000
      FF00000084000000FF0000848400000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000007B7B7B007B7B
      7B0000000000000000007B7B7B000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00000000000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000FF000000FF0000000000000000007B7B7B00000000000000
      000000000000FFFFFF00000000000000000000000000000000000000FF000000
      FF000000FF000000FF000000FF000000000000000000FFFFFF00BDBDBD00BDBD
      BD00FFFFFF00FFFFFF00FFFFFF00FFFFFF00BDBDBD00FFFFFF00FFFFFF00FFFF
      FF00BDBDBD00BDBDBD00FFFFFF000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000
      00007B7B7B007B7B7B0000FFFF000000000000000000FFFFFF00000000000000
      0000FFFFFF00000000000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000FF00000000000000000000000000000000007B7B7B000000
      0000FFFFFF00000000007B7B7B00000000000000000000000000000084000000
      84000000840000008400000084000000000000000000FFFFFF00FFFFFF00FFFF
      FF000000FF00FFFFFF00FFFFFF00FFFFFF00BDBDBD00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF007B7B7B000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000
      00007B7B7B0000FFFF0000FFFF000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00000000000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF000000000000000000000000000000000000000000000000000000
      0000000000007B7B7B0000000000000000000000000000848400008484000084
      84000000000000000000000000000000000000000000FFFFFF00FFFFFF000000
      FF000000FF000000FF00FFFFFF00FFFFFF00BDBDBD0000000000000000000000
      00000000000000000000000000000000000000000000FFFFFF00000000000000
      0000FFFFFF00000000000000000000000000FFFFFF0000000000000000000000
      00000000FF0000000000000000007B7B7B0000000000FFFFFF00000000000000
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000000000FF000000
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000084840000848400008484000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF000000FF00FFFFFF00FFFFFF00FFFFFF0000000000BDBDBD00BDBDBD00BDBD
      BD00BDBDBD0000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000
      FF000000FF000000FF00000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00000000000000FF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000008484000084840000848400000000000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000BDBDBD00BDBDBD00BDBD
      BD000000000000000000000000000000000000000000FFFFFF00000000000000
      00000000000000000000FFFFFF0000000000FFFFFF00000000000000FF000000
      FF000000FF000000FF000000FF000000000000000000FFFFFF00000000000000
      0000FFFFFF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000848400008484000084840000000000000000000000
      0000000000000000000000000000000000007B7B7B0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000FF000000FF000000
      FF000000FF000000FF000000FF000000FF0000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF0000000000FFFFFF00FFFFFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000084840000848400008484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF00000000000000FF000000FF000000
      FF00000000000000FF00000000000000000000000000FFFFFF00000000000000
      0000FFFFFF000000000000000000000000000000000000000000000000000000
      FF000000FF000000FF00000000000000000000000000FFFFFF0000000000BDBD
      BD00FFFFFF0000000000FFFFFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000848400000000000000000000000000000000007B7B
      7B00000000007B7B7B0000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF0000000000FFFFFF00FFFFFF000000000000000000000000000000
      FF000000FF000000FF00000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007B7B
      7B00000000007B7B7B0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000FF0000000000000000000000
      00000000FF0000000000000000000000000000000000FFFFFF0000000000BDBD
      BD00FFFFFF0000000000FFFFFF000000000000000000000000007B7B7B000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      00000000000000000000000000007B7B7B000000000000000000000000007B7B
      7B00000000007B7B7B0000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      00000000000000000000000000000000000000000000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF000000000000000000000000000000FF000000FF000000FF000000
      FF000000FF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000C6C6C600C6C6
      C600000000000084840000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000000000008484000084
      8400008484000084840000848400008484000084840000848400008484000000
      0000000000000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000C6C6C600C6C6
      C600000000000084840000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000FFFF00000000000084
      8400008484000084840000848400008484000084840000848400008484000084
      8400000000000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000C6C6C600C6C6
      C600000000000084840000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF000000000000000000FFFFFF000000
      00000000000000000000FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000000000000000000000000000000000FFFFFF0000FFFF000000
      0000008484000084840000848400008484000084840000848400008484000084
      8400008484000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000000000000000
      0000000000000084840000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000FFFF00FFFFFF0000FF
      FF00000000000084840000848400008484000084840000848400008484000084
      8400008484000084840000000000000000000000000000000000008484000084
      8400008484000084840000848400008484000084840000848400008484000084
      8400008484000084840000000000000000000000000000000000000000000000
      FF00000000000000000000000000FFFFFF0000000000BDBDBD00000000000000
      0000FFFFFF0000000000FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000000000000000000000000000000000FFFFFF0000FFFF00FFFF
      FF0000FFFF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000084
      8400000000000000000000000000000000000000000000000000000000000000
      0000008484000084840000000000000000000000000000000000000000000000
      FF000000FF000000000000000000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000FFFF00FFFFFF0000FF
      FF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000008484000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000FFFFFF000000000000000000FFFFFF000000
      000000000000000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF000000000000000000000000000000000000000000FFFFFF0000FFFF00FFFF
      FF0000FFFF00FFFFFF0000FFFF00FFFFFF0000FFFF00FFFFFF00000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000008484000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF0000000000FFFFFF00FFFFFF00FFFFFF000000
      0000FFFFFF00FFFFFF000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00000000000000000000000000000000000000000000FFFF00FFFFFF0000FF
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000008484000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF000000FF0000000000BDBDBD00FFFFFF000000
      0000FFFFFF00000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000008484000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF000000FF0000000000FFFFFF00FFFFFF00FFFFFF000000
      000000000000000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000FFFFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000FF0000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008484000000
      0000C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6C600C6C6
      C60000000000C6C6C60000000000000000000000000000000000000000000000
      FF000000FF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000500000000100010000000000800200000000000000000000
      000000000000000000000000FFFFFF00FC1FFFFFF8000000F0070007F8000000
      E003000720000000C001000700000000C001000700000000C001000700000000
      C001000F00000000C001FFFF00000000E0033F0100000000F1C73E0000000000
      F1C73600E0000000F1C71200F8000000F0070000F8000000F80FF200F8010000
      FC1FF601F8030000FFFFFF1FF8070000E00F847F8000FFFFE00F00EF0000001F
      E00F31BFE01C000FE00F39FFE01F0007E00F993FE01F0003E00FCA1FE01F0001
      E00FF40FE01F0000A00B9C07E01F0000C0079603E01F0000E00FCB01E01F0000
      E00FFF80E01F0000C007F7C0E01F8000C007FFE0FFFFC000C007EFF0F83FE000
      F83FFFF8F83FF000F83FFFFCF83FFFFF803FFFFFFFFFFF7E001FFFFFFFF8BE7D
      0004C631FFF89E790000E22381FFC0030000F00781FCC0070000F88FFFFCC00F
      0000FC1FFFFFC00F0000FE3FFFFC00010000FC1FF7FC80000000F80FE7FFC003
      0007F0078013C007001FE2238013E007000FC631E7FFCE738007FFFFF7F89E79
      8023FFFFFFF8BE7D5577FFFFFFFF7EFEFFDFF862FFFFFC00FFCF80E0FFFFFC00
      FFC701E0CFF3FC00000301E087E1FC00000131E100000000000031C100000000
      0001C181000000000003C307000100000007FE1700030023000FCC3700070001
      001FA877000F0000007F40F7FE8B002300FF01E3FFDF006301FFC1E3FF7700C3
      03FFC0E3FFDF0107FFFFC83FFFFF03FFFFFFFFFFFFFFFFFFFFFFFFFFC001FC00
      C007001F8001FC00C007000F8001FC00C00700078001FC00C00700038001EC00
      C00700018001E400C00700008001E000C007001F80010000C007001F80010001
      C007001F80010003C0078FF180010007C00FFFF98001000FC01FFF758001E3FF
      C03FFF8F8001E7FFFFFFFFFFFFFFEFFF00000000000000000000000000000000
      000000000000}
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.edb'
    Filter = 'EasyTable database files(*.edb)|*.edb|Any file (*.*)|*.*'
    Left = 528
    Top = 376
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.edb'
    Filter = 'EasyTable database files(*.edb)|*.edb|Any file (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 560
    Top = 376
  end
  object MainMenu1: TMainMenu
    Images = ImageList1
    Left = 432
    Top = 376
    object File1: TMenuItem
      Caption = '&Database'
      object FileNewItem: TMenuItem
        Caption = '&New database'
        Hint = 'Create a new database'
        ImageIndex = 0
        OnClick = FileNewExecute
      end
      object FileOpenItem: TMenuItem
        Caption = '&Open database'
        Hint = 'Open existing database'
        ImageIndex = 1
        OnClick = FileOpenExecute
      end
      object ReopenDatabaseItem: TMenuItem
        Caption = 'Reopen database'
        ImageIndex = 17
      end
      object Changedatabaseencryption1: TMenuItem
        Action = FileChangeEncryption
      end
      object Repairdatabase1: TMenuItem
        Action = FileRepair
      end
      object Compactdatabase1: TMenuItem
        Action = FileCompact
      end
      object Renametables2: TMenuItem
        Action = FileRename
      end
      object Deletetables2: TMenuItem
        Action = FileDelete
      end
      object FilePrintStructure1: TMenuItem
        Action = FilePrintStructure
      end
      object Close1: TMenuItem
        Action = FileClose
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object FileExitItem: TMenuItem
        Caption = 'E&xit'
        Hint = 'Exit TET manager'
        ShortCut = 49240
        OnClick = FileExitItemClick
      end
    end
    object ToolsMenu: TMenuItem
      Caption = '&Table'
      object Createtable1: TMenuItem
        Caption = '&New table'
        Enabled = False
        Hint = 'Create new table in current database'
        ImageIndex = 0
        ShortCut = 16462
        OnClick = acCreateTableExecute
      end
      object Opentable1: TMenuItem
        Caption = '&Open table'
        Enabled = False
        Hint = 'Open table from current database'
        ImageIndex = 1
        ShortCut = 16463
        OnClick = acOpenTableExecute
      end
      object Restructuretable1: TMenuItem
        Caption = 'Re&structure'
        Enabled = False
        Hint = 'Restructure | Restructure table'
        ImageIndex = 5
        ShortCut = 16467
        OnClick = acRestructureTableExecute
      end
      object Changepassword1: TMenuItem
        Caption = '&Change password'
        Enabled = False
        ImageIndex = 16
        OnClick = acChangePasswordOfTableExecute
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Repairtable1: TMenuItem
        Caption = '&Repair tables'
        Enabled = False
        Hint = 'Repair | Repair selected tables'
        ImageIndex = 6
        ShortCut = 16466
        OnClick = acRepairTableExecute
      end
      object Renametables1: TMenuItem
        Caption = 'R&ename tables'
        Enabled = False
        Hint = 'Rename selected tables'
        ImageIndex = 8
        ShortCut = 16461
        OnClick = acRenameTableExecute
      end
      object Copytables1: TMenuItem
        Caption = 'Co&py tables'
        Enabled = False
        Hint = 'Copy selected tables'
        ImageIndex = 7
        ShortCut = 16464
        OnClick = acCopyTableExecute
      end
      object Exporttables1: TMenuItem
        Caption = 'E&mpty tables'
        Enabled = False
        Hint = 'Empty selected table'
        ImageIndex = 13
        ShortCut = 16453
        OnClick = acEmptyTableExecute
      end
      object Deletetables1: TMenuItem
        Caption = '&Delete tables'
        Enabled = False
        Hint = 'Delete selected tables'
        ImageIndex = 12
        ShortCut = 16452
        OnClick = acDeleteTableExecute
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Closetable1: TMenuItem
        Caption = '&Close table'
        Enabled = False
        Hint = 'Close table'
        ImageIndex = 14
        ShortCut = 16471
        OnClick = acCloseTableExecute
      end
    end
    object SQL1: TMenuItem
      Caption = 'SQL'
      object OpenSQLQuery1: TMenuItem
        Caption = '&Open SQL Query'
        OnClick = OpenQuery1Click
      end
      object ExecuteSQLScript1: TMenuItem
        Caption = '&Execute SQL Script'
        OnClick = ExecuteSQLscript1Click
      end
      object EditSQLScript1: TMenuItem
        Caption = '&Edit SQL Script'
        OnClick = EditSQLScript1Click
      end
      object LoadSQLScript1: TMenuItem
        Caption = '&Load SQL Script'
        OnClick = LoadSQLscript1Click
      end
      object SaveSQLScript1: TMenuItem
        Caption = '&Save SQL Script'
        OnClick = SaveSQLScript1Click
      end
      object miSQLSyntax: TMenuItem
        Caption = 'Disable Syntax Highliting'
        OnClick = miSQLSyntaxClick
      end
    end
    object pmActions: TMenuItem
      Caption = '&Actions'
      object Gotorecord1: TMenuItem
        Action = acRecNo
      end
      object Filterexpression1: TMenuItem
        Action = acFilter
      end
      object Findrecord1: TMenuItem
        Action = acFind
      end
      object Locate1: TMenuItem
        Action = acLocate
      end
      object Selectindex1: TMenuItem
        Action = acUseIndex
      end
      object Findkey1: TMenuItem
        Action = acFindKey
      end
      object Setrange1: TMenuItem
        Action = acSetRange
      end
      object Addrecords1: TMenuItem
        Action = acAddRecords
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      Hint = 'Help topics'
      object HelpAboutItem: TMenuItem
        Caption = '&About...'
        Hint = 
          'About|Displays program information, version number, and copyrigh' +
          't'
        OnClick = HelpAboutItemClick
      end
    end
  end
  object IndexesTable: TEasyTable
    CurrentVersion = '21.00 '
    TableName = 'Indexes'
    DatabaseName = 'MEMORY'
    InMemory = True
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    BeforePost = IndexesTableBeforePost
    AfterPost = IndexesTableAfterPost
    AfterScroll = IndexesTableAfterScroll
    OnNewRecord = IndexesTableNewRecord
    Left = 458
    Top = 4
  end
  object IndexDataSource: TDataSource
    DataSet = IndexesTable
    Left = 576
    Top = 238
  end
  object FieldsDataSource: TDataSource
    DataSet = FieldsTable
    Left = 544
    Top = 238
  end
  object CurrentTable: TEasyTable
    CurrentVersion = '21.00 '
    TableName = 'test_backup_backup'
    DatabaseName = 'CurrentDB'
    BLOBBlockSize = 100
    InMemory = False
    OnProgress = CurrentTableProgress
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    AfterInsert = CurrentTableAfterScroll
    AfterPost = CurrentTableAfterScroll
    AfterScroll = CurrentTableAfterScroll
    Left = 522
    Top = 4
  end
  object CurrentDataSource: TDataSource
    DataSet = CurrentTable
    Left = 544
    Top = 270
  end
  object DialogsTable: TEasyTable
    CurrentVersion = '21.00 '
    TableName = 'Dialogs'
    DatabaseName = 'MEMORY'
    BLOBBlockSize = 100
    InMemory = True
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Left = 490
    Top = 4
  end
  object DialogDataSource: TDataSource
    DataSet = DialogsTable
    Left = 509
    Top = 269
  end
  object FieldsTable: TEasyTable
    CurrentVersion = '21.00 '
    TableName = 'Fields'
    DatabaseName = 'MEMORY'
    BLOBCompression = clFastest
    InMemory = True
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    BeforePost = FieldsTableBeforePost
    AfterPost = FieldsTableAfterPost
    AfterScroll = FieldsTableAfterScroll
    OnNewRecord = FieldsTableNewRecord
    Left = 426
    Top = 4
  end
  object BDEDataSource: TDataSource
    Left = 512
    Top = 238
  end
  object CurrentDB: TEasyDatabase
    DatabaseFileName = 'E:\test.edb'
    DatabaseName = 'CurrentDB'
    InMemory = False
    OnProgress = CurrentDBProgress
    SessionName = 'Default'
    Left = 554
    Top = 4
  end
  object CurrentQuery: TEasyQuery
    RequestLive = False
    CurrentVersion = '21.00 '
    DatabaseName = 'CurrentDB'
    InMemory = False
    BDELikeFilter = False
    AfterPost = CurrentTableAfterScroll
    AfterScroll = CurrentTableAfterScroll
    Left = 632
    Top = 8
  end
  object PopupMenuSQL: TPopupMenu
    OnPopup = PopupSQLMenuPopup
    Left = 272
    Top = 360
    object Undo1: TMenuItem
      Tag = 1
      Caption = 'Undo'
      OnClick = PopupSQLMenuClick
    end
    object Clear1: TMenuItem
      Tag = 12
      Caption = 'Clear'
      ShortCut = 119
      OnClick = PopupSQLMenuClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Cut1: TMenuItem
      Tag = 2
      Caption = 'Cut'
      OnClick = PopupSQLMenuClick
    end
    object Copy1: TMenuItem
      Tag = 3
      Caption = 'Copy'
      OnClick = PopupSQLMenuClick
    end
    object Paste1: TMenuItem
      Tag = 4
      Caption = 'Paste'
      OnClick = PopupSQLMenuClick
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object SelectAll1: TMenuItem
      Tag = 5
      Caption = 'Select All'
      ShortCut = 116
      OnClick = PopupSQLMenuClick
    end
    object N6: TMenuItem
      Caption = '-'
    end
    object SaveAs1: TMenuItem
      Tag = 6
      Caption = '&Save as'
      OnClick = PopupSQLMenuClick
    end
    object Load1: TMenuItem
      Tag = 7
      Caption = '&Load'
      OnClick = PopupSQLMenuClick
    end
    object N7: TMenuItem
      Caption = '-'
    end
    object PriorSQL: TMenuItem
      Tag = 9
      Caption = 'Prior SQL'
      ShortCut = 113
      OnClick = PopupSQLMenuClick
    end
    object NextSQL: TMenuItem
      Tag = 10
      Caption = 'Next SQL'
      ShortCut = 114
      OnClick = PopupSQLMenuClick
    end
    object N9: TMenuItem
      Caption = '-'
    end
    object HistoryClear: TMenuItem
      Tag = 13
      Caption = 'History Clear'
      OnClick = PopupSQLMenuClick
    end
    object HistorySave: TMenuItem
      Tag = 14
      Caption = 'History Save'
      OnClick = PopupSQLMenuClick
    end
    object N8: TMenuItem
      Caption = '-'
    end
    object OpenQuery2: TMenuItem
      Tag = 11
      Caption = 'Open Query'
      ShortCut = 120
      OnClick = PopupSQLMenuClick
    end
    object ExecSQL1: TMenuItem
      Tag = 8
      Caption = 'Exec SQL'
      ShortCut = 121
      OnClick = PopupSQLMenuClick
    end
  end
  object odLoadSQL: TOpenDialog
    DefaultExt = '.SQL'
    Filter = 
      'SQL Scripts (*.sql)|*.SQL|Text Files (*.*)|*.TXT|Any Files (*.*)' +
      '|*.*'
    FilterIndex = 0
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Load SQL Script'
    Left = 610
    Top = 366
  end
  object sdSaveSQL: TSaveDialog
    DefaultExt = '.SQL'
    Filter = 
      'SQL Scripts (*.sql)|*.SQL|Text Files (*.*)|*.TXT|Any Files (*.*)' +
      '|*.*'
    FilterIndex = 0
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Save SQL Script'
    Left = 658
    Top = 366
  end
  object ActionList: TActionList
    Images = ImageList1
    Left = 464
    Top = 376
    object acFilter: TAction
      Category = 'Actions'
      Caption = 'Fi&lter expression'
      Enabled = False
      Hint = 'Set / Clear Filter expression for current table'
      ShortCut = 16460
      OnExecute = acFilterExecute
    end
    object acRestructureTable: TAction
      Category = 'Table'
      Caption = 'Re&structure'
      Enabled = False
      Hint = 'Restructure | Restructure table'
      ImageIndex = 5
      ShortCut = 16467
      OnExecute = acRestructureTableExecute
    end
    object acSetRange: TAction
      Category = 'Actions'
      Caption = '&Set range'
      Enabled = False
      Hint = 'Set range in current table'
      ShortCut = 16449
      OnExecute = acSetRangeExecute
    end
    object acFindKey: TAction
      Category = 'Actions'
      Caption = 'Find ke&y'
      Enabled = False
      Hint = 'Find record using current index'
      ShortCut = 16473
      OnExecute = acFindKeyExecute
    end
    object FileNew: TAction
      Category = 'Database'
      Caption = '&New database'
      Hint = 'Create a new database'
      ImageIndex = 0
      OnExecute = FileNewExecute
    end
    object FileOpen: TAction
      Category = 'Database'
      Caption = '&Open database'
      Hint = 'Open existing database'
      ImageIndex = 1
      OnExecute = FileOpenExecute
    end
    object FileRename: TAction
      Category = 'Database'
      Caption = '&Rename database'
      Enabled = False
      Hint = 'Rename current database'
      ImageIndex = 8
      OnExecute = FileRenameExecute
    end
    object FileDelete: TAction
      Category = 'Database'
      Caption = '&Delete database'
      Enabled = False
      Hint = 'Delete current database'
      ImageIndex = 12
      OnExecute = FileDeleteExecute
    end
    object FileExit: TAction
      Category = 'Database'
      Caption = 'E&xit'
      Hint = 'Exit TET manager'
      ShortCut = 49240
      OnExecute = FileExitItemClick
    end
    object HelpAbout1: TAction
      Category = 'Help'
      Caption = '&About...'
      Hint = 
        'About|Displays program information, version number, and copyrigh' +
        't'
      OnExecute = HelpAboutItemClick
    end
    object FileClose: TAction
      Category = 'Database'
      Caption = '&Close database'
      Enabled = False
      Hint = 'Close current database'
      ImageIndex = 14
      OnExecute = FileCloseExecute
    end
    object acRepairTable: TAction
      Category = 'Table'
      Caption = '&Repair tables'
      Enabled = False
      Hint = 'Repair | Repair selected tables'
      ImageIndex = 6
      ShortCut = 16466
      OnExecute = acRepairTableExecute
    end
    object acDeleteTable: TAction
      Category = 'Table'
      Caption = '&Delete tables'
      Enabled = False
      Hint = 'Delete selected tables'
      ImageIndex = 12
      ShortCut = 16452
      OnExecute = acDeleteTableExecute
    end
    object acCloseTable: TAction
      Category = 'Table'
      Caption = '&Close table'
      Enabled = False
      Hint = 'Close table'
      ImageIndex = 14
      ShortCut = 16471
      OnExecute = acCloseTableExecute
    end
    object acCreateTable: TAction
      Category = 'Table'
      Caption = '&New table'
      Enabled = False
      Hint = 'Create new table in current database'
      ImageIndex = 0
      ShortCut = 16462
      OnExecute = acCreateTableExecute
    end
    object acOpenTable: TAction
      Category = 'Table'
      Caption = '&Open table'
      Enabled = False
      Hint = 'Open table from current database'
      ImageIndex = 1
      ShortCut = 16463
      OnExecute = acOpenTableExecute
    end
    object FileRepair: TAction
      Category = 'Database'
      Caption = '&Repair database'
      Enabled = False
      Hint = 'Repair current database'
      ImageIndex = 6
      OnExecute = FileRepairExecute
    end
    object acRenameTable: TAction
      Category = 'Table'
      Caption = 'R&ename tables'
      Enabled = False
      Hint = 'Rename selected tables'
      ImageIndex = 8
      ShortCut = 16461
      OnExecute = acRenameTableExecute
    end
    object acCopyTable: TAction
      Category = 'Table'
      Caption = 'Co&py tables'
      Enabled = False
      Hint = 'Copy selected tables'
      ImageIndex = 7
      ShortCut = 16464
      OnExecute = acCopyTableExecute
    end
    object acEmptyTable: TAction
      Category = 'Table'
      Caption = 'E&mpty tables'
      Enabled = False
      Hint = 'Empty selected table'
      ImageIndex = 13
      ShortCut = 16453
      OnExecute = acEmptyTableExecute
    end
    object acUseIndex: TAction
      Category = 'Actions'
      Caption = 'Select &index'
      Enabled = False
      Hint = 'Select current index to order table'
      ShortCut = 16469
      OnExecute = acUseIndexExecute
    end
    object acFind: TAction
      Category = 'Actions'
      Caption = '&Find record'
      Enabled = False
      Hint = 'Find record in current table'
      ShortCut = 16454
      OnExecute = acFindExecute
    end
    object acRecNo: TAction
      Category = 'Actions'
      Caption = '&Go to record'
      Enabled = False
      Hint = 'Go to record'
      ShortCut = 16455
      OnExecute = acRecNoExecute
    end
    object acLocate: TAction
      Category = 'Actions'
      Caption = 'Loca&te'
      Enabled = False
      Hint = 'Locate record using field values'
      ShortCut = 16468
      OnExecute = acLocateExecute
    end
    object FileCompact: TAction
      Category = 'Database'
      Caption = '&Compact database'
      Enabled = False
      Hint = 'Compact current database'
      ImageIndex = 15
      OnExecute = FileCompactExecute
    end
    object acChangePasswordOfTable: TAction
      Category = 'Table'
      Caption = '&Change password'
      Enabled = False
      ImageIndex = 16
      OnExecute = acChangePasswordOfTableExecute
    end
    object FileCopy: TAction
      Category = 'Database'
      Caption = 'Cop&y database'
      Enabled = False
      Hint = 'Copy current database'
      ImageIndex = 7
    end
    object FileChangeEncryption: TAction
      Category = 'Database'
      Caption = 'Change database &encryption'
      Enabled = False
      ImageIndex = 16
      OnExecute = FileChangeEncryptionExecute
    end
    object acAddRecords: TAction
      Category = 'Actions'
      Caption = '&Add records'
      Enabled = False
      OnExecute = acAddRecordsExecute
    end
    object FilePrintStructure: TAction
      Category = 'Database'
      Caption = 'FilePrintStructure'
      Enabled = False
      Hint = 'Document data structures'
      OnExecute = FilePrintStructureExecute
    end
    object acSwitchPans: TAction
      Caption = 'acSwitchPans'
      ShortCut = 8315
      OnExecute = acSwitchPansExecute
    end
  end
end
