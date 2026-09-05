object frmMain: TfrmMain
  Left = 44
  Top = 36
  Width = 688
  Height = 499
  Caption = 'SFSExplorer'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 305
    Top = 0
    Width = 3
    Height = 472
    Cursor = crHSplit
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 305
    Height = 472
    Align = alLeft
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 49
      Height = 13
      Caption = 'Password:'
    end
    object btOpen: TButton
      Left = 152
      Top = 18
      Width = 57
      Height = 25
      Caption = 'Open'
      TabOrder = 0
      OnClick = btOpenClick
    end
    object GroupBox1: TGroupBox
      Left = 8
      Top = 64
      Width = 281
      Height = 217
      Caption = 'Pages: '
      TabOrder = 1
      object lbPages: TListBox
        Left = 8
        Top = 24
        Width = 121
        Height = 121
        ItemHeight = 13
        TabOrder = 0
        OnClick = lbPagesClick
      end
      object btSavePage: TButton
        Left = 12
        Top = 183
        Width = 75
        Height = 25
        Caption = 'Save page'
        TabOrder = 1
        OnClick = btSavePageClick
      end
      object GroupBox2: TGroupBox
        Left = 140
        Top = 19
        Width = 130
        Height = 126
        Caption = 'Page info: '
        TabOrder = 2
        object Label2: TLabel
          Left = 10
          Top = 22
          Width = 64
          Height = 13
          Caption = 'NextPageNo:'
        end
        object Label3: TLabel
          Left = 10
          Top = 44
          Width = 52
          Height = 13
          Caption = 'PageType:'
        end
        object Label4: TLabel
          Left = 10
          Top = 66
          Width = 46
          Height = 13
          Caption = 'EncType:'
        end
        object lbNextPageNo: TLabel
          Left = 76
          Top = 22
          Width = 6
          Height = 13
          Caption = '0'
        end
        object lbPageType: TLabel
          Left = 76
          Top = 45
          Width = 6
          Height = 13
          Caption = '0'
        end
        object lbEncType: TLabel
          Left = 76
          Top = 68
          Width = 6
          Height = 13
          Caption = '0'
        end
      end
      object cbDecrypt: TCheckBox
        Left = 13
        Top = 160
        Width = 97
        Height = 17
        Caption = 'Decrypt page'
        TabOrder = 3
      end
    end
    object edPass: TEdit
      Left = 72
      Top = 20
      Width = 73
      Height = 21
      TabOrder = 2
      Text = '1'
    end
    object btRefresh: TButton
      Left = 224
      Top = 18
      Width = 57
      Height = 25
      Caption = 'Refresh'
      TabOrder = 3
      OnClick = btRefreshClick
    end
    object GroupBox3: TGroupBox
      Left = 8
      Top = 288
      Width = 281
      Height = 169
      Caption = 'Directory: '
      TabOrder = 4
      object lbDirectory: TListBox
        Left = 8
        Top = 24
        Width = 121
        Height = 121
        ItemHeight = 13
        TabOrder = 0
        OnClick = lbDirectoryClick
      end
      object GroupBox4: TGroupBox
        Left = 140
        Top = 19
        Width = 130
        Height = 129
        Caption = 'DirItem info: '
        TabOrder = 1
        object Label5: TLabel
          Left = 10
          Top = 22
          Width = 82
          Height = 13
          Caption = 'FirstMapPageNo:'
        end
        object lbFirstMapPageNo: TLabel
          Left = 98
          Top = 22
          Width = 6
          Height = 13
          Caption = '0'
        end
      end
    end
  end
  object Panel1: TPanel
    Left = 308
    Top = 0
    Width = 372
    Height = 472
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object memHex: TMemo
      Left = 0
      Top = 0
      Width = 372
      Height = 472
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 384
    Top = 24
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.dat'
    Left = 416
    Top = 24
  end
end
