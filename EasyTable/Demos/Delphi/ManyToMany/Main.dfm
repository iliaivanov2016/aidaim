object MainForm: TMainForm
  Left = 208
  Top = 70
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
  object Deps1_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Departments'
    DatabaseName = 'DBDemos'
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 232
    Top = 41
  end
  object DataSource1: TDataSource
    DataSet = Deps1_ds
    Left = 264
    Top = 41
  end
  object DMLinks1_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Dep_Mem_Links'
    DatabaseName = 'DBDemos'
    IndexName = '@Department_ID'
    MasterFields = 'ID'
    MasterSource = DataSource1
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 320
    Top = 42
    object DMLinks1_dsMemberName: TStringField
      DisplayWidth = 25
      FieldKind = fkLookup
      FieldName = 'MemberName'
      LookupDataSet = Members1_ds
      LookupKeyFields = 'ID'
      LookupResultField = 'FirstName'
      KeyFields = 'Member_ID'
      Size = 255
      Lookup = True
    end
    object DMLinks1_dsDepartment_ID: TIntegerField
      FieldName = 'Department_ID'
    end
    object DMLinks1_dsMember_ID: TIntegerField
      FieldName = 'Member_ID'
    end
    object DMLinks1_dsID: TAutoIncField
      FieldName = 'ID'
    end
  end
  object DataSource2: TDataSource
    DataSet = DMLinks1_ds
    Left = 352
    Top = 42
  end
  object EasyDatabase1: TEasyDatabase
    Connected = True
    DatabaseFileName = '..\..\Data\DBDemos.edb'
    DatabaseName = 'DBDemos'
    InMemory = False
    SessionName = 'Default'
    Left = 144
    Top = 45
  end
  object Members1_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Members'
    DatabaseName = 'DBDemos'
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 416
    Top = 42
  end
  object Deps2_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Departments'
    DatabaseName = 'DBDemos'
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 416
    Top = 81
  end
  object DataSource3: TDataSource
    DataSet = Members2_ds
    Left = 264
    Top = 81
  end
  object DMLinks2_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Dep_Mem_Links'
    DatabaseName = 'DBDemos'
    IndexName = '@Member_ID'
    MasterFields = 'ID'
    MasterSource = DataSource3
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 320
    Top = 82
    object DMLinks2_dsDepartmentName: TStringField
      FieldKind = fkLookup
      FieldName = 'DepartmentName'
      LookupDataSet = Deps2_ds
      LookupKeyFields = 'ID'
      LookupResultField = 'Name'
      KeyFields = 'Department_ID'
      Size = 25
      Lookup = True
    end
    object DMLinks2_dsDepartment_ID: TIntegerField
      FieldName = 'Department_ID'
    end
    object DMLinks2_dsMember_ID: TIntegerField
      FieldName = 'Member_ID'
    end
    object DMLinks2_dsID: TAutoIncField
      FieldName = 'ID'
    end
  end
  object DataSource4: TDataSource
    DataSet = DMLinks2_ds
    Left = 352
    Top = 82
  end
  object Members2_ds: TEasyTable
    CurrentVersion = '6.04 Prerelease #1'
    TableName = 'Members'
    DatabaseName = 'DBDemos'
    InMemory = False
    AutoIndexes = True
    CacheEnabled = True
    BDELikeFilter = False
    Active = True
    Left = 232
    Top = 82
  end
end
