object Form1: TForm1
  Left = 260
  Top = 214
  Width = 555
  Height = 360
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
  object DBGrid1: TDBGrid
    Left = 9
    Top = 97
    Width = 241
    Height = 153
    DataSource = dsTable
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator1: TDBNavigator
    Left = 9
    Top = 259
    Width = 240
    Height = 25
    DataSource = dsTable
    TabOrder = 1
  end
  object DBGrid2: TDBGrid
    Left = 293
    Top = 97
    Width = 241
    Height = 153
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object DBNavigator2: TDBNavigator
    Left = 293
    Top = 259
    Width = 240
    Height = 25
    TabOrder = 3
  end
  object Button1: TButton
    Left = 320
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Run Query'
    TabOrder = 4
    OnClick = Button1Click
  end
  object GroupBox1: TGroupBox
    Left = 294
    Top = 0
    Width = 240
    Height = 83
    Caption = ' Query Text '
    TabOrder = 5
    object mQuery: TMemo
      Left = 2
      Top = 15
      Width = 236
      Height = 66
      Align = alClient
      Lines.Strings = (
        'Select * from Table1 where id >= 2')
      TabOrder = 0
    end
  end
  object GroupBox2: TGroupBox
    Left = 10
    Top = 0
    Width = 240
    Height = 83
    TabOrder = 6
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 225
      Height = 65
      AutoSize = False
      Caption = 
        'This demo shows how you can use IProvider interface of TClientDa' +
        'taset with Accuracer components.'
      WordWrap = True
    end
  end
  object Button2: TButton
    Left = 72
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 7
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 416
    Top = 296
    Width = 89
    Height = 25
    Caption = 'Execute Query'
    TabOrder = 8
    OnClick = Button3Click
  end
  object cdsQuery: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <>
    Params = <>
    ProviderName = 'dspQueryProvider'
    StoreDefs = True
    Left = 416
    Top = 80
  end
  object cdsTable: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'Company'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'Address'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'Phone'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'FAX'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'TaxRate'
        DataType = ftFloat
      end
      item
        Name = 'LastInvoiceDate'
        DataType = ftDateTime
      end
      item
        Name = 'CustNo'
        Attributes = [faReadonly]
        DataType = ftAutoInc
      end>
    IndexDefs = <>
    Params = <>
    ProviderName = 'dsTableProvider'
    StoreDefs = True
    AfterPost = cdsTableAfterPost
    AfterDelete = cdsTableAfterDelete
    Left = 113
    Top = 176
  end
  object dsTable: TDataSource
    DataSet = cdsTable
    Left = 200
    Top = 176
  end
  object dsTableProvider: TDataSetProvider
    DataSet = EasyTable1
    ResolveToDataSet = True
    Options = [poIncFieldProps, poAutoRefresh, poPropogateChanges, poAllowCommandText]
    UpdateMode = upWhereKeyOnly
    Left = 153
    Top = 176
  end
  object dspQueryProvider: TDataSetProvider
    DataSet = EasyQuery1
    ResolveToDataSet = True
    Options = [poIncFieldProps, poAutoRefresh, poPropogateChanges, poAllowCommandText]
    UpdateMode = upWhereKeyOnly
    Left = 376
    Top = 80
  end
  object DataSource1: TDataSource
    DataSet = cdsQuery
    Left = 336
    Top = 80
  end
  object EasyDatabase1: TEasyDatabase
    Connected = True
    DatabaseFileName = '..\..\Data\DBDemos.edb'
    DatabaseName = 'TestDB'
    InMemory = False
    SessionName = 'Default'
    Left = 256
    Top = 168
  end
  object EasyQuery1: TEasyQuery
    RequestLive = False
    CurrentVersion = '5.72 '
    InMemory = True
    BDELikeFilter = False
    Left = 464
    Top = 80
  end
  object EasyTable1: TEasyTable
    CurrentVersion = '5.72 '
    TableName = 'customer_Findkey'
    DatabaseName = 'TestDB'
    InMemory = False
    AutoIndexes = False
    CacheEnabled = True
    BDELikeFilter = False
    Left = 80
    Top = 176
  end
end
