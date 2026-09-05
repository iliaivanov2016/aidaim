object Form1: TForm1
  Left = 52
  Top = 114
  Width = 812
  Height = 466
  Caption = 'Form1'
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
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 804
    Height = 257
    Align = alTop
    Caption = ' Test results '
    TabOrder = 0
    object Info: TMemo
      Left = 2
      Top = 15
      Width = 800
      Height = 240
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 257
    Width = 804
    Height = 182
    Align = alClient
    Caption = ' Tests '
    TabOrder = 1
    object CurrentProgress: TGauge
      Left = 92
      Top = 16
      Width = 193
      Height = 25
      ForeColor = clBlue
      Progress = 0
    end
    object Label1: TLabel
      Left = 8
      Top = 22
      Width = 80
      Height = 13
      Caption = 'Current progress:'
    end
    object OverallProgress: TGauge
      Left = 92
      Top = 48
      Width = 193
      Height = 25
      ForeColor = clBlue
      Progress = 0
    end
    object Label2: TLabel
      Left = 8
      Top = 54
      Width = 79
      Height = 13
      Caption = 'Overall progress:'
    end
    object cmbDirArray: TButton
      Left = 304
      Top = 16
      Width = 75
      Height = 25
      Caption = 'DIRArray'
      TabOrder = 0
      OnClick = cmbDirArrayClick
    end
    object cmbClose: TButton
      Left = 616
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 1
      OnClick = cmbCloseClick
    end
    object Button1: TButton
      Left = 384
      Top = 48
      Width = 75
      Height = 25
      Caption = 'FSM Test'
      TabOrder = 2
      OnClick = Button1Click
    end
    object cmbDIRManager: TButton
      Left = 304
      Top = 48
      Width = 75
      Height = 25
      Caption = 'DIRManager'
      TabOrder = 3
      OnClick = cmbDIRManagerClick
    end
    object btPageManager: TButton
      Left = 384
      Top = 16
      Width = 75
      Height = 25
      Caption = 'PageManager'
      TabOrder = 4
      OnClick = btPageManagerClick
    end
    object btUFPMTest: TButton
      Left = 464
      Top = 48
      Width = 119
      Height = 25
      Caption = 'UserFilePageMap'
      TabOrder = 5
      OnClick = btUFPMTestClick
    end
    object cbnFFSTest: TButton
      Left = 464
      Top = 16
      Width = 119
      Height = 25
      Caption = 'Single File System test'
      TabOrder = 6
      OnClick = cbnFFSTestClick
    end
    object BigSFSTest: TButton
      Left = 616
      Top = 48
      Width = 74
      Height = 25
      Caption = 'Big SFS test'
      TabOrder = 7
      OnClick = BigSFSTestClick
    end
  end
end
