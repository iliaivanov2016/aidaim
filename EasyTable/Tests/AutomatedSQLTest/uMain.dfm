object fmMain: TfmMain
  Left = 60
  Top = 113
  Width = 945
  Height = 577
  Caption = 'Automated SQL Test. (c) AidAim Software, 2000-2004.'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 498
    Width = 937
    Height = 52
    Align = alBottom
    TabOrder = 0
    object bnClose: TBitBtn
      Left = 326
      Top = 16
      Width = 65
      Height = 25
      Caption = '&Exit'
      TabOrder = 0
      OnClick = bnCloseClick
      Kind = bkClose
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 937
    Height = 498
    Align = alClient
    TabOrder = 1
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 935
      Height = 496
      ActivePage = TabSheet2
      Align = alClient
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Log'
        object Splitter2: TSplitter
          Left = 417
          Top = 0
          Height = 468
        end
        object ErrorLog: TMemo
          Left = 420
          Top = 0
          Width = 507
          Height = 468
          Align = alClient
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object Log: TMemo
          Left = 0
          Top = 0
          Width = 417
          Height = 468
          Align = alLeft
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Results'
        ImageIndex = 1
        object Splitter1: TSplitter
          Left = 0
          Top = 164
          Width = 927
          Height = 3
          Cursor = crVSplit
          Align = alTop
        end
        object gbBDE: TGroupBox
          Left = 0
          Top = 167
          Width = 927
          Height = 301
          Align = alClient
          TabOrder = 0
          object DBGrid2: TDBGrid
            Left = 2
            Top = 15
            Width = 711
            Height = 284
            DataSource = dsTest
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBMemoTest2: TDBMemo
            Left = 720
            Top = 16
            Width = 193
            Height = 281
            DataSource = dsTest
            TabOrder = 1
          end
        end
        object gbTET: TGroupBox
          Left = 0
          Top = 0
          Width = 927
          Height = 164
          Align = alTop
          TabOrder = 1
          object DBGrid1: TDBGrid
            Left = 2
            Top = 15
            Width = 711
            Height = 147
            DataSource = dsTET
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBMemoTest1: TDBMemo
            Left = 720
            Top = 15
            Width = 193
            Height = 143
            DataSource = dsTET
            TabOrder = 1
          end
        end
      end
    end
  end
  object dsTET: TDataSource
    Left = 64
    Top = 352
  end
  object dsTest: TDataSource
    Left = 384
    Top = 356
  end
end
