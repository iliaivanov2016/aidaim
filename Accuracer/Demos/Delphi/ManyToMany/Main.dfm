object MainForm: TMainForm
  Left = 240
  Top = 190
  Width = 570
  Height = 468
  Caption = 'ManyToMany Relationship Demo'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 562
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 94
      Top = 18
      Width = 355
      Height = 16
      Caption = 'This demo shows an example of many-to-many relationship.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 52
    Width = 562
    Height = 389
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'Departments'
      object GroupBox1: TGroupBox
        Left = 0
        Top = 0
        Width = 554
        Height = 313
        Align = alTop
        Caption = 'Departments and Members working in selected department: '
        TabOrder = 0
        object GroupBox2: TGroupBox
          Left = 7
          Top = 22
          Width = 538
          Height = 137
          Caption = 'All Departments: '
          TabOrder = 0
          object DBGrid1: TDBGrid
            Left = 7
            Top = 24
            Width = 522
            Height = 73
            DataSource = DataSource1
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBNavigator1: TDBNavigator
            Left = 8
            Top = 104
            Width = 240
            Height = 25
            DataSource = DataSource1
            TabOrder = 1
          end
        end
        object GroupBox3: TGroupBox
          Left = 8
          Top = 162
          Width = 537
          Height = 137
          Caption = 'Members for selected department: '
          TabOrder = 1
          object DBGrid2: TDBGrid
            Left = 8
            Top = 24
            Width = 521
            Height = 73
            DataSource = DataSource2
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBNavigator2: TDBNavigator
            Left = 8
            Top = 104
            Width = 240
            Height = 25
            DataSource = DataSource2
            TabOrder = 1
          end
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Members'
      ImageIndex = 1
      object GroupBox4: TGroupBox
        Left = 0
        Top = 0
        Width = 554
        Height = 345
        Align = alTop
        Caption = 'Members and Departments where selected member works: '
        TabOrder = 0
        object GroupBox5: TGroupBox
          Left = 8
          Top = 22
          Width = 529
          Height = 137
          Caption = 'All Members: '
          TabOrder = 0
          object DBGrid3: TDBGrid
            Left = 8
            Top = 24
            Width = 513
            Height = 73
            DataSource = DataSource3
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBNavigator3: TDBNavigator
            Left = 8
            Top = 104
            Width = 240
            Height = 25
            DataSource = DataSource3
            TabOrder = 1
          end
        end
        object GroupBox6: TGroupBox
          Left = 8
          Top = 182
          Width = 529
          Height = 137
          Caption = 'Departments for selected member: '
          TabOrder = 1
          object DBGrid4: TDBGrid
            Left = 8
            Top = 24
            Width = 513
            Height = 73
            DataSource = DataSource4
            TabOrder = 0
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'MS Sans Serif'
            TitleFont.Style = []
          end
          object DBNavigator4: TDBNavigator
            Left = 8
            Top = 104
            Width = 240
            Height = 25
            DataSource = DataSource4
            TabOrder = 1
          end
        end
      end
    end
  end
  object DataSource1: TDataSource
    DataSet = Deps1_ds
    Left = 232
    Top = 41
  end
  object DataSource2: TDataSource
    DataSet = DMLinks1_ds
    Left = 328
    Top = 42
  end
  object DataSource3: TDataSource
    DataSet = Members2_ds
    Left = 232
    Top = 81
  end
  object DataSource4: TDataSource
    DataSet = DMLinks2_ds
    Left = 328
    Top = 82
  end
  object ACRDatabase1: TACRDatabase
    FormatVersion = 4.019999999999999000
    DatabaseFileName = '..\..\Data\DBDemos.adb'
    DatabaseName = 'Many'
    Exclusive = True
    SessionName = 'Default'
    BackupParams.CompressionAlgorithm = caNone
    BackupParams.CompressionMode = 1
    BackupParams.CryptoParams.CryptoAlgorithm = craNone
    BackupParams.CryptoParams.CryptoMode = acmCTS
    BackupParams.CryptoParams.KeySize = 56
    BackupParams.CryptoParams.Password = 'ACRpassword'
    BackupParams.CryptoParams.UseInitVector = False
    BackupParams.BlockSize = 102400
    ConnectionParams.RemoteHost = 'localhost'
    ConnectionParams.RemotePort = 6669
    ConnectionParams.LocalPort = 6668
    ConnectionParams.DatabaseName = 'DBDemos'
    ConnectionParams.CompressionAlgorithm = caNone
    ConnectionParams.CompressionMode = 1
    ConnectionParams.CryptoParams.CryptoAlgorithm = craNone
    ConnectionParams.CryptoParams.CryptoMode = acmCTS
    ConnectionParams.CryptoParams.KeySize = 56
    ConnectionParams.CryptoParams.Password = 'ACRpassword'
    ConnectionParams.CryptoParams.UseInitVector = False
    ConnectionParams.ServerID = 0
    ConnectionParams.PacketSize = 8192
    ConnectionParams.ConnectRetryCount = 30
    ConnectionParams.ConnectDelay = 500
    ConnectionParams.DisconnectRetryCount = 10
    ConnectionParams.DisconnectDelay = 300
    ConnectionParams.ResendRequestDelay = 500
    ConnectionParams.ReceiveDelay = 20000
    LockParams.Delay = 100
    LockParams.RetryCount = 10
    Options.MaxSessionCount = 367
    Options.PageSize = 4096
    Options.ExtentPageCount = 4
    Options.RandomSearchRetryCount = 10
    CryptoParams.CryptoAlgorithm = craNone
    CryptoParams.CryptoMode = acmCTS
    CryptoParams.KeySize = 56
    CryptoParams.Password = 'ACRpassword'
    CryptoParams.UseInitVector = False
    Left = 144
    Top = 40
  end
  object Deps1_ds: TACRTable
    CurrentVersion = '4.02 '
    StoreDefs = True
    DatabaseName = 'Many'
    InMemory = False
    ReadOnly = False
    IndexDefs = <
      item
        Name = '@ID'
        Fields = 'ID'
        Options = [ixUnique]
      end
      item
        Name = '@@Name'
        CaseInsFields = 'Name'
        Fields = 'Name'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@Name'
        Fields = 'Name'
      end>
    FieldDefs = <
      item
        Name = 'Name'
        DataType = ftFixedChar
        Size = 20
      end
      item
        Name = 'ID'
        DataType = ftAutoInc
      end>
    TableName = 'Departments'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 200
    Top = 40
  end
  object Members2_ds: TACRTable
    CurrentVersion = '4.02 '
    StoreDefs = True
    DatabaseName = 'Many'
    InMemory = False
    ReadOnly = False
    IndexDefs = <
      item
        Name = '@ID'
        Fields = 'ID'
        Options = [ixUnique]
      end
      item
        Name = '@@FirstName'
        CaseInsFields = 'FirstName'
        Fields = 'FirstName'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@FirstName'
        Fields = 'FirstName'
      end>
    FieldDefs = <
      item
        Name = 'FirstName'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'ID'
        DataType = ftAutoInc
      end>
    TableName = 'Members'
    Exclusive = False
    MemoryTableAllocBy = 1000
    Left = 200
    Top = 80
  end
  object DMLinks1_ds: TACRTable
    CurrentVersion = '4.02 '
    StoreDefs = True
    DatabaseName = 'Many'
    InMemory = False
    ReadOnly = False
    IndexDefs = <
      item
        Name = '@ID'
        Fields = 'ID'
        Options = [ixUnique]
      end
      item
        Name = '@@Department_ID'
        CaseInsFields = 'Department_ID'
        Fields = 'Department_ID'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@Department_ID'
        Fields = 'Department_ID'
      end
      item
        Name = '@@Member_ID'
        CaseInsFields = 'Member_ID'
        Fields = 'Member_ID'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@Member_ID'
        Fields = 'Member_ID'
      end>
    IndexName = '@Department_ID'
    FieldDefs = <
      item
        Name = 'Department_ID'
        DataType = ftFixedChar
        Size = 20
      end
      item
        Name = 'Member_ID'
        DataType = ftFixedChar
        Size = 20
      end
      item
        Name = 'ID'
        DataType = ftAutoInc
      end>
    TableName = 'Dep_Mem_Links'
    Exclusive = False
    MasterFields = 'ID'
    MasterSource = DataSource1
    MemoryTableAllocBy = 1000
    Left = 296
    Top = 40
  end
  object DMLinks2_ds: TACRTable
    CurrentVersion = '4.02 '
    StoreDefs = True
    DatabaseName = 'Many'
    InMemory = False
    ReadOnly = False
    IndexDefs = <
      item
        Name = '@ID'
        Fields = 'ID'
        Options = [ixUnique]
      end
      item
        Name = '@@Department_ID'
        CaseInsFields = 'Department_ID'
        Fields = 'Department_ID'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@Department_ID'
        Fields = 'Department_ID'
      end
      item
        Name = '@@Member_ID'
        CaseInsFields = 'Member_ID'
        Fields = 'Member_ID'
        Options = [ixCaseInsensitive]
      end
      item
        Name = '@Member_ID'
        Fields = 'Member_ID'
      end>
    IndexName = '@Member_ID'
    FieldDefs = <
      item
        Name = 'Department_ID'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'Member_ID'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'ID'
        DataType = ftAutoInc
      end>
    TableName = 'Dep_Mem_Links'
    Exclusive = False
    MasterFields = 'ID'
    MasterSource = DataSource3
    MemoryTableAllocBy = 1000
    Left = 296
    Top = 80
  end
end
