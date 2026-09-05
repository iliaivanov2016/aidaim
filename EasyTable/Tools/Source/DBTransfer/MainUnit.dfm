object MainForm: TMainForm
  Left = 173
  Top = 102
  ActiveControl = btnNext
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  ClientHeight = 362
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000000000000000000000000000000000000000007777770000000000000000
    0000000000000007000000000000000000000000000000070000000000000000
    0000000000777007000000000000000000077070007770070000700000000000
    0077000700787000000007000000000007708000077877000070007000000000
    07088807777777770777000700000000008F88877FFFFF077887700700000000
    00088888F88888FF08870070000000000000880888877778F070007000000007
    77088888880007778F770077777000700008F088007777077F07000000700700
    008F08880800077778F7700000700708888F0880F08F807078F7777700700708
    F88F0780F070F07078F7887700700708888F0780F077807088F7777700700700
    008F0788FF00080888F77000007000000008F0780FFFF0088F77007000000000
    0008F07788000888887700700000000000008F07788888880870007000000000
    00088FF0077788088887000700000000008F888FF00000F87887700700000000
    0708F8088FFFFF88078700700000000007708000088888000070070000000000
    0077007000888007000070000000000000077700008F80070007000000000000
    0000000000888007000000000000000000000000000000070000000000000000
    000000000777777700000000000000000000000000000000000000000000FFFF
    FFFFFFFC0FFFFFFC0FFFFFF80FFFFFF80FFFFE180E7FFC00043FF800001FF800
    000FF800000FFC00001FFE00001FE0000001C000000180000001800000018000
    00018000000180000001FC00001FFC00001FFE00001FFC00000FF800000FF800
    001FF800003FFC180C7FFE380EFFFFF80FFFFFF80FFFFFF80FFFFFFFFFFF}
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 312
    Width = 527
    Height = 3
    Align = alTop
    Shape = bsBottomLine
  end
  object btnCancel: TButton
    Left = 415
    Top = 329
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    TabOrder = 0
    OnClick = btnCancelClick
  end
  object btnPrev: TButton
    Left = 251
    Top = 329
    Width = 75
    Height = 25
    Caption = '< &Back'
    TabOrder = 1
    OnClick = btnPrevClick
  end
  object btnNext: TButton
    Left = 327
    Top = 329
    Width = 75
    Height = 25
    Caption = '&Next >'
    Default = True
    TabOrder = 2
    OnClick = btnNextClick
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 527
    Height = 312
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object Notebook1: TNotebook
      Left = 0
      Top = 0
      Width = 527
      Height = 312
      Align = alClient
      PageIndex = 1
      TabOrder = 0
      object TPage
        Left = 0
        Top = 0
        Caption = 'Welcome'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label12: TLabel
          Left = 91
          Top = 129
          Width = 121
          Height = 13
          Caption = 'Feel free to contact us at:'
        end
        object Label13: TLabel
          Left = 248
          Top = 129
          Width = 31
          Height = 13
          Caption = 'E-mail:'
        end
        object hyperlink: TLabel
          Left = 297
          Top = 129
          Width = 99
          Height = 13
          Cursor = crHandPoint
          Alignment = taCenter
          BiDiMode = bdLeftToRight
          Caption = 'support@aidaim.com'
          Color = clBtnFace
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsUnderline]
          ParentBiDiMode = False
          ParentColor = False
          ParentFont = False
          OnMouseDown = hyperlinkMouseDown
          IsControl = True
        end
        object Label14: TLabel
          Left = 246
          Top = 147
          Width = 45
          Height = 13
          Caption = 'Web site:'
        end
        object AidAimHLink: TLabel
          Left = 297
          Top = 147
          Width = 80
          Height = 13
          Cursor = crHandPoint
          Caption = 'www.aidaim.com'
          Color = clBtnFace
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlue
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsUnderline]
          ParentColor = False
          ParentFont = False
          OnMouseDown = AidAimHLinkMouseDown
          IsControl = True
        end
        object Label7: TLabel
          Left = 91
          Top = 31
          Width = 332
          Height = 59
          AutoSize = False
          Caption = 
            'DBTransfer makes it easy to import and export heterogenous data.' +
            ' This wizard guides you through the steps to import or export da' +
            'ta between many popular formats supported by BDE and EasyTable 3' +
            '.0 database files (*.edb).'
          WordWrap = True
        end
        object Label9: TLabel
          Left = 91
          Top = 94
          Width = 291
          Height = 13
          Caption = 'DBTransfer supports both alias and directories for BDE tables.'
        end
        object Label8: TLabel
          Left = 91
          Top = 179
          Width = 177
          Height = 13
          Caption = 'Please, choose an action to proceed.'
        end
        object rgAction: TRadioGroup
          Left = 91
          Top = 203
          Width = 321
          Height = 73
          Caption = ' Actions: '
          ItemIndex = 0
          Items.Strings = (
            'Import tables from BDE'
            'Export tables to BDE')
          TabOrder = 0
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Select BDE source'
        object Label2: TLabel
          Left = 16
          Top = 16
          Width = 203
          Height = 13
          Caption = 'Choose import option and select the tables:'
        end
        object Label3: TLabel
          Left = 337
          Top = 48
          Width = 73
          Height = 13
          Caption = 'Selected tables'
        end
        object rbAlias: TRadioButton
          Left = 16
          Top = 48
          Width = 113
          Height = 17
          Caption = 'Import from alias'
          TabOrder = 0
          OnClick = rbAliasClick
        end
        object rbDir: TRadioButton
          Left = 172
          Top = 48
          Width = 125
          Height = 17
          Caption = 'Import from directory'
          Checked = True
          TabOrder = 1
          TabStop = True
          OnClick = rbDirClick
        end
        object BDESourceAlias: TListBox
          Left = 12
          Top = 80
          Width = 145
          Height = 217
          Enabled = False
          ItemHeight = 13
          Sorted = True
          TabOrder = 2
          OnClick = BDESourceAliasClick
        end
        object BDESourceDrive: TDriveComboBox
          Left = 172
          Top = 80
          Width = 145
          Height = 19
          DirList = BDESourceDir
          TabOrder = 3
        end
        object BDESourceDir: TDirectoryListBox
          Left = 172
          Top = 105
          Width = 145
          Height = 193
          TabOrder = 4
          OnChange = BDESourceDirChange
        end
        object BDESourceTables: TListBox
          Left = 336
          Top = 80
          Width = 145
          Height = 220
          ItemHeight = 13
          MultiSelect = True
          Sorted = True
          TabOrder = 5
          OnClick = BDESourceTablesClick
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Select TET Dest'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label4: TLabel
          Left = 19
          Top = 16
          Width = 321
          Height = 13
          Caption = 
            'Choose a destination database: an existing EasyTable database fi' +
            'le.'
        end
        object DriveComboBox1: TDriveComboBox
          Left = 19
          Top = 54
          Width = 153
          Height = 19
          DirList = DirectoryListBox1
          TabOrder = 0
        end
        object DirectoryListBox1: TDirectoryListBox
          Left = 19
          Top = 79
          Width = 153
          Height = 210
          FileList = TETDest
          TabOrder = 1
          OnChange = DirectoryListBox1Change
        end
        object TETDest: TFileListBox
          Left = 200
          Top = 54
          Width = 265
          Height = 235
          ItemHeight = 13
          Mask = '*.edb'
          TabOrder = 2
          OnChange = TETDestChange
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Import and Export'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label10: TLabel
          Left = 8
          Top = 16
          Width = 205
          Height = 13
          Caption = 'Click on Start button to begin data transfer. '
        end
        object Label11: TLabel
          Left = 137
          Top = 240
          Width = 371
          Height = 31
          AutoSize = False
          Caption = 
            'Auto-indexes slow down transfer process, but you will not have t' +
            'o create indexes manually for each field.'
          WordWrap = True
        end
        object ImportLog: TMemo
          Left = 0
          Top = 48
          Width = 521
          Height = 185
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object Button1: TButton
          Left = 15
          Top = 272
          Width = 75
          Height = 25
          Caption = 'Start'
          TabOrder = 1
          OnClick = Button1Click
        end
        object Button2: TButton
          Left = 427
          Top = 273
          Width = 75
          Height = 25
          Caption = 'Save log'
          TabOrder = 2
          OnClick = Button2Click
        end
        object cbAutoIndexes: TCheckBox
          Left = 14
          Top = 244
          Width = 123
          Height = 17
          Caption = 'Create AutoIndexes'
          TabOrder = 3
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Select BDE dest'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label5: TLabel
          Left = 335
          Top = 25
          Width = 73
          Height = 13
          Caption = 'Selected tables'
        end
        object Label6: TLabel
          Left = 16
          Top = 16
          Width = 300
          Height = 13
          Caption = 'Select tables for exporting to BDE from an EasyTable database.'
        end
        object TETSourceTables: TListBox
          Left = 334
          Top = 44
          Width = 142
          Height = 255
          ItemHeight = 13
          MultiSelect = True
          Sorted = True
          TabOrder = 0
          OnClick = TETSourceTablesClick
        end
        object TETSourceDir: TDirectoryListBox
          Left = 17
          Top = 69
          Width = 138
          Height = 230
          FileList = TETSource
          TabOrder = 1
          OnChange = TETSourceDirChange
        end
        object TETSourceDrive: TDriveComboBox
          Left = 17
          Top = 44
          Width = 138
          Height = 19
          DirList = TETSourceDir
          TabOrder = 2
        end
        object TETSource: TFileListBox
          Left = 172
          Top = 44
          Width = 138
          Height = 255
          ItemHeight = 13
          Mask = '*.edb'
          TabOrder = 3
          OnChange = TETSourceChange
        end
      end
      object TPage
        Left = 0
        Top = 0
        Caption = 'Select TET source'
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Label1: TLabel
          Left = 16
          Top = 14
          Width = 343
          Height = 13
          Caption = 
            'Choose export option: the destination where you want to export t' +
            'ables to.'
        end
        object rbDestDir: TRadioButton
          Left = 231
          Top = 42
          Width = 113
          Height = 16
          Caption = 'Export to directory'
          Checked = True
          TabOrder = 0
          TabStop = True
          OnClick = rbDestDirClick
        end
        object rbDestAlias: TRadioButton
          Left = 17
          Top = 41
          Width = 113
          Height = 17
          Caption = 'Export to alias'
          TabOrder = 1
          OnClick = rbDestAliasClick
        end
        object BDEDestAlias: TListBox
          Left = 17
          Top = 69
          Width = 153
          Height = 220
          Enabled = False
          ItemHeight = 13
          Sorted = True
          TabOrder = 2
          OnClick = BDEDestAliasClick
        end
        object BDEDestDrive: TDriveComboBox
          Left = 231
          Top = 69
          Width = 153
          Height = 19
          DirList = BDEDestDir
          TabOrder = 3
        end
        object BDEDestDir: TDirectoryListBox
          Left = 231
          Top = 94
          Width = 153
          Height = 195
          TabOrder = 4
          OnChange = BDEDestDirChange
        end
      end
    end
  end
  object TETtable: TEasyTable
    CurrentVersion = '16.00 '
    DatabaseName = 'EasyDB'
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Left = 56
    Top = 328
  end
  object dsTET: TDataSource
    DataSet = TETtable
    Left = 16
    Top = 328
  end
  object dsBDE: TDataSource
    DataSet = BDETable
    Left = 56
    Top = 304
  end
  object EasyDB: TEasyDatabase
    DatabaseName = 'EasyDB'
    InMemory = False
    SessionName = 'Default'
    Left = 96
    Top = 328
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.txt'
    FileName = 'Log.txt'
    Filter = 'Text file (*.txt) |*.txt| Any file (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofNoReadOnlyReturn, ofEnableSizing]
    Title = 'Save log to text file'
    Left = 96
    Top = 304
  end
  object BDETable: TTable
    Left = 16
    Top = 296
  end
end
