{ *************************************************************************** }
{                                                                             }
{ Kylix and Delphi Cross-Platform Visual Component Library                    }
{                                                                             }
{ Copyright (c) 1995, 2001 Borland Software Corporation                       }
{                                                                             }
{ *************************************************************************** }


unit DB;

{$R-,T-,H+,X+}

interface

{$IFDEF MSWINDOWS}
uses Windows, SysUtils, Classes, Variants, MaskUtils, SqlTimSt, FMTBcd;
{$ENDIF}
{$IFDEF LINUX}
uses Libc, SysUtils, Classes, Variants, SqlTimSt, FMTBcd;
{$ENDIF}

type

{ Forward declarations }

  TField = class;
  TObjectField = class;
  TDataLink = class;
  TDataSource = class;
  TDataSet = class;
  TFieldDefs = class;
  TIndexDefs = class;

{ Exception classes }

  EDatabaseError = class(Exception);

{ EUpdateError }

  EUpdateError = class(EDatabaseError)
  private
    FErrorCode: Integer;
    FPreviousError: Integer;
    FContext: string;
    FOriginalException: Exception;
  public
    constructor Create(NativeError, Context: string;
      ErrCode, PrevError: Integer; E: Exception);
    destructor Destroy; override;
    property Context: string read FContext;
    property ErrorCode: Integer read FErrorCode;
    property PreviousError: Integer read FPreviousError;
    property OriginalException: Exception read FOriginalException;
  end;

{ Misc DataSet types }

  TFieldType = (ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
    ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,
    ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString,
    ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob,
    ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd);

  TDataSetState = (dsInactive, dsBrowse, dsEdit, dsInsert, dsSetKey,
    dsCalcFields, dsFilter, dsNewValue, dsOldValue, dsCurValue, dsBlockRead,
    dsInternalCalc, dsOpening);

  TDataEvent = (deFieldChange, deRecordChange, deDataSetChange,
    deDataSetScroll, deLayoutChange, deUpdateRecord, deUpdateState,
    deCheckBrowseMode, dePropertyChange, deFieldListChange,
    deFocusControl, deParentScroll, deConnectChange, deReconcileError,
    deDisabledStateChange);

  TUpdateStatus = (usUnmodified, usModified, usInserted, usDeleted);
  TUpdateStatusSet = set of TUpdateStatus;

  TUpdateAction = (uaFail, uaAbort, uaSkip, uaRetry, uaApplied);

  TUpdateRecordTypes = set of (rtModified, rtInserted, rtDeleted, rtUnmodified);

  TUpdateMode = (upWhereAll, upWhereChanged, upWhereKeyOnly);

  TUpdateKind = (ukModify, ukInsert, ukDelete);

  TUpdateErrorEvent = procedure(DataSet: TDataSet; E: EDatabaseError;
    UpdateKind: TUpdateKind; var UpdateAction: TUpdateAction) of object;

  TUpdateRecordEvent = procedure(DataSet: TDataSet; UpdateKind: TUpdateKind;
    var UpdateAction: TUpdateAction) of object;

{ TCustomConnection }

  TLoginEvent = procedure(Sender: TObject; Username, Password: string) of object;
  TConnectChangeEvent = procedure(Sender: TObject; Connecting: Boolean) of object;

  TCustomConnection = class(TComponent)
  private
    FClients: TList;
    FDataSets: TList;
    FConnectEvents: TList;
    FLoginPrompt: Boolean;
    FStreamedConnected: Boolean;
    FAfterConnect: TNotifyEvent;
    FAfterDisconnect: TNotifyEvent;
    FBeforeConnect: TNotifyEvent;
    FBeforeDisconnect: TNotifyEvent;
    FOnLogin: TLoginEvent;
  protected
    procedure DoConnect; virtual;
    procedure DoDisconnect; virtual;
    function GetConnected: Boolean; virtual;
    function GetDataSet(Index: Integer): TDataSet; virtual;
    function GetDataSetCount: Integer; virtual;
    procedure Loaded; override;
    procedure RegisterClient(Client: TObject; Event: TConnectChangeEvent = nil); virtual;
    procedure SetConnected(Value: Boolean); virtual;
    procedure SendConnectEvent(Connecting: Boolean);
    property StreamedConnected: Boolean read FStreamedConnected write FStreamedConnected;
    procedure UnRegisterClient(Client: TObject); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Open; overload;
    procedure Close;
    property Connected: Boolean read GetConnected write SetConnected default False;
    property DataSets[Index: Integer]: TDataSet read GetDataSet;
    property DataSetCount: Integer read GetDataSetCount;
    property LoginPrompt: Boolean read FLoginPrompt write FLoginPrompt default False;
    property AfterConnect: TNotifyEvent read FAfterConnect write FAfterConnect;
    property BeforeConnect: TNotifyEvent read FBeforeConnect write FBeforeConnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property OnLogin: TLoginEvent read FOnLogin write FOnLogin;
  end;

{ TNamedItem }

  TNamedItem = class(TCollectionItem)
  private
    FName: string;
  protected
    function GetDisplayName: string; override;
    procedure SetDisplayName(const Value: string); override;
  published
    property Name: string read FName write SetDisplayName;
  end;

{ TDefCollection }

  TDefUpdateMethod = procedure of object;

  TDefCollection = class(TOwnedCollection)
  private
    FDataSet: TDataSet;
    FUpdated: Boolean;
    FOnUpdate: TNotifyEvent;
    FInternalUpdateCount: Integer;
  protected
    procedure DoUpdate(Sender: TObject);
    procedure SetItemName(AItem: TCollectionItem); override;
    procedure Update(AItem: TCollectionItem); override;
    procedure UpdateDefs(AMethod: TDefUpdateMethod);
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
  public
    constructor Create(ADataSet: TDataSet; AOwner: TPersistent;
      AClass: TCollectionItemClass);
    function Find(const AName: string): TNamedItem;
    procedure GetItemNames(List: TStrings);
    function IndexOf(const AName: string): Integer;
    property DataSet: TDataSet read FDataSet;
    property Updated: Boolean read FUpdated write FUpdated;
  end;

{ TFieldDef }

  TFieldClass = class of TField;

  TFieldAttribute = (faHiddenCol, faReadonly, faRequired, faLink, faUnNamed, faFixed);
  TFieldAttributes = set of TFieldAttribute;

  TFieldDef = class(TNamedItem)
  private
    FChildDefs: TFieldDefs;
    FPrecision: Integer;
    FFieldNo: Integer;
    FSize: Integer;
    FInternalCalcField: Boolean;
    FDataType: TFieldType;
    FAttributes: TFieldAttributes;
    function CreateFieldComponent(Owner: TComponent;
      ParentField: TObjectField = nil; FieldName: string = ''): TField;
    function GetChildDefs: TFieldDefs;
    function GetFieldClass: TFieldClass;
    function GetFieldNo: Integer;
    function GetParentDef: TFieldDef;
    function GetRequired: Boolean;
    function GetSize: Integer;
    procedure ReadRequired(Reader: TReader);
    procedure SetAttributes(Value: TFieldAttributes);
    procedure SetChildDefs(Value: TFieldDefs);
    procedure SetDataType(Value: TFieldType);
    procedure SetPrecision(Value: Integer);
    procedure SetRequired(Value: Boolean);
    procedure SetSize(Value: Integer);
  protected
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(Owner: TFieldDefs; const Name: string;
      DataType: TFieldType; Size: Integer; Required: Boolean; FieldNo: Integer); reintroduce; overload;
    destructor Destroy; override;
    function AddChild: TFieldDef;
    procedure Assign(Source: TPersistent); override;
    function CreateField(Owner: TComponent; ParentField: TObjectField = nil;
      const FieldName: string = ''; CreateChildren: Boolean = True): TField;
    function HasChildDefs: Boolean;
    property FieldClass: TFieldClass read GetFieldClass;
    property FieldNo: Integer read GetFieldNo write FFieldNo stored False;
    property InternalCalcField: Boolean read FInternalCalcField write FInternalCalcField;
    property ParentDef: TFieldDef read GetParentDef;
    property Required: Boolean read GetRequired write SetRequired;
  published
    property Attributes: TFieldAttributes read FAttributes write SetAttributes default [];
    property ChildDefs: TFieldDefs read GetChildDefs write SetChildDefs stored HasChildDefs;
    property DataType: TFieldType read FDataType write SetDataType default ftUnknown;
    property Precision: Integer read FPrecision write SetPrecision default 0;
    property Size: Integer read GetSize write SetSize default 0;
  end;

{ TFieldDefs }

  TFieldDefs = class(TDefCollection)
  private
    FParentDef: TFieldDef;
    FHiddenFields: Boolean;
    function GetFieldDef(Index: Integer): TFieldDef;
    procedure SetFieldDef(Index: Integer; Value: TFieldDef);
    procedure SetHiddenFields(Value: Boolean);
  protected
    procedure FieldDefUpdate(Sender: TObject);
    procedure ChildDefUpdate(Sender: TObject);
    procedure SetItemName(AItem: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function AddFieldDef: TFieldDef;
    function Find(const Name: string): TFieldDef;
    procedure Update; reintroduce;
    { procedure Add kept for compatability - AddFieldDef is the better way }
    procedure Add(const Name: string; DataType: TFieldType; Size: Integer = 0;
      Required: Boolean = False);
    property HiddenFields: Boolean read FHiddenFields write SetHiddenFields;
    property Items[Index: Integer]: TFieldDef read GetFieldDef write SetFieldDef; default;
    property ParentDef: TFieldDef read FParentDef;
  end;

{ TIndexDef }

  TIndexOption = (ixPrimary, ixUnique, ixDescending, ixCaseInsensitive,
    ixExpression, ixNonMaintained);
  TIndexOptions = set of TIndexOption;

  TIndexDef = class(TNamedItem)
  private
    FSource: string;
    FFieldExpression: string;
    FDescFields: string;
    FCaseInsFields: string;
    FOptions: TIndexOptions;
    FGroupingLevel: Integer;
    function GetExpression: string;
    function GetFields: string;
    procedure SetDescFields(const Value: string);
    procedure SetCaseInsFields(const Value: string);
    procedure SetExpression(const Value: string);
    procedure SetFields(const Value: string);
    procedure SetOptions(Value: TIndexOptions);
    procedure SetSource(const Value: string);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Owner: TIndexDefs; const Name, Fields: string;
      Options: TIndexOptions); reintroduce; overload;
    procedure Assign(ASource: TPersistent); override;
    property FieldExpression: string read FFieldExpression;
  published
    property CaseInsFields: string read FCaseInsFields write SetCaseInsFields;
    property DescFields: string read FDescFields write SetDescFields;
    property Expression: string read GetExpression write SetExpression;
    property Fields: string read GetFields write SetFields;
    property Options: TIndexOptions read FOptions write SetOptions default [];
    property Source: string read FSource write SetSource;
    property GroupingLevel: Integer read FGroupingLevel write FGroupingLevel default 0;
  end;

{ TIndexDefs }

  TIndexDefs = class(TDefCollection)
  private
    function GetIndexDef(Index: Integer): TIndexDef;
    procedure SetIndexDef(Index: Integer; Value: TIndexDef);
  public
    constructor Create(ADataSet: TDataSet);
    function AddIndexDef: TIndexDef;
    function Find(const Name: string): TIndexDef;
    procedure Update; reintroduce;
    function FindIndexForFields(const Fields: string): TIndexDef;
    function GetIndexForFields(const Fields: string;
      CaseInsensitive: Boolean): TIndexDef;
    { procedure Add kept for compatability - AddIndexDef is the better way }
    procedure Add(const Name, Fields: string; Options: TIndexOptions);
    property Items[Index: Integer]: TIndexDef read GetIndexDef write SetIndexDef; default;
  end;

{ TFlatList }

  TFlatList = class(TStringList)
  private
    FDataSet: TDataSet;
    FLocked: Boolean;
    FUpdated: Boolean;
  protected
    procedure ListChanging(Sender: TObject);
    function FindItem(const Name: string; MustExist: Boolean): TObject;
    function GetCount: Integer; override;
    function GetUpdated: Boolean; virtual;
    procedure UpdateList; virtual; abstract;
    property Updated: Boolean read GetUpdated write FUpdated;
    property Locked: Boolean read FLocked write FLocked;
  public
    constructor Create(ADataSet: TDataSet);
    procedure Update;
    property DataSet: TDataSet read FDataSet;
  end;

{ TFieldDefList }

  TFieldDefList = class(TFlatList)
  private
    function GetFieldDef(Index: Integer): TFieldDef;
  protected
    function GetUpdated: Boolean; override;
    procedure UpdateList; override;
  public
    function FieldByName(const Name: string): TFieldDef;
    function Find(const Name: string): TFieldDef; reintroduce;
    property FieldDefs[Index: Integer]: TFieldDef read GetFieldDef; default;
  end;

{ TFieldList }

  TFieldList = class(TFlatList)
  private
    function GetField(Index: Integer): TField;
  protected
    procedure UpdateList; override;
  public
    function FieldByName(const Name: string): TField;
    function Find(const Name: string): TField; reintroduce;
    property Fields[Index: Integer]: TField read GetField; default;
  end;

{ TFields }

  TFieldKind = (fkData, fkCalculated, fkLookup, fkInternalCalc, fkAggregate);
  TFieldKinds = set of TFieldKind;

  TFields = class(TObject)
  private
    FList: TList;
    FDataSet: TDataSet;
    FSparseFields: Integer;
    FOnChange: TNotifyEvent;
    FValidFieldKinds: TFieldKinds;
  protected
    procedure Changed;
    procedure CheckFieldKind(FieldKind: TFieldKind; Field: TField);
    function GetCount: Integer;
    function GetField(Index: Integer): TField;
    procedure SetField(Index: Integer; Value: TField);
    procedure SetFieldIndex(Field: TField; Value: Integer);
    property SparseFields: Integer read FSparseFields write FSparseFields;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ValidFieldKinds: TFieldKinds read FValidFieldKinds write FValidFieldKinds;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    procedure Add(Field: TField);
    procedure CheckFieldName(const FieldName: string);
    procedure CheckFieldNames(const FieldNames: string);
    procedure Clear;
    function FindField(const FieldName: string): TField;
    function FieldByName(const FieldName: string): TField;
    function FieldByNumber(FieldNo: Integer): TField;
    procedure GetFieldNames(List: TStrings);
    function IndexOf(Field: TField): Integer;
    procedure Remove(Field: TField);
    property Count: Integer read GetCount;
    property DataSet: TDataSet read FDataSet;
    property Fields[Index: Integer]: TField read GetField write SetField; default;
  end;

{ TField }

  TProviderFlag = (pfInUpdate, pfInWhere, pfInKey, pfHidden);
  TProviderFlags = set of TProviderFlag;

  TFieldNotifyEvent = procedure(Sender: TField) of object;
  TFieldGetTextEvent = procedure(Sender: TField; var Text: string;
    DisplayText: Boolean) of object;
  TFieldSetTextEvent = procedure(Sender: TField; const Text: string) of object;
  TFieldRef = ^TField;
  TFieldChars = set of Char;
  TAutoRefreshFlag = (arNone, arAutoInc, arDefault);

  PLookupListEntry = ^TLookupListEntry;
  TLookupListEntry = record
    Key: Variant;
    Value: Variant;
  end;

  TLookupList = class(TObject)
  private
    FList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AKey, AValue: Variant);
    procedure Clear;
    function ValueOfKey(const AKey: Variant): Variant;
  end;

  TField = class(TComponent)
  private
    FAutoGenerateValue: TAutoRefreshFlag;
    FDataSet: TDataSet;
    FFieldName: string;
    FFields: TFields;
    FDataType: TFieldType;
    FReadOnly: Boolean;
    FFieldKind: TFieldKind;
    FAlignment: TAlignment;
    FVisible: Boolean;
    FRequired: Boolean;
    FValidating: Boolean;
    FSize: Integer;
    FOffset: Integer;
    FFieldNo: Integer;
    FDisplayWidth: Integer;
    FDisplayLabel: string;
{$IFDEF MSWINDOWS}
    FEditMask: TEditMask;
{$ENDIF}
{$IFDEF LINUX}
    FEditMask: string;
{$ENDIF}
    FValueBuffer: Pointer;
    FLookupDataSet: TDataSet;
    FKeyFields: string;
    FLookupKeyFields: string;
    FLookupResultField: string;
    FLookupCache: Boolean;
    FLookupList: TLookupList;
    FAttributeSet: string;
    FCustomConstraint: string;
    FImportedConstraint: string;
    FConstraintErrorMessage: string;
    FDefaultExpression: string;
    FOrigin: string;
    FProviderFlags: TProviderFlags;
    FParentField: TObjectField;
    FValidChars: TFieldChars;
    FOnChange: TFieldNotifyEvent;
    FOnValidate: TFieldNotifyEvent;
    FOnGetText: TFieldGetTextEvent;
    FOnSetText: TFieldSetTextEvent;
    procedure CalcLookupValue;
    function GetCalculated: Boolean;
    function GetDisplayLabel: string;
    function GetDisplayName: string;
    function GetDisplayText: string;
    function GetDisplayWidth: Integer;
    function GetEditText: string;
    function GetFullName: string;
    function GetIndex: Integer;
    function GetIsIndexField: Boolean;
    function GetLookup: Boolean;
    function GetLookupList: TLookupList;
    function GetCurValue: Variant;
    function GetNewValue: Variant;
    function GetOldValue: Variant;
    function IsDisplayLabelStored: Boolean;
    function IsDisplayWidthStored: Boolean;
    procedure ReadAttributeSet(Reader: TReader);
    procedure ReadCalculated(Reader: TReader);
    procedure ReadLookup(Reader: TReader);
    procedure SetAlignment(Value: TAlignment);
    procedure SetCalculated(Value: Boolean);
    procedure SetDisplayLabel(Value: string);
    procedure SetDisplayWidth(Value: Integer);
{$IFDEF MSWINDOWS}
    procedure SetEditMask(const Value: TEditMask);
{$ENDIF}
{$IFDEF LINUX}
    procedure SetEditMask(const Value: string);
{$ENDIF}
    procedure SetEditText(const Value: string);
    procedure SetFieldName(const Value: string);
    procedure SetIndex(Value: Integer);
    procedure SetLookup(Value: Boolean);
    procedure SetLookupDataSet(Value: TDataSet);
    procedure SetLookupKeyFields(const Value: string);
    procedure SetLookupResultField(const Value: string);
    procedure SetKeyFields(const Value: string);
    procedure SetLookupCache(const Value: Boolean);
    procedure SetNewValue(const Value: Variant);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetVisible(Value: Boolean);
    procedure ValidateLookupInfo(All: Boolean);
    procedure WriteAttributeSet(Writer: TWriter);
    procedure WriteCalculated(Writer: TWriter);
    procedure WriteLookup(Writer: TWriter);
  protected
    function AccessError(const TypeName: string): EDatabaseError; dynamic;
    procedure Bind(Binding: Boolean); virtual;
    procedure CheckInactive;
    class procedure CheckTypeSize(Value: Integer); virtual;
    procedure Change; virtual;
    procedure DataChanged;
    procedure DefineProperties(Filer: TFiler); override;
    procedure FreeBuffers; virtual;
    function GetAsBCD: TBcd; virtual;
    function GetAsBoolean: Boolean; virtual;
    function GetAsByteArray: Variant; virtual;
    function GetAsCurrency: Currency; virtual;
    function GetAsDateTime: TDateTime; virtual;
    function GetAsFloat: Double; virtual;
    function GetAsInteger: Longint; virtual;
    function GetAsSqlTimeStamp: TSQLTimeStamp; virtual;
    function GetAsString: string; virtual;
    function GetAsVariant: Variant; virtual;
    function GetCanModify: Boolean; virtual;
    function GetClassDesc: string; virtual;
    function GetDataSize: Integer; virtual;
    procedure CopyData(Source, Dest: Pointer); virtual;
    function GetDefaultWidth: Integer; virtual;
    function GetFieldNo: Integer; virtual;
    function GetHasConstraints: Boolean; virtual;
    function GetIsNull: Boolean; virtual;
    function GetSize: Integer; virtual;
    procedure GetText(var Text: string; DisplayText: Boolean); virtual;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure PropertyChanged(LayoutAffected: Boolean);
    procedure ReadState(Reader: TReader); override;
    procedure SetAsBCD(const Value: TBcd); virtual;
    procedure SetAsBoolean(Value: Boolean); virtual;
    procedure SetAsByteArray(const Value: Variant); virtual;
    procedure SetAsCurrency(Value: Currency); virtual;
    procedure SetAsDateTime(Value: TDateTime); virtual;
    procedure SetAsFloat(Value: Double); virtual;
    procedure SetAsInteger(Value: Longint); virtual;
    procedure SetAsSQLTimeStamp(const Value: TSQLTimeStamp); virtual;
    procedure SetAsString(const Value: string); virtual;
    procedure SetAsVariant(const Value: Variant); virtual;
    procedure SetDataSet(ADataSet: TDataSet); virtual;
    procedure SetDataType(Value: TFieldType);
    procedure SetFieldKind(Value: TFieldKind); virtual;
    procedure SetParentComponent(AParent: TComponent); override;
    procedure SetParentField(AField: TObjectField); virtual;
    procedure SetSize(Value: Integer); virtual;
    procedure SetText(const Value: string); virtual;
    procedure SetVarValue(const Value: Variant); virtual;
    procedure SetAutoGenerateValue(const Value: TAutoRefreshFlag);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignValue(const Value: TVarRec);
    procedure Clear; virtual;
    procedure FocusControl;
    function GetData(Buffer: Pointer; NativeFormat: Boolean = True): Boolean;
    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;
    class function IsBlob: Boolean; virtual;
    function IsValidChar(InputChar: Char): Boolean; virtual;
    procedure RefreshLookupList;
    procedure SetData(Buffer: Pointer; NativeFormat: Boolean = True);
    procedure SetFieldType(Value: TFieldType); virtual;
    procedure Validate(Buffer: Pointer);
    property AsBCD: TBcd read GetAsBCD write SetAsBCD;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsSQLTimeStamp: TSQLTimeStamp read GetAsSQLTimeStamp write SetAsSQLTimeStamp;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsInteger: Longint read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AttributeSet: string read FAttributeSet write FAttributeSet;
    property Calculated: Boolean read GetCalculated write SetCalculated default False;
    property CanModify: Boolean read GetCanModify;
    property CurValue: Variant read GetCurValue;
    property DataSet: TDataSet read FDataSet write SetDataSet stored False;
    property DataSize: Integer read GetDataSize;
    property DataType: TFieldType read FDataType;
    property DisplayName: string read GetDisplayName;
    property DisplayText: string read GetDisplayText;
{$IFDEF MSWINDOWS}
    property EditMask: TEditMask read FEditMask write SetEditMask;
    property EditMaskPtr: TEditMask read FEditMask;
{$ENDIF}
{$IFDEF LINUX}
    property EditMask: string read FEditMask write SetEditMask;
    property EditMaskPtr: string read FEditMask;
{$ENDIF}
    property FieldNo: Integer read GetFieldNo;
    property FullName: string read GetFullName;
    property IsIndexField: Boolean read GetIsIndexField;
    property IsNull: Boolean read GetIsNull;
    property Lookup: Boolean read GetLookup write SetLookup;
    property LookupList: TLookupList read GetLookupList;
    property NewValue: Variant read GetNewValue write SetNewValue;
    property Offset: Integer read FOffset;
    property OldValue: Variant read GetOldValue;
    property ParentField: TObjectField read FParentField write SetParentField;
    property Size: Integer read GetSize write SetSize;
    property Text: string read GetEditText write SetEditText;
    property ValidChars: TFieldChars read FValidChars write FValidChars;
    property Value: Variant read GetAsVariant write SetAsVariant;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property AutoGenerateValue: TAutoRefreshFlag read FAutoGenerateValue write SetAutoGenerateValue default arNone;
    property CustomConstraint: string read FCustomConstraint write FCustomConstraint;
    property ConstraintErrorMessage: string read FConstraintErrorMessage write FConstraintErrorMessage;
    property DefaultExpression: string read FDefaultExpression write FDefaultExpression;
    property DisplayLabel: string read GetDisplayLabel write SetDisplayLabel
      stored IsDisplayLabelStored;
    property DisplayWidth: Integer read GetDisplayWidth write SetDisplayWidth
      stored IsDisplayWidthStored;
    property FieldKind: TFieldKind read FFieldKind write SetFieldKind default fkData;
    property FieldName: string read FFieldName write SetFieldName;
    property HasConstraints: Boolean read GetHasConstraints default False;
    property Index: Integer read GetIndex write SetIndex stored False;
    property ImportedConstraint: string read FImportedConstraint write FImportedConstraint;
    property LookupDataSet: TDataSet read FLookupDataSet write SetLookupDataSet;
    property LookupKeyFields: string read FLookupKeyFields write SetLookupKeyFields;
    property LookupResultField: string read FLookupResultField write SetLookupResultField;
    property KeyFields: string read FKeyFields write SetKeyFields;
    property LookupCache: Boolean read FLookupCache write SetLookupCache default False;
    property Origin: string read FOrigin write FOrigin;
    property ProviderFlags: TProviderFlags read FProviderFlags write FProviderFlags default [pfInWhere, pfInUpdate];
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property Required: Boolean read FRequired write FRequired default False;
    property Visible: Boolean read FVisible write SetVisible default True;
    property OnChange: TFieldNotifyEvent read FOnChange write FOnChange;
    property OnGetText: TFieldGetTextEvent read FOnGetText write FOnGetText;
    property OnSetText: TFieldSetTextEvent read FOnSetText write FOnSetText;
    property OnValidate: TFieldNotifyEvent read FOnValidate write FOnValidate;
  end;

{ TStringField }

  TStringField = class(TField)
  private
    FFixedChar: Boolean;
    FTransliterate: Boolean;
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    function GetAsBCD: TBcd; override;
    function GetAsBoolean: Boolean; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsSqlTimeStamp: TSQLTimeStamp; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: string): Boolean;
    procedure SetAsBCD(const Value: TBcd); override;
    procedure SetAsBoolean(Value: Boolean); override;
    procedure SetAsDateTime(Value: TDateTime); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsSQLTimeStamp(const Value: TSQLTimeStamp); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: string read GetAsString write SetAsString;
  published
    property EditMask;
    property FixedChar: Boolean read FFixedChar write FFixedChar default False;
    property Size default 20;
    property Transliterate: Boolean read FTransliterate write FTransliterate default True;
  end;

{ TWideStringField }

  TWideStringField = class(TStringField)
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetAsWideString: WideString;
    function GetDataSize: Integer; override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
    procedure SetAsWideString(const Value: WideString);
  public
    constructor Create(AOwner: TComponent); override;
    property Value: WideString read GetAsWideString write SetAsWideString;
  end;

{ TNumericField }

  TNumericField = class(TField)
  private
    FDisplayFormat: string;
    FEditFormat: string;
  protected
    procedure RangeError(Value, Min, Max: Extended);
    procedure SetDisplayFormat(const Value: string);
    procedure SetEditFormat(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Alignment default taRightJustify;
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat;
    property EditFormat: string read FEditFormat write SetEditFormat;
  end;

{ TIntegerField }

  TIntegerField = class(TNumericField)
  private
    FMinRange: Longint;
    FMaxRange: Longint;
    FMinValue: Longint;
    FMaxValue: Longint;
    procedure CheckRange(Value, Min, Max: Longint);
    procedure SetMaxValue(Value: Longint);
    procedure SetMinValue(Value: Longint);
  protected
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: Longint): Boolean;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: Longint read GetAsInteger write SetAsInteger;
  published
    property MaxValue: Longint read FMaxValue write SetMaxValue default 0;
    property MinValue: Longint read FMinValue write SetMinValue default 0;
  end;

{ TSmallintField }

  TSmallintField = class(TIntegerField)
  protected
    function GetDataSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TLargeintField }

  Largeint = Int64;

  TLargeintField = class(TNumericField)
  private
    FMinValue: Largeint;
    FMaxValue: Largeint;
    procedure CheckRange(Value, Min, Max: Largeint);
  protected
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsLargeint: Largeint;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: Largeint): Boolean;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsLargeint(Value: Largeint);
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property AsLargeInt: LargeInt read GetAsLargeint write SetAsLargeint;
    property Value: Largeint read GetAsLargeint write SetAsLargeint;
  published
    property MaxValue: Largeint read FMaxValue write FMaxValue default 0;
    property MinValue: Largeint read FMinValue write FMinValue default 0;
  end;

{ TWordField }

  TWordField = class(TIntegerField)
  protected
    function GetDataSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TAutoIncField }

  TAutoIncField = class(TIntegerField)
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TFloatField }

  TFloatField = class(TNumericField)
  private
    FCurrency: Boolean;
    FCheckRange: Boolean;
    FPrecision: Integer;
    FMinValue: Double;
    FMaxValue: Double;
    procedure SetCurrency(Value: Boolean);
    procedure SetMaxValue(Value: Double);
    procedure SetMinValue(Value: Double);
    procedure SetPrecision(Value: Integer);
    procedure UpdateCheckRange;
  protected
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: Double read GetAsFloat write SetAsFloat;
  published
    { Lowercase to avoid name clash with C++ Currency type }
    property currency: Boolean read FCurrency write SetCurrency default False;
    property MaxValue: Double read FMaxValue write SetMaxValue;
    property MinValue: Double read FMinValue write SetMinValue;
    property Precision: Integer read FPrecision write SetPrecision default 15;
  end;

{ TCurrencyField }

  TCurrencyField = class(TFloatField)
  public
    constructor Create(AOwner: TComponent); override;
  published
    { Lowercase to avoid name clash with C++ Currency type }
    property currency default True;
  end;

{ TBooleanField }

  TBooleanField = class(TField)
  private
    FDisplayValues: string;
    FTextValues: array[Boolean] of string;
    procedure LoadTextValues;
    procedure SetDisplayValues(const Value: string);
  protected
    function GetAsBoolean: Boolean; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure SetAsBoolean(Value: Boolean); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: Boolean read GetAsBoolean write SetAsBoolean;
  published
    property DisplayValues: string read FDisplayValues write SetDisplayValues;
  end;

{ TDateTimeField }

  TDateTimeField = class(TField)
  private
    FDisplayFormat: string;
    function GetValue(var Value: TDateTime): Boolean;
    procedure SetDisplayFormat(const Value: string);
  protected
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure SetAsDateTime(Value: TDateTime); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: TDateTime read GetAsDateTime write SetAsDateTime;
  published
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat;
    property EditMask;
  end;

{ TSQLTimeStampField }

  TSQLTimeStampField = class(TField)
  private
    FDisplayFormat: string;
    function GetValue(var Value: TSQLTimeStamp): Boolean;
    procedure SetDisplayFormat(const Value: string);
  protected
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsSQLTimeStamp: TSQLTimeStamp; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsFloat: Double; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure SetAsSQLTimeStamp(const Value: TSQLTimeStamp); override;
    procedure SetAsDateTime(Value: TDateTime); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: TSQLTimeStamp read GetAsSQLTimeStamp write SetAsSQLTimeStamp;
  published
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat;
    property EditMask;
  end;

{ TDateField }

  TDateField = class(TDateTimeField)
  protected
    function GetDataSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TTimeField }

  TTimeField = class(TDateTimeField)
  protected
    function GetDataSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TBinaryField }

  TBinaryField = class(TField)
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsString: string; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetAsVariant: Variant; override;
    procedure SetAsString(const Value: string); override;
    procedure SetText(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Size default 16;
  end;

{ TBytesField }

  TBytesField = class(TBinaryField)
  protected
    function GetDataSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TVarBytesField }

  TVarBytesField = class(TBytesField)
  protected
    function GetDataSize: Integer; override;
    procedure SetAsByteArray(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TBCDField }

  {PBcd struct moved to FmtBcd.pas}

  TBCDField = class(TNumericField)
  private
    FCurrency: Boolean;
    FCheckRange: Boolean;
    FMinValue: Currency;
    FMaxValue: Currency;
    FPrecision: Integer;
    procedure SetCurrency(Value: Boolean);
    procedure SetMaxValue(Value: Currency);
    procedure SetMinValue(Value: Currency);
    procedure SetPrecision(Value: Integer);
    procedure UpdateCheckRange;
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsBCD: TBcd; override;
    function GetAsCurrency: Currency; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: Currency): Boolean;
    procedure SetAsBCD(const Value: TBcd); override;
    procedure SetAsCurrency(Value: Currency); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: Currency read GetAsCurrency write SetAsCurrency;
  published
    { Lowercase to avoid name clash with C++ Currency type }
    property currency: Boolean read FCurrency write SetCurrency default False;
    property MaxValue: Currency read FMaxValue write SetMaxValue;
    property MinValue: Currency read FMinValue write SetMinValue;
    property Precision: Integer read FPrecision write SetPrecision default 0;
    property Size default 4;
  end;

{ TFMTBCDField }

  TFMTBCDField = class(TNumericField)
  private
    FCurrency: Boolean;
    FCheckRange: Boolean;
    FMinValue: String;
    FMaxValue: String;
    FPrecision: Integer;
    procedure BcdRangeError(Value: Variant; Max, Min: String);
    procedure SetCurrency(Value: Boolean);
    procedure SetMaxValue(Value: String);
    procedure SetMinValue(Value: String);
    procedure SetPrecision(Value: Integer);
    procedure UpdateCheckRange;
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure CopyData(Source, Dest: Pointer); override;
    function GetAsCurrency: Currency; override;
    function GetAsBCD: TBcd; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    function GetDefaultWidth: Integer; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    function GetValue(var Value: TBcd): Boolean;
    procedure SetAsCurrency(Value: Currency); override;
    procedure SetAsBCD(const Value: TBcd); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: TBcd read GetAsBCD write SetAsBCD;
  published
    { Lowercase to avoid name clash with C++ Currency type }
    property currency: Boolean read FCurrency write SetCurrency default False;
    property MaxValue: String read FMaxValue write SetMaxValue;
    property MinValue: String read FMinValue write SetMinValue;
    property Precision: Integer read FPrecision write SetPrecision default 0;
    property Size default 4;
  end;



{ TBlobField }

  TBlobType = ftBlob..ftOraClob;

  TBlobField = class(TField)
  private
    FModifiedRecord: Integer;
    FModified: Boolean;
    FGraphicHeader: Boolean;
    FTransliterate: Boolean;
    function GetBlobType: TBlobType;
    function GetModified: Boolean;
    procedure LoadFromBlob(Blob: TBlobField);
    procedure LoadFromStrings(Strings: TStrings);
    procedure LoadFromStreamPersist(StreamPersist: IStreamPersist);
    procedure SaveToStrings(Strings: TStrings);
    procedure SaveToStreamPersist(StreamPersist: IStreamPersist);
    procedure SetBlobType(Value: TBlobType);
    procedure SetModified(Value: Boolean);
    function SupportsStreamPersist(const Persistent: TPersistent;
      var StreamPersist: IStreamPersist): Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure FreeBuffers; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetBlobSize: Integer; virtual;
    function GetClassDesc: string; override;
    function GetIsNull: Boolean; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure SetAsString(const Value: string); override;
    procedure SetText(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    class function IsBlob: Boolean; override;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure SetFieldType(Value: TFieldType); override;
    property BlobSize: Integer read GetBlobSize;
    property Modified: Boolean read GetModified write SetModified;
    property Value: string read GetAsString write SetAsString;
    property Transliterate: Boolean read FTransliterate write FTransliterate;
  published
    property BlobType: TBlobType read GetBlobType write SetBlobType default ftBlob;
    property GraphicHeader: Boolean read FGraphicHeader write FGraphicHeader default True;
    property Size default 0;
  end;

{ TMemoField }

  TMemoField = class(TBlobField)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Transliterate default True;
  end;

{ TGraphicField }

  TGraphicField = class(TBlobField)
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TObjectField }

  TObjectField = class(TField)
  private
    FFields: TFields;
    FOwnedFields: TFields;
    FObjectType: string;
    FTotalSize: Integer;
    FUnNamed: Boolean;
    procedure DataSetChanged;
    procedure ReadUnNamed(Reader: TReader);
    procedure WriteUnNamed(Writer: TWriter);
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure FreeBuffers; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function GetDefaultWidth: Integer; override;
    function GetFieldCount: Integer;
    function GetFields: TFields; virtual;
    function GetFieldValue(Index: Integer): Variant; virtual;
    function GetHasConstraints: Boolean; override;
    procedure SetChildOrder(Component: TComponent; Order: Integer); override;
    procedure SetDataSet(ADataSet: TDataSet); override;
    procedure SetFieldKind(Value: TFieldKind); override;
    procedure SetFieldValue(Index: Integer; const Value: Variant); virtual;
    procedure SetParentField(AField: TObjectField); override;
    procedure SetUnNamed(Value: Boolean);
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property FieldCount: Integer read GetFieldCount;
    property Fields: TFields read GetFields;
    property FieldValues[Index: Integer]: Variant read GetFieldValue
      write SetFieldValue; default;
    property UnNamed: Boolean read FUnNamed default False;
  published
    property ObjectType: string read FObjectType write FObjectType;
  end;

{ TADTField }

  TADTField = class(TObjectField)
  private
    procedure FieldsChanged(Sender: TObject);
  protected
    function GetSize: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TArrayField }

  TArrayField = class(TObjectField)
  protected
    procedure Bind(Binding: Boolean); override;
    procedure SetSize(Value: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Size default 10;
  end;

{ TDataSetField }

  TDataSetField = class(TObjectField)
  private
    FOwnedDataSet: TDataSet;
    FNestedDataSet: TDataSet;
    FIncludeObjectField: Boolean;
    function GetNestedDataSet: TDataSet;
    procedure AssignNestedDataSet(Value: TDataSet);
    procedure SetIncludeObjectField(Value: Boolean);
  protected
    procedure Bind(Binding: Boolean); override;
    function GetCanModify: Boolean; override;
    function GetFields: TFields; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property NestedDataSet: TDataSet read GetNestedDataSet;
  published
    property IncludeObjectField: Boolean read FIncludeObjectField write SetIncludeObjectField default False;
  end;

{ TReferenceField }

  TReferenceField = class(TDataSetField)
  private
    FReferenceTableName: string;
  protected
    function GetAsVariant: Variant; override;
    function GetDataSize: Integer; override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Assign(Source: TPersistent); override;
  published
    property ReferenceTableName: string read FReferenceTableName write FReferenceTableName;
    property Size default 0;
  end;

{ TVariantField }

  TVariantField = class(TField)
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    function GetAsBCD: TBcd; override;
    function GetAsBoolean: Boolean; override;
    function GetAsDateTime: TDateTime; override;
    function GetAsSqlTimeStamp: TSqlTimeStamp; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    function GetDefaultWidth: Integer; override;
    procedure SetAsBCD(const Value: TBcd); override;
    procedure SetAsBoolean(Value: Boolean); override;
    procedure SetAsSqlTimeStamp(const Value: TSqlTimeStamp); override;
    procedure SetAsDateTime(Value: TDateTime); override;
    procedure SetAsFloat(Value: Double); override;
    procedure SetAsInteger(Value: Longint); override;
    procedure SetAsString(const Value: string); override;
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TInterfaceField }

  TInterfaceField = class(TField)
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    function GetValue: IUnknown;
    function GetAsVariant: Variant; override;
    procedure SetValue(const Value: IUnknown);
    procedure SetVarValue(const Value: Variant); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Value: IUnknown read GetValue write SetValue;
  end;

{ TIDispatchField }

  TIDispatchField = class(TInterfaceField)
  protected
    function GetValue: IDispatch;
    procedure SetValue(const Value: IDispatch);
  public
    constructor Create(AOwner: TComponent); override;
    property Value: IDispatch read GetValue write SetValue;
  end;

{ TGuidField }

  TGuidField = class(TStringField)
  protected
    class procedure CheckTypeSize(Value: Integer); override;
    function GetAsGuid: TGUID;
    function GetDefaultWidth: Integer; override;
    procedure SetAsGuid(const Value: TGUID);
  public
    constructor Create(AOwner: TComponent); override;
    property AsGuid: TGUID read GetAsGuid write SetAsGuid;
  end;

{ TAggregateField }

  TAggregateField = class(TField)
  private
    FActive: Boolean;
    FCurrency: Boolean;
    FDisplayName: string;
    FDisplayFormat: string;
    FExpression: string;
    FGroupingLevel: Integer;
    FIndexName: string;
    FHandle: Pointer;
    FPrecision: Integer;
    FResultType: TFieldType;
    procedure SetHandle(Value: Pointer); virtual;
    procedure SetActive(Value: Boolean);
    function GetHandle: Pointer; virtual;
    procedure SetGroupingLevel(Value: Integer);
    procedure SetIndexName(Value: String);
    procedure SetExpression(Value: String);
    procedure SetPrecision(Value: Integer);
    procedure SetCurrency(Value: Boolean);
  protected
    function GetAsString: string; override;
    function GetAsVariant: Variant; override;
    procedure GetText(var Text: string; DisplayText: Boolean); override;
    procedure Reset;
    procedure SetDisplayFormat(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    property Handle: Pointer read GetHandle write SetHandle;
    property ResultType: TFieldType read FResultType write FResultType;
  published
    property Active: Boolean read FActive write SetActive default False;
    { Lowercase to avoid name clash with C++ Currency type }
    property currency: Boolean read FCurrency write SetCurrency default False;
    property DisplayName: String read FDisplayName write FDisplayName;
    property DisplayFormat: string read FDisplayFormat write SetDisplayFormat;
    property Expression: String read FExpression write SetExpression;
    property FieldKind default fkAggregate;
    property GroupingLevel: Integer read FGroupingLevel write SetGroupingLevel default 0;
    property IndexName: String read FIndexName write SetIndexName;
    property Precision: Integer read FPrecision write SetPrecision default 15;
    property Visible default False;
  end;

{ TDataLink }

  TDataLink = class(TPersistent)
  private
    FDataSource: TDataSource;
    FNext: TDataLink;
    FBufferCount: Integer;
    FFirstRecord: Integer;
    FReadOnly: Boolean;
    FActive: Boolean;
    FVisualControl: Boolean;
    FEditing: Boolean;
    FUpdating: Boolean;
    FDataSourceFixed: Boolean;
    function GetDataSet: TDataSet;
    procedure SetActive(Value: Boolean);
    procedure SetDataSource(ADataSource: TDataSource);
    procedure SetEditing(Value: Boolean);
    procedure SetReadOnly(Value: Boolean);
    procedure UpdateRange;
    procedure UpdateState;
  protected
    procedure ActiveChanged; virtual;
    procedure CheckBrowseMode; virtual;
    procedure DataEvent(Event: TDataEvent; Info: Longint); virtual;
    procedure DataSetChanged; virtual;
    procedure DataSetScrolled(Distance: Integer); virtual;
    procedure EditingChanged; virtual;
    procedure FocusControl(Field: TFieldRef); virtual;
    function GetActiveRecord: Integer; virtual;
    function GetBOF: Boolean; virtual;
    function GetBufferCount: Integer; virtual;
    function GetEOF: Boolean; virtual;
    function GetRecordCount: Integer; virtual;
    procedure LayoutChanged; virtual;
    function MoveBy(Distance: Integer): Integer; virtual;
    procedure RecordChanged(Field: TField); virtual;
    procedure SetActiveRecord(Value: Integer); virtual;
    procedure SetBufferCount(Value: Integer); virtual;
    procedure UpdateData; virtual;
    property VisualControl: Boolean read FVisualControl write FVisualControl;
  public
    constructor Create;
    destructor Destroy; override;
    function Edit: Boolean;
    function ExecuteAction(Action: TBasicAction): Boolean; dynamic;
    function UpdateAction(Action: TBasicAction): Boolean; dynamic;
    procedure UpdateRecord;
    property Active: Boolean read FActive;
    property ActiveRecord: Integer read GetActiveRecord write SetActiveRecord;
    property BOF: Boolean read GetBOF;
    property BufferCount: Integer read FBufferCount write SetBufferCount;
    property DataSet: TDataSet read GetDataSet;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property DataSourceFixed: Boolean read FDataSourceFixed write FDataSourceFixed;
    property Editing: Boolean read FEditing;
    property Eof: Boolean read GetEOF;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property RecordCount: Integer read GetRecordCount;
  end;

{ TDetailDataLink }

  TDetailDataLink = class(TDataLink)
  protected
    function GetDetailDataSet: TDataSet; virtual;
  public
    property DetailDataSet: TDataSet read GetDetailDataSet;
  end;

{ TMasterDataLink }

  TMasterDataLink = class(TDetailDataLink)
  private
    FDataSet: TDataSet;
    FFieldNames: string;
    FFields: TList;
    FOnMasterChange: TNotifyEvent;
    FOnMasterDisable: TNotifyEvent;
    procedure SetFieldNames(const Value: string);
  protected
    procedure ActiveChanged; override;
    procedure CheckBrowseMode; override;
    function GetDetailDataSet: TDataSet; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(DataSet: TDataSet);
    destructor Destroy; override;
    property FieldNames: string read FFieldNames write SetFieldNames;
    property Fields: TList read FFields;
    property OnMasterChange: TNotifyEvent read FOnMasterChange write FOnMasterChange;
    property OnMasterDisable: TNotifyEvent read FOnMasterDisable write FOnMasterDisable;
  end;

{ TDataSource }

  TDataChangeEvent = procedure(Sender: TObject; Field: TField) of object;

  TDataSource = class(TComponent)
  private
    FDataSet: TDataSet;
    FDataLinks: TList;
    FEnabled: Boolean;
    FAutoEdit: Boolean;
    FState: TDataSetState;
    FOnStateChange: TNotifyEvent;
    FOnDataChange: TDataChangeEvent;
    FOnUpdateData: TNotifyEvent;
    procedure AddDataLink(DataLink: TDataLink);
    procedure DataEvent(Event: TDataEvent; Info: Longint);
    procedure NotifyDataLinks(Event: TDataEvent; Info: Longint);
    procedure NotifyLinkTypes(Event: TDataEvent; Info: Longint; LinkType: Boolean);
    procedure RemoveDataLink(DataLink: TDataLink);
    procedure SetDataSet(ADataSet: TDataSet);
    procedure SetEnabled(Value: Boolean);
    procedure SetState(Value: TDataSetState);
    procedure UpdateState;
  protected
    property DataLinks: TList read FDataLinks;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Edit;
    function IsLinkedTo(DataSet: TDataSet): Boolean;
    property State: TDataSetState read FState;
  published
    property AutoEdit: Boolean read FAutoEdit write FAutoEdit default True;
    property DataSet: TDataSet read FDataSet write SetDataSet;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    property OnDataChange: TDataChangeEvent read FOnDataChange write FOnDataChange;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
  end;

{ TDataSetDesigner }

  TDataSetDesigner = class(TObject)
  private
    FDataSet: TDataSet;
    FSaveActive: Boolean;
  public
    constructor Create(DataSet: TDataSet);
    destructor Destroy; override;
    procedure BeginDesign;
    procedure DataEvent(Event: TDataEvent; Info: Longint); virtual;
    procedure EndDesign;
    property DataSet: TDataSet read FDataSet;
  end;

{ TCheckConstraint }

  TCheckConstraint = class(TCollectionItem)
  private
    FImportedConstraint: string;
    FCustomConstraint: string;
    FErrorMessage: string;
    FFromDictionary: Boolean;
    procedure SetImportedConstraint(const Value: string);
    procedure SetCustomConstraint(const Value: string);
    procedure SetErrorMessage(const Value: string);
  public
    procedure Assign(Source: TPersistent); override;
    function GetDisplayName: string; override;
  published
    property CustomConstraint: string read FCustomConstraint write SetCustomConstraint;
    property ErrorMessage: string read FErrorMessage write SetErrorMessage;
    property FromDictionary: Boolean read FFromDictionary write FFromDictionary;
    property ImportedConstraint: string read FImportedConstraint write SetImportedConstraint;
  end;

{ TCheckConstraints }

  TCheckConstraints = class(TCollection)
  private
    FOwner: TPersistent;
    function GetItem(Index: Integer): TCheckConstraint;
    procedure SetItem(Index: Integer; Value: TCheckConstraint);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(Owner: TPersistent);
    function Add: TCheckConstraint;
    property Items[Index: Integer]: TCheckConstraint read GetItem write SetItem; default;
  end;

{ TParam }

  TBlobData = string;

  TParamType = (ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult);
  TParamTypes = set of TParamType;

  TParams = class;

  TParam = class(TCollectionItem)
  private
    FParamRef: TParam;
    FNativeStr: string;
    FData: Variant;
    FPrecision: Integer;
    FNumericScale: Integer;
    FNull: Boolean;
    FName: string;
    FDataType: TFieldType;
    FBound: Boolean;
    FParamType: TParamType;
    FSize: Integer;
    function ParamRef: TParam;
    function GetDataSet: TDataSet;
    function IsParamStored: Boolean;
    function GetDataType: TFieldType;
    function GetParamType: TParamType;
    procedure SetParamType(Value: TParamType);
  protected
    procedure AssignParam(Param: TParam);
    procedure AssignTo(Dest: TPersistent); override;
    function GetAsFMTBCD: TBcd;
    function GetAsBCD: Currency;
    function GetAsBoolean: Boolean;
    function GetAsDateTime: TDateTime;
    function GetAsSQLTimeStamp: TSQLTimeStamp;
    function GetAsCurrency: Currency;
    function GetAsFloat: Double;
    function GetAsInteger: Longint;
    function GetAsMemo: string;
    function GetAsString: string;
    function GetAsVariant: Variant;
    function GetIsNull: Boolean;
    function IsEqual(Value: TParam): Boolean;
    procedure SetAsBCD(const Value: Currency);
    procedure SetAsFMTBCD(const Value: TBcd);
    procedure SetAsBlob(const Value: TBlobData);
    procedure SetAsBoolean(Value: Boolean);
    procedure SetAsCurrency(const Value: Currency);
    procedure SetAsDate(const Value: TDateTime);
    procedure SetAsDateTime(const Value: TDateTime);
    procedure SetAsSQLTimeStamp(const Value: TSQLTimeStamp);
    procedure SetAsFloat(const Value: Double);
    procedure SetAsInteger(Value: Longint);
    procedure SetAsMemo(const Value: string);
    procedure SetAsString(const Value: string);
    procedure SetAsSmallInt(Value: LongInt);
    procedure SetAsTime(const Value: TDateTime);
    procedure SetAsVariant(const Value: Variant);
    procedure SetAsWord(Value: LongInt);
    procedure SetDataType(Value: TFieldType);
    procedure SetText(const Value: string);
    function GetDisplayName: string; override;
    property DataSet: TDataSet read GetDataSet;
  public
    constructor Create(Collection: TCollection); overload; override;
    constructor Create(AParams: TParams; AParamType: TParamType); reintroduce; overload;
    procedure Assign(Source: TPersistent); override;
    procedure AssignField(Field: TField);
    procedure AssignFieldValue(Field: TField; const Value: Variant);
    procedure Clear;
    procedure GetData(Buffer: Pointer);
    function GetDataSize: Integer;
    procedure LoadFromFile(const FileName: string; BlobType: TBlobType);
    procedure LoadFromStream(Stream: TStream; BlobType: TBlobType);
    procedure SetBlobData(Buffer: Pointer; Size: Integer);
    procedure SetData(Buffer: Pointer);
    property AsBCD: Currency read GetAsBCD write SetAsBCD;
    property AsFMTBCD: TBcd read GetAsFMTBCD write SetAsFMTBCD;
    property AsBlob: TBlobData read GetAsString write SetAsBlob;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
    property AsDate: TDateTime read GetAsDateTime write SetAsDate;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsInteger: LongInt read GetAsInteger write SetAsInteger;
    property AsSmallInt: LongInt read GetAsInteger write SetAsSmallInt;
    property AsSQLTimeStamp: TSQLTimeStamp read GetAsSQLTimeStamp write SetAsSQLTimeStamp;
    property AsMemo: string read GetAsMemo write SetAsMemo;
    property AsString: string read GetAsString write SetAsString;
    property AsTime: TDateTime read GetAsDateTime write SetAsTime;
    property AsWord: LongInt read GetAsInteger write SetAsWord;
    property Bound: Boolean read FBound write FBound;
    property IsNull: Boolean read GetIsNull;
    property NativeStr: string read FNativeStr write FNativeStr;
    property Text: string read GetAsString write SetText;
  published
    property DataType: TFieldType read GetDataType write SetDataType;
    property Precision: Integer read FPrecision write FPrecision default 0;
    property NumericScale: Integer read FNumericScale write FNumericScale default 0;
    property Name: string read FName write FName;
    property ParamType: TParamType read GetParamType write SetParamType;
    property Size: Integer read FSize write FSize default 0;
    property Value: Variant read GetAsVariant write SetAsVariant stored IsParamStored;
  end;

{ TParams }

  TParams = class(TCollection)
  private
    FOwner: TPersistent;
    function GetParamValue(const ParamName: string): Variant;
    procedure ReadBinaryData(Stream: TStream);
    procedure SetParamValue(const ParamName: string;
      const Value: Variant);
    function GetItem(Index: Integer): TParam;
    procedure SetItem(Index: Integer; Value: TParam);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DefineProperties(Filer: TFiler); override;
    function GetDataSet: TDataSet;
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(Owner: TPersistent); overload;
    procedure AssignValues(Value: TParams);
    { Create, AddParam, RemoveParam and CreateParam are in for backward compatibility }
    constructor Create; overload;
    procedure AddParam(Value: TParam);
    procedure RemoveParam(Value: TParam);
    function CreateParam(FldType: TFieldType; const ParamName: string;
      ParamType: TParamType): TParam;
    procedure GetParamList(List: TList; const ParamNames: string);
    function IsEqual(Value: TParams): Boolean;
    function ParseSQL(SQL: String; DoCreate: Boolean): String;
    function ParamByName(const Value: string): TParam;
    function FindParam(const Value: string): TParam;
    property Items[Index: Integer]: TParam read GetItem write SetItem; default;
    property ParamValues[const ParamName: string]: Variant read GetParamValue write SetParamValue;
  end;

{ IProviderSupport interface }

  IProviderSupport = interface
  ['{7AF8F684-0660-47B5-A1B3-E168D2ACB908}']
    procedure PSEndTransaction(Commit: Boolean);
    procedure PSExecute;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      ResultSet: Pointer = nil): Integer;
    procedure PSGetAttributes(List: TList);
    function PSGetDefaultOrder: TIndexDef;
    function PSGetKeyFields: string;
    function PSGetParams: TParams;
    function PSGetQuoteChar: string;
    function PSGetTableName: string;
    function PSGetIndexDefs(IndexTypes: TIndexOptions = [ixPrimary..ixNonMaintained]): TIndexDefs;
    function PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError;
    function PSInTransaction: Boolean;
    function PSIsSQLBased: Boolean;
    function PSIsSQLSupported: Boolean;
    procedure PSReset;
    procedure PSSetParams(AParams: TParams);
    procedure PSSetCommandText(const CommandText: string);
    procedure PSStartTransaction;
    function PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean;
  end;

{ TDataSet }

  TBookmark = Pointer;
  TBookmarkStr = string;

  PBookmarkFlag = ^TBookmarkFlag;
  TBookmarkFlag = (bfCurrent, bfBOF, bfEOF, bfInserted);

  TBufferList = array of PChar;

  TGetMode = (gmCurrent, gmNext, gmPrior);

  TGetResult = (grOK, grBOF, grEOF, grError);

  TResyncMode = set of (rmExact, rmCenter);

  TDataAction = (daFail, daAbort, daRetry);

  TBlobStreamMode = (bmRead, bmWrite, bmReadWrite);

  TLocateOption = (loCaseInsensitive, loPartialKey);
  TLocateOptions = set of TLocateOption;

  TDataOperation = procedure of object;

  TDataSetNotifyEvent = procedure(DataSet: TDataSet) of object;
  TDataSetErrorEvent = procedure(DataSet: TDataSet; E: EDatabaseError;
    var Action: TDataAction) of object;

  TFilterOption = (foCaseInsensitive, foNoPartialCompare);
  TFilterOptions = set of TFilterOption;

  TFilterRecordEvent = procedure(DataSet: TDataSet;
    var Accept: Boolean) of object;

  PPacketAttribute = ^TPacketAttribute;
  TPacketAttribute = record
    Name: string;
    Value: OleVariant;
    IncludeInDelta: Boolean;
  end;

  TBlobByteData = array of Byte;

  TGroupPosInd = (gbFirst, gbMiddle, gbLast);
  TGroupPosInds = set of TGroupPosInd;

  TDataSet = class(TComponent, IProviderSupport)
  private
    FFields: TFields;
    FAggFields: TFields;
    FFieldDefs: TFieldDefs;
    FFieldDefList: TFieldDefList;
    FFieldList: TFieldList;
    FDataSources: TList;
    FFirstDataLink: TDataLink;
    FBufferCount: Integer;
    FRecordCount: Integer;
    FActiveRecord: Integer;
    FCurrentRecord: Integer;
    FBuffers: TBufferList;
    FCalcBuffer: PChar;
    FBookmarkSize: Integer;
    FCalcFieldsSize: Integer;
    FDesigner: TDataSetDesigner;
    FDisableCount: Integer;
    FBlobFieldCount: Integer;
    FFilterText: string;
    FBlockReadSize: Integer;
    FConstraints: TCheckConstraints;
    FDataSetField: TDataSetField;
    FIsUniDirectional: Boolean;
    FNestedDataSets: TList;
    FNestedDatasetClass: TClass;
    FReserved: Pointer;
    FFieldNoOfs: Integer;
    { Byte sized data members (for alignment) }
    FFilterOptions: TFilterOptions;
    FState: TDataSetState;
    FEnableEvent: TDataEvent;
    FDisableState: TDataSetState;
    FBOF: Boolean;
    FEOF: Boolean;
    FModified: Boolean;
    FStreamedActive: Boolean;
    FInternalCalcFields: Boolean;
    FFound: Boolean;
    FDefaultFields: Boolean;
    FAutoCalcFields: Boolean;
    FFiltered: Boolean;
    FObjectView: Boolean;
    FSparseArrays: Boolean;
    FInternalOpenComplete: Boolean;
    { Events }
    FBeforeOpen: TDataSetNotifyEvent;
    FAfterOpen: TDataSetNotifyEvent;
    FBeforeClose: TDataSetNotifyEvent;
    FAfterClose: TDataSetNotifyEvent;
    FBeforeInsert: TDataSetNotifyEvent;
    FAfterInsert: TDataSetNotifyEvent;
    FBeforeEdit: TDataSetNotifyEvent;
    FAfterEdit: TDataSetNotifyEvent;
    FBeforePost: TDataSetNotifyEvent;
    FAfterPost: TDataSetNotifyEvent;
    FBeforeCancel: TDataSetNotifyEvent;
    FAfterCancel: TDataSetNotifyEvent;
    FBeforeDelete: TDataSetNotifyEvent;
    FAfterDelete: TDataSetNotifyEvent;
    FBeforeRefresh: TDataSetNotifyEvent;
    FAfterRefresh: TDataSetNotifyEvent;
    FBeforeScroll: TDataSetNotifyEvent;
    FAfterScroll: TDataSetNotifyEvent;
    FOnNewRecord: TDataSetNotifyEvent;
    FOnCalcFields: TDataSetNotifyEvent;
    FOnEditError: TDataSetErrorEvent;
    FOnPostError: TDataSetErrorEvent;
    FOnDeleteError: TDataSetErrorEvent;
    FOnFilterRecord: TFilterRecordEvent;
    procedure AddDataSource(DataSource: TDataSource);
    procedure AddRecord(const Values: array of const; Append: Boolean);
    procedure BeginInsertAppend;
    procedure CheckCanModify;
    procedure CheckOperation(Operation: TDataOperation;
      ErrorEvent: TDataSetErrorEvent);
    procedure CheckParentState;
    procedure CheckRequiredFields;
    procedure DoInternalOpen;
    procedure EndInsertAppend;
    function GetActive: Boolean;
    function GetBuffer(Index: Integer): PChar;
    function GetFieldCount: Integer;
    function GetFieldValue(const FieldName: string): Variant;
    function GetFound: Boolean;
    function GetNestedDataSets: TList;
    procedure MoveBuffer(CurIndex, NewIndex: Integer);
    procedure RemoveDataSource(DataSource: TDataSource);
    procedure SetBufferCount(Value: Integer);
    procedure SetConstraints(Value: TCheckConstraints);
    procedure SetFieldDefs(Value: TFieldDefs);
    procedure SetFieldValue(const FieldName: string; const Value: Variant);
    procedure SetSparseArrays(Value: Boolean);
  protected
    { IProviderSupport }
    procedure PSEndTransaction(Commit: Boolean); virtual;
    procedure PSExecute; virtual;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      ResultSet: Pointer = nil): Integer; virtual;
    procedure PSGetAttributes(List: TList); virtual;
    function PSGetDefaultOrder: TIndexDef; virtual;
    function PSGetKeyFields: string; virtual;
    function PSGetParams: TParams; virtual;
    function PSGetQuoteChar: string; virtual;
    function PSGetTableName: string; virtual;
    function PSGetIndexDefs(IndexTypes: TIndexOptions): TIndexDefs; virtual;
    function PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError; virtual;
    function PSInTransaction: Boolean; virtual;
    function PSIsSQLBased: Boolean; virtual;
    function PSIsSQLSupported: Boolean; virtual;
    procedure PSReset; virtual;
    procedure PSSetParams(AParams: TParams); virtual;
    procedure PSSetCommandText(const CommandText: string); virtual;
    procedure PSStartTransaction; virtual;
    function PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean; virtual;
  protected
    procedure ResetAggField(Field: TField); virtual;
    procedure BindFields(Binding: Boolean);
    function BookmarkAvailable: Boolean;
    procedure CalculateFields(Buffer: PChar); virtual;
    procedure CheckActive; virtual;
    procedure CheckBiDirectional;
    procedure CheckFieldCompatibility(Field: TField; FieldDef: TFieldDef); virtual;
    procedure CheckInactive; virtual;
    procedure ClearBuffers; virtual;
    procedure ClearCalcFields(Buffer: PChar); virtual;
    procedure CloseBlob(Field: TField); virtual;
    procedure CloseCursor; virtual;
    procedure CreateFields; virtual;
    function CreateNestedDataSet(DataSetField: TDataSetField): TDataSet; virtual;
    procedure DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean); virtual;
    procedure DataEvent(Event: TDataEvent; Info: Longint); virtual;
    procedure DefChanged(Sender: TObject); virtual;
    procedure DestroyFields; virtual;
    procedure DoAfterCancel; virtual;
    procedure DoAfterClose; virtual;
    procedure DoAfterDelete; virtual;
    procedure DoAfterEdit; virtual;
    procedure DoAfterInsert; virtual;
    procedure DoAfterOpen; virtual;
    procedure DoAfterPost; virtual;
    procedure DoAfterRefresh; virtual;
    procedure DoAfterScroll; virtual;
    procedure DoBeforeCancel; virtual;
    procedure DoBeforeClose; virtual;
    procedure DoBeforeDelete; virtual;
    procedure DoBeforeEdit; virtual;
    procedure DoBeforeInsert; virtual;
    procedure DoBeforeOpen; virtual;
    procedure DoBeforePost; virtual;
    procedure DoBeforeRefresh; virtual;
    procedure DoBeforeScroll; virtual;
    procedure DoOnCalcFields; virtual;
    procedure DoOnNewRecord; virtual;
    function FieldByNumber(FieldNo: Integer): TField;
    function FindRecord(Restart, GoForward: Boolean): Boolean; virtual;
    procedure FreeFieldBuffers; virtual;
    function GetAggregateValue(Field: TField): Variant; virtual;
    function GetAggRecordCount(Grp: TGroupPosInd): Integer; virtual;
    procedure ActivateBuffers; virtual;
    function GetBookmarkStr: TBookmarkStr; virtual;
    procedure GetCalcFields(Buffer: PChar); virtual;
    function GetCanModify: Boolean; virtual;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function GetDataSource: TDataSource; virtual;
    function GetFieldClass(FieldType: TFieldType): TFieldClass; virtual;
    function GetFieldFullName(Field: TField): string; virtual;
    function GetStateFieldValue(State: TDataSetState; Field: TField): Variant; virtual;
    function GetIsIndexField(Field: TField): Boolean; virtual;
    function GetIndexDefs(IndexDefs: TIndexDefs; IndexTypes: TIndexOptions): TIndexDefs;
    function GetNextRecords: Integer; virtual;
    function GetNextRecord: Boolean; virtual;
    function GetPriorRecords: Integer; virtual;
    function GetPriorRecord: Boolean; virtual;
    function GetRecordCount: Integer; virtual;
    function GetRecNo: Integer; virtual;
    procedure InitFieldDefs; virtual;
    procedure InitFieldDefsFromFields;
    procedure InitRecord(Buffer: PChar); virtual;
    procedure InternalCancel; virtual;
    procedure InternalEdit; virtual;
    procedure InternalInsert; virtual;
    procedure InternalRefresh; virtual;
    procedure Loaded; override;
    procedure OpenCursor(InfoQuery: Boolean = False); virtual;
    procedure OpenCursorComplete;
    procedure OpenParentDataSet(ParentDataSet: TDataSet);
    procedure RefreshInternalCalcFields(Buffer: PChar); virtual;
    procedure RestoreState(const Value: TDataSetState);
    procedure BlockReadNext; virtual;
    procedure SetActive(Value: Boolean); virtual;
    procedure SetBookmarkStr(const Value: TBookmarkStr); virtual;
    procedure SetBlockReadSize(Value: Integer); virtual;
    procedure SetBufListSize(Value: Integer); virtual;
    procedure SetChildOrder(Component: TComponent; Order: Integer); override;
    procedure SetCurrentRecord(Index: Integer); virtual;
    procedure SetDataSetField(const Value: TDataSetField); virtual;
    procedure SetDefaultFields(const Value: Boolean);
    procedure SetFiltered(Value: Boolean); virtual;
    procedure SetFilterOptions(Value: TFilterOptions); virtual;
    procedure SetFilterText(const Value: string); virtual;
    procedure SetFound(const Value: Boolean);
    procedure SetModified(Value: Boolean);
    procedure SetName(const Value: TComponentName); override;
    procedure SetObjectView(const Value: Boolean);
    procedure SetOnFilterRecord(const Value: TFilterRecordEvent); virtual;
    procedure SetRecNo(Value: Integer); virtual;
    procedure SetState(Value: TDataSetState);
    procedure SetStateFieldValue(State: TDataSetState; Field: TField; const Value: Variant); virtual;
    function SetTempState(const Value: TDataSetState): TDataSetState;
    procedure SetUniDirectional(const Value: Boolean);
    function TempBuffer: PChar;
    procedure UpdateBufferCount;
    procedure UpdateIndexDefs; virtual;
    property ActiveRecord: Integer read FActiveRecord;
    property CurrentRecord: Integer read FCurrentRecord;
    property BlobFieldCount: Integer read FBlobFieldCount;
    property BookmarkSize: Integer read FBookmarkSize write FBookmarkSize;
    property Buffers[Index: Integer]: PChar read GetBuffer;
    property BufferCount: Integer read FBufferCount;
    property CalcBuffer: PChar read FCalcBuffer;
    property CalcFieldsSize: Integer read FCalcFieldsSize;
    property Constraints: TCheckConstraints read FConstraints write SetConstraints;
    property FieldNoOfs: Integer read FFieldNoOfs write FFieldNoOfs;
    property InternalCalcFields: Boolean read FInternalCalcFields;
    property NestedDataSets: TList read GetNestedDataSets;
    property NestedDataSetClass: TClass read FNestedDataSetClass write FNestedDataSetClass;
    property Reserved: Pointer read FReserved write FReserved;
  protected { Method stubs for UniDirectional/Readonly/Unbuffered datasets }
    function AllocRecordBuffer: PChar; virtual;
    procedure FreeRecordBuffer(var Buffer: PChar); virtual;
    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); virtual;
    function GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; virtual;
    function GetRecordSize: Word; virtual;
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); virtual;
    procedure InternalDelete; virtual;
    procedure InternalFirst; virtual;
    procedure InternalGotoBookmark(Bookmark: Pointer); virtual;
    procedure InternalInitRecord(Buffer: PChar); virtual;
    procedure InternalLast; virtual;
    procedure InternalPost; virtual;
    procedure InternalSetToRecord(Buffer: PChar); virtual;
    procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag); virtual;
    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); virtual;
    procedure SetFieldData(Field: TField; Buffer: Pointer); overload; virtual;
    procedure SetFieldData(Field: TField; Buffer: Pointer; NativeFormat: Boolean); overload; virtual;
  protected { abstract methods required for all datasets }
    function GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean): TGetResult; virtual; abstract;
    procedure InternalClose; virtual; abstract;
    procedure InternalHandleException; virtual; abstract;
    procedure InternalInitFieldDefs; virtual; abstract;
    procedure InternalOpen; virtual; abstract;
    function IsCursorOpen: Boolean; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ActiveBuffer: PChar;
    procedure Append;
    procedure AppendRecord(const Values: array of const);
    function BookmarkValid(Bookmark: TBookmark): Boolean; virtual;
    procedure Cancel; virtual;
    procedure CheckBrowseMode;
    procedure ClearFields;
    procedure Close;
    function  ControlsDisabled: Boolean;
    function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; virtual;
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream; virtual;
    procedure CursorPosChanged;
    procedure Delete;
    procedure DisableControls;
    procedure Edit;
    procedure EnableControls;
    function FieldByName(const FieldName: string): TField;
    function FindField(const FieldName: string): TField;
    function FindFirst: Boolean;
    function FindLast: Boolean;
    function FindNext: Boolean;
    function FindPrior: Boolean;
    procedure First;
    procedure FreeBookmark(Bookmark: TBookmark); virtual;
    function GetBookmark: TBookmark; virtual;
    function GetCurrentRecord(Buffer: PChar): Boolean; virtual;
    procedure GetDetailDataSets(List: TList); virtual;
    procedure GetDetailLinkFields(MasterFields, DetailFields: TList); virtual;
    function GetBlobFieldData(FieldNo: Integer; var Buffer: TBlobByteData): Integer; virtual;
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; overload; virtual;
    function GetFieldData(FieldNo: Integer; Buffer: Pointer): Boolean; overload; virtual;
    function GetFieldData(Field: TField; Buffer: Pointer; NativeFormat: Boolean): Boolean; overload; virtual;
    procedure GetFieldList(List: TList; const FieldNames: string);
    procedure GetFieldNames(List: TStrings); virtual;
    procedure GotoBookmark(Bookmark: TBookmark);
    procedure Insert;
    procedure InsertRecord(const Values: array of const);
    function IsEmpty: Boolean;
    function IsLinkedTo(DataSource: TDataSource): Boolean;
    function IsSequenced: Boolean; virtual;
    procedure Last;
    function Locate(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; virtual;
    function Lookup(const KeyFields: string; const KeyValues: Variant;
      const ResultFields: string): Variant; virtual;
    function MoveBy(Distance: Integer): Integer;
    procedure Next;
    procedure Open;
    procedure Post; virtual;
    procedure Prior;
    procedure Refresh;
    procedure Resync(Mode: TResyncMode); virtual;
    procedure SetFields(const Values: array of const);
    function Translate(Src, Dest: PChar; ToOem: Boolean): Integer; virtual;
    procedure UpdateCursorPos;
    procedure UpdateRecord;
    function UpdateStatus: TUpdateStatus; virtual;
    property AggFields: TFields read FAggFields;
    property Bof: Boolean read FBOF;
    property Bookmark: TBookmarkStr read GetBookmarkStr write SetBookmarkStr;
    property CanModify: Boolean read GetCanModify;
    property DataSetField: TDataSetField read FDataSetField write SetDataSetField;
    property DataSource: TDataSource read GetDataSource;
    property DefaultFields: Boolean read FDefaultFields;
    property Designer: TDataSetDesigner read FDesigner;
    property Eof: Boolean read FEOF; {Upper case EOF conflicts with C++}
    property BlockReadSize: Integer read FBlockReadSize write SetBlockReadSize;
    property FieldCount: Integer read GetFieldCount;
    property FieldDefs: TFieldDefs read FFieldDefs write SetFieldDefs;
    property FieldDefList: TFieldDefList read FFieldDefList;
    property Fields: TFields read FFields;
    property FieldList: TFieldList read FFieldList;
    property FieldValues[const FieldName: string]: Variant read GetFieldValue write SetFieldValue; default;
    property Found: Boolean read GetFound;
    property IsUniDirectional: Boolean read FIsUniDirectional default False;
    property Modified: Boolean read FModified;
    property ObjectView: Boolean read FObjectView write SetObjectView;
    property RecordCount: Integer read GetRecordCount;
    property RecNo: Integer read GetRecNo write SetRecNo;
    property RecordSize: Word read GetRecordSize;
    property SparseArrays: Boolean read FSparseArrays write SetSparseArrays;
    property State: TDataSetState read FState;
    property Filter: string read FFilterText write SetFilterText;
    property Filtered: Boolean read FFiltered write SetFiltered default False;
    property FilterOptions: TFilterOptions read FFilterOptions write SetFilterOptions default [];
    property Active: Boolean read GetActive write SetActive default False;
    property AutoCalcFields: Boolean read FAutoCalcFields write FAutoCalcFields default True;
    property BeforeOpen: TDataSetNotifyEvent read FBeforeOpen write FBeforeOpen;
    property AfterOpen: TDataSetNotifyEvent read FAfterOpen write FAfterOpen;
    property BeforeClose: TDataSetNotifyEvent read FBeforeClose write FBeforeClose;
    property AfterClose: TDataSetNotifyEvent read FAfterClose write FAfterClose;
    property BeforeInsert: TDataSetNotifyEvent read FBeforeInsert write FBeforeInsert;
    property AfterInsert: TDataSetNotifyEvent read FAfterInsert write FAfterInsert;
    property BeforeEdit: TDataSetNotifyEvent read FBeforeEdit write FBeforeEdit;
    property AfterEdit: TDataSetNotifyEvent read FAfterEdit write FAfterEdit;
    property BeforePost: TDataSetNotifyEvent read FBeforePost write FBeforePost;
    property AfterPost: TDataSetNotifyEvent read FAfterPost write FAfterPost;
    property BeforeCancel: TDataSetNotifyEvent read FBeforeCancel write FBeforeCancel;
    property AfterCancel: TDataSetNotifyEvent read FAfterCancel write FAfterCancel;
    property BeforeDelete: TDataSetNotifyEvent read FBeforeDelete write FBeforeDelete;
    property AfterDelete: TDataSetNotifyEvent read FAfterDelete write FAfterDelete;
    property BeforeScroll: TDataSetNotifyEvent read FBeforeScroll write FBeforeScroll;
    property AfterScroll: TDataSetNotifyEvent read FAfterScroll write FAfterScroll;
    property BeforeRefresh: TDataSetNotifyEvent read FBeforeRefresh write FBeforeRefresh;
    property AfterRefresh: TDataSetNotifyEvent read FAfterRefresh write FAfterRefresh;
    property OnCalcFields: TDataSetNotifyEvent read FOnCalcFields write FOnCalcFields;
    property OnDeleteError: TDataSetErrorEvent read FOnDeleteError write FOnDeleteError;
    property OnEditError: TDataSetErrorEvent read FOnEditError write FOnEditError;
    property OnFilterRecord: TFilterRecordEvent read FOnFilterRecord write SetOnFilterRecord;
    property OnNewRecord: TDataSetNotifyEvent read FOnNewRecord write FOnNewRecord;
    property OnPostError: TDataSetErrorEvent read FOnPostError write FOnPostError;
  end;

{ TDateTimeRec }

type
  TDateTimeAlias = type TDateTime;
  {$NODEFINE TDateTimeAlias}
  (*$HPPEMIT 'namespace Db'*)
  (*$HPPEMIT '{'*)
  (*$HPPEMIT '    typedef TDateTimeBase TDateTimeAlias;'*)
  (*$HPPEMIT '}'*)
  TDateTimeRec = record
    case TFieldType of
      ftDate: (Date: Longint);
      ftTime: (Time: Longint);
      ftDateTime: (DateTime: TDateTimeAlias);
  end;

const
  { The following field types do not support assignment as text, unless the
    field object's OnSetText event is assigned to perform the text to
    binary conversion. }
  ftNonTextTypes = [ftBytes, ftVarBytes, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftADT, ftArray,
    ftReference, ftDataSet];

  { Field types with a fixed size.  TField.Size = 0 for all of these }
  ftFixedSizeTypes = [ftSmallint, ftInteger, ftWord, ftBoolean, ftFloat,
    ftCurrency, ftDate, ftTime, ftDateTime, ftAutoInc, ftLargeint, ftTimeStamp];

  dsEditModes = [dsEdit, dsInsert, dsSetKey];
  dsWriteModes = [dsEdit, dsInsert, dsSetKey, dsCalcFields, dsFilter,
    dsNewValue, dsInternalCalc];

var
  DefaultFieldClasses: array[TFieldType] of TFieldClass = (
    nil,                { ftUnknown }
    TStringField,       { ftString }
    TSmallintField,     { ftSmallint }
    TIntegerField,      { ftInteger }
    TWordField,         { ftWord }
    TBooleanField,      { ftBoolean }
    TFloatField,        { ftFloat }
    TCurrencyField,     { ftCurrency }
    TBCDField,          { ftBCD }
    TDateField,         { ftDate }
    TTimeField,         { ftTime }
    TDateTimeField,     { ftDateTime }
    TBytesField,        { ftBytes }
    TVarBytesField,     { ftVarBytes }
    TAutoIncField,      { ftAutoInc }
    TBlobField,         { ftBlob }
    TMemoField,         { ftMemo }
    TGraphicField,      { ftGraphic }
    TBlobField,         { ftFmtMemo }
    TBlobField,         { ftParadoxOle }
    TBlobField,         { ftDBaseOle }
    TBlobField,         { ftTypedBinary }
    nil,                { ftCursor }
    TStringField,       { ftFixedChar }
    TWideStringField,   { ftWideString }
    TLargeIntField,     { ftLargeInt }
    TADTField,          { ftADT }
    TArrayField,        { ftArray }
    TReferenceField,    { ftReference }
    TDataSetField,      { ftDataSet }
    TBlobField,         { ftOraBlob }
    TMemoField,         { ftOraClob }
    TVariantField,      { ftVariant }
    TInterfaceField,    { ftInterface }
    TIDispatchField,    { ftIDispatch }
    TGuidField,         { ftGuid }
    TSQLTimeStampField, { ftTimeStamp }
    TFMTBcdField);      { ftTimeStamp }

const
    
  FieldTypeNames: array[TFieldType] of string = (
    'Unknown', 'String', 'SmallInt', 'Integer', 'Word', 'Boolean', 'Float',
    'Currency', 'BCD', 'Date', 'Time', 'DateTime', 'Bytes', 'VarBytes',
    'AutoInc', 'Blob', 'Memo', 'Graphic', 'FmtMemo', 'ParadoxOle',
    'dBaseOle', 'TypedBinary', 'Cursor', 'FixedChar', 'WideString',
    'LargeInt', 'ADT', 'Array', 'Reference', 'DataSet', 'HugeBlob', 'HugeClob',
    'Variant', 'Interface', 'Dispatch', 'Guid', 'SQLTimeStamp', 'FMTBcdField');

  FieldTypeVarMap: array[TFieldType] of Word = (
    varEmpty, varString, varInteger, varInteger, varInteger,
    varBoolean, varDouble, varCurrency, varCurrency, varDate, varDate, varDate,
    varEmpty, varEmpty, varInteger, varEmpty, varString, varEmpty,
    varEmpty, varEmpty, varEmpty, varEmpty, varEmpty, varString, varOleStr,
    varEmpty, varEmpty, varEmpty, varEmpty, varEmpty, varEmpty, varEmpty,
    varVariant, varUnknown, varDispatch, varString, varEmpty, varEmpty);

  ObjectFieldTypes = [ftADT, ftArray, ftReference, ftDataSet];

  dsMaxStringSize = 8192; { Maximum string field size }
  RegisterFieldsProc: procedure(const FieldClassess: array of TFieldClass) = nil;

type
  TDBScreenCursor = (dcrDefault, dcrHourGlass, dcrSQLWait, dcrOther);

  IDBScreen = interface
    ['{29A1C508-6ADC-44CD-88DE-4F51B25D5995}']
    function GetCursor: TDBScreenCursor;
    procedure SetCursor(Cursor: TDBScreenCursor);

    property Cursor: TDBScreenCursor read GetCursor write SetCursor;
  end;

  IDBApplication = interface
    ['{FAA0DF76-EC6A-48AA-9754-2D36DF815C0D}']
    function GetTitle: string;
    procedure ProcessMessages;
    procedure SetTitle(const Value: string);

    property Title: string read GetTitle write SetTitle;
  end;

  IDBSession = interface
    ['{CC2448FB-B672-4BA2-93F7-77CBEDA815FE}']
    procedure AddPassword(const APassword: string);
    procedure RemovePassword(const APassword: string);
    procedure RemoveAllPasswords;
  end;

var
  LoginDialogProc: function (const ADatabaseName: string; var AUserName, APassword: string): Boolean;
  LoginDialogExProc: function (const ADatabaseName: string; var AUserName, APassword: string; NameReadOnly: Boolean): Boolean;
  RemoteLoginDialogProc: function (var AUserName, APassword: string): Boolean;
  ScreenCursorProc: procedure (const CurIndex : integer);
  PasswordDialog: function (const ASession: IDBSession): Boolean;
  DBScreen: IDBScreen;
  DBApplication: IDBApplication;

{ Global Functions }

function ExtractFieldName(const Fields: string; var Pos: Integer): string;
procedure RegisterFields(const FieldClasses: array of TFieldClass);

procedure DatabaseError(const Message: string; Component: TComponent = nil);
procedure DatabaseErrorFmt(const Message: string; const Args: array of const;
  Component: TComponent = nil);

procedure DisposeMem(var Buffer; Size: Integer);
function BuffersEqual(Buf1, Buf2: Pointer; Size: Integer): Boolean;
{ moved to FmtBcd.pas
function BCDToCurr(const BCD: TBcd; var Curr: Currency): Boolean;
function CurrToBCD(Curr: Currency; var BCD: TBcd; Precision: Integer = 32;
  Decimals: Integer = 4): Boolean; }

function GetFieldProperty(DataSet: TDataSet; Control: TComponent;
  const FieldName: string): TField;

function VarTypeToDataType(VarType: Integer): TFieldType;

implementation

{$IFDEF MSWINDOWS}
uses DBConsts, RTLConsts, ComObj, ActiveX;
{$ENDIF}
{$IFDEF LINUX}
uses DBConsts, RTLConsts, MaskUtils, Types;
{$ENDIF}

{ Paradox graphic BLOB header }

type
  TGraphicHeader = record
    Count: Word;                { Fixed at 1 }
    HType: Word;                { Fixed at $0100 }
    Size: Longint;              { Size not including header }
  end;

{ Error and exception handling routines }

{ EUpdateError }

constructor EUpdateError.Create(NativeError, Context: string;
  ErrCode, PrevError: Integer; E: Exception);
begin
  FContext := Context;
  FErrorCode := ErrCode;
  FPreviousError := PrevError;
  FOriginalException := E;
  inherited Create(NativeError);
end;

destructor EUpdateError.Destroy;
begin
  FOriginalException.Free;
  inherited Destroy;
end;

procedure DatabaseError(const Message: string; Component: TComponent = nil);
begin
  if Assigned(Component) and (Component.Name <> '') then
    raise EDatabaseError.Create(Format('%s: %s', [Component.Name, Message])) else
    raise EDatabaseError.Create(Message);
end;

procedure DatabaseErrorFmt(const Message: string; const Args: array of const;
  Component: TComponent = nil);
begin
  DatabaseError(Format(Message, Args), Component);
end;

function GetFieldProperty(DataSet: TDataSet; Control: TComponent;
  const FieldName: string): TField;
begin
  Result := DataSet.FindField(FieldName);
  if Result = nil then
    DatabaseErrorFmt(SFieldNotFound, [FieldName], Control);
end;

{ Utility routines }

procedure DisposeMem(var Buffer; Size: Integer);
begin
  if Pointer(Buffer) <> nil then
  begin
    FreeMem(Pointer(Buffer), Size);
    Pointer(Buffer) := nil;
  end;
end;

function BuffersEqual(Buf1, Buf2: Pointer; Size: Integer): Boolean; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     ESI,Buf1
        MOV     EDI,Buf2
        XOR     EAX,EAX
        JECXZ   @@1
        CLD
        REPE    CMPSB
        JNE     @@1
        INC     EAX
@@1:    POP     ESI
        POP     EDI
end;

function ExtractFieldName(const Fields: string; var Pos: Integer): string;
var
  I: Integer;
begin
  I := Pos;
  while (I <= Length(Fields)) and (Fields[I] <> ';') do Inc(I);
  Result := Trim(Copy(Fields, Pos, I - Pos));
  if (I <= Length(Fields)) and (Fields[I] = ';') then Inc(I);
  Pos := I;
end;

procedure RegisterFields(const FieldClasses: array of TFieldClass);
begin
  if Assigned(RegisterFieldsProc) then
    RegisterFieldsProc(FieldClasses) else
    DatabaseError(SInvalidFieldRegistration);
end;

function VarTypeToDataType(VarType: Integer): TFieldType;
begin
  case VarType of
    varSmallint, varShortInt, varByte: Result := ftSmallInt;
    varWord, varInteger: Result := ftInteger;
    varCurrency: Result := ftBCD;
    varLongWord, varSingle, varDouble: Result := ftFloat;
    varDate: Result := ftDateTime;
    varBoolean: Result := ftBoolean;
    varString, varOleStr: Result := ftString;
    varInt64: Result := ftLargeInt;
  else
    if VarType = varSQLTimeStamp then
      Result := ftTimeStamp
    else if VarType = varFMTBcd then
      Result := ftFMTBcd
    else 
      Result := ftUnknown;
  end;
end;

{ TCustomConnection }

constructor TCustomConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataSets := TList.Create;
  FClients := TList.Create;
  FConnectEvents := TList.Create;
end;

destructor TCustomConnection.Destroy;
begin
  inherited Destroy;
  SetConnected(False);
  FreeAndNil(FConnectEvents);
  FreeAndNil(FClients);
  FreeAndNil(FDataSets);
end;

procedure TCustomConnection.Loaded;
begin
  inherited Loaded;
  try
    if FStreamedConnected then SetConnected(True);
  except
    if csDesigning in ComponentState then
      if Assigned(Classes.ApplicationHandleException) then
        Classes.ApplicationHandleException(ExceptObject)
      else
        ShowException(ExceptObject, ExceptAddr)
    else
      raise;
  end;
end;

procedure TCustomConnection.Open;
begin
  SetConnected(True);
end;

procedure TCustomConnection.Close;
begin
  SetConnected(False);
end;

procedure TCustomConnection.SetConnected(Value: Boolean);
begin
  if (csReading in ComponentState) and Value then
    FStreamedConnected := True else
  begin
    if Value = GetConnected then Exit;
    if Value then
    begin
      if Assigned(BeforeConnect) then BeforeConnect(Self);
      DoConnect;
      SendConnectEvent(True);
      if Assigned(AfterConnect) then AfterConnect(Self);
    end else
    begin
      if Assigned(BeforeDisconnect) then BeforeDisconnect(Self);
      SendConnectEvent(False);
      DoDisconnect;
      if Assigned(AfterDisconnect) then AfterDisconnect(Self);
    end;
  end;
end;

procedure TCustomConnection.DoConnect;
begin
end;

procedure TCustomConnection.DoDisconnect;
begin
end;

function TCustomConnection.GetConnected: Boolean;
begin
  Result := False;
end;

procedure TCustomConnection.SendConnectEvent(Connecting: Boolean);
var
  I: Integer;
  ConnectEvent: TConnectChangeEvent;
begin
  for I := 0 to FClients.Count - 1 do
  begin
    if FConnectEvents[I] <> nil then
    begin
      TMethod(ConnectEvent).Code := FConnectEvents[I];
      TMethod(ConnectEvent).Data := FClients[I];
      ConnectEvent(Self, Connecting);
    end;
    if TObject(FClients[I]) is TDataset then
      TDataSet(FClients[I]).DataEvent(deConnectChange, Integer(Connecting));
  end;
end;

procedure TCustomConnection.RegisterClient(Client: TObject; Event: TConnectChangeEvent = nil);
begin
  FClients.Add(Client);
  FConnectEvents.Add(TMethod(Event).Code);
  if Client is TDataSet then
    FDataSets.Add(Client);
end;

procedure TCustomConnection.UnRegisterClient(Client: TObject);
var
  Index: Integer;
begin
  if Client is TDataSet then
    FDataSets.Remove(Client);
  Index := FClients.IndexOf(Client);
  if Index <> -1 then
  begin
    FClients.Delete(Index);
    FConnectEvents.Delete(Index);
  end;
end;

function TCustomConnection.GetDataSet(Index: Integer): TDataSet;
begin
  Result := FDataSets[Index];
end;

function TCustomConnection.GetDataSetCount: Integer;
begin
  Result := FDataSets.Count;
end;

{ TDataSetDesigner }

constructor TDataSetDesigner.Create(DataSet: TDataSet);
begin
  FDataSet := DataSet;
  FDataSet.FDesigner := Self;
end;

destructor TDataSetDesigner.Destroy;
begin
  FDataSet.FDesigner := nil;
end;

procedure TDataSetDesigner.BeginDesign;
begin
  FDataSet.DisableControls;
  FSaveActive := FDataSet.Active;
  if FSaveActive then
  begin
    FDataSet.SetState(dsInactive);
    FDataSet.CloseCursor;
  end;
end;

procedure TDataSetDesigner.DataEvent(Event: TDataEvent; Info: Longint);
begin
end;

procedure TDataSetDesigner.EndDesign;
begin
  if FSaveActive then
  begin
    try
      FDataSet.OpenCursor;
      FDataSet.SetState(dsBrowse);
    except
      FDataSet.EnableControls;
      FDataSet.SetState(dsInactive);
      FDataSet.CloseCursor;
      raise;
    end;
  end;
  FSaveActive := False;
  FDataSet.EnableControls;
end;

{ TNamedItem }

function TNamedItem.GetDisplayName: string;
begin
  Result := FName;
end;

procedure TNamedItem.SetDisplayName(const Value: string);
begin
  if (Value <> '') and (AnsiCompareText(Value, FName) <> 0) and
    (Collection is TDefCollection) and
    (TDefCollection(Collection).IndexOf(Value) >= 0) then
    DatabaseErrorFmt(SDuplicateName, [Value, Collection.ClassName]);
  FName := Value;
  inherited;
end;

{ TDefCollection }

constructor TDefCollection.Create(ADataSet: TDataSet; AOwner: TPersistent;
  AClass: TCollectionItemClass);
begin
  inherited Create(AOwner, AClass);
  FDataSet := ADataSet;
  FOnUpdate := DoUpdate;
end;

procedure TDefCollection.SetItemName(AItem: TCollectionItem);
begin
  with TNamedItem(AItem) do
    if (Name = '') and Assigned(DataSet) then
      Name := DataSet.Name + Copy(ClassName, 2, 5) + IntToStr(ID+1);
end;

procedure TDefCollection.Update(AItem: TCollectionItem);
begin
  if Assigned(DataSet) and not (csLoading in DataSet.ComponentState) then OnUpdate(AItem);
end;

procedure TDefCollection.DoUpdate(Sender: TObject);
begin
  if (FInternalUpdateCount = 0) then
  begin
    Updated := False;
    DataSet.DefChanged(Self);
  end;
end;

procedure TDefCollection.UpdateDefs(AMethod: TDefUpdateMethod);
begin
  if not Updated then
  begin
    Inc(FInternalUpdateCount);
    BeginUpdate;
    try
      AMethod;
    finally
      EndUpdate;
      Dec(FInternalUpdateCount);
    end;
    Updated := True; { Defs are now a mirror of data source }
  end;
end;

function TDefCollection.IndexOf(const AName: string): Integer;
begin
  for Result := 0 to Count - 1 do
    if AnsiCompareText(TNamedItem(Items[Result]).Name, AName) = 0 then Exit;
  Result := -1;
end;

function TDefCollection.Find(const AName: string): TNamedItem;
var
  I: Integer;
begin
  I := IndexOf(AName);
  if I < 0 then Result := nil else Result := TNamedItem(Items[I]);
end;

procedure TDefCollection.GetItemNames(List: TStrings);
var
  I: Integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    for I := 0 to Count - 1 do
      with TNamedItem(Items[I]) do
        if Name <> '' then List.Add(Name);
  finally
    List.EndUpdate;
  end;
end;

{ TFieldDef }

constructor TFieldDef.Create(Owner: TFieldDefs; const Name: string;
  DataType: TFieldType; Size: Integer; Required: Boolean; FieldNo: Integer);
var
  FieldClass: TFieldClass;
begin
  inherited Create(Owner);
  FieldClass := Owner.FDataSet.GetFieldClass(DataType);
  if Assigned(FieldClass) then
    FieldClass.CheckTypeSize(Size);
  FName := Name;
  FDataType := DataType;
  FSize := Size;
  if Required then
    Include(FAttributes, faRequired);
  FFieldNo := FieldNo;
end;

destructor TFieldDef.Destroy;
begin
  inherited Destroy;
  FChildDefs.Free;
end;

procedure TFieldDef.ReadRequired(Reader: TReader);
begin
  SetRequired(Reader.ReadBoolean);
end;

procedure TFieldDef.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('Required', ReadRequired, nil, False);
end;

function TFieldDef.GetFieldClass: TFieldClass;
begin
  if Collection is TFieldDefs then
    Result := TFieldDefs(Collection).DataSet.GetFieldClass(DataType) else
    Result := nil;
end;

function TFieldDef.GetFieldNo: Integer;
begin
  if FFieldNo > 0 then
    Result := FFieldNo else
    Result := Index + 1;
end;

procedure TFieldDef.SetAttributes(Value: TFieldAttributes);
begin
  FAttributes := Value;
  Changed(False);
end;

procedure TFieldDef.SetDataType(Value: TFieldType);
const
  TypeSizes: packed array[TFieldType] of Byte =
    (0 {ftUnknown}, 20 {ftString}, 0 {ftSmallint}, 0 {ftInteger}, 0 {ftWord},
     0 {ftBoolean}, 0 {ftFloat}, 0 {ftCurrency}, 4 {ftBCD}, 0 {ftDate},
     0 {ftTime}, 0 {ftDateTime}, 16 {ftBytes}, 16 {ftVarBytes}, 0 {ftAutoInc},
     0 {ftBlob}, 0 {ftMemo}, 0 {ftGraphic}, 0 {ftFmtMemo}, 0 {ftParadoxOle},
     0 {ftDBaseOle}, 0 {ftTypedBinary}, 0 {ftCursor}, 20 { ftFixedChar },
     0 {ftWideString}, 0 {ftLargeInt} , 0 {ftADT}, 10 {ftArray}, 0 {ftReference},
     0 {ftDataSet}, 0 {ftOraBlob}, 0 {ftOraClob}, 0 {ftVariant}, 0 {ftInterface},
     0 {ftIDispatch}, 0 {ftGuid}, 0 {ftTimeStamp}, 0 {ftFMTBcd});
begin
  FDataType := Value;
  FPrecision := 0;
  FSize := TypeSizes[Value];
  Changed(False);
end;

procedure TFieldDef.SetPrecision(Value: Integer);
begin
  FPrecision := Value;
  Changed(False);
end;

function TFieldDef.GetRequired: Boolean;
begin
  Result := faRequired in Attributes;
end;

procedure TFieldDef.SetRequired(Value: Boolean);
begin
  if Value then
    Attributes := Attributes + [faRequired] else
    Attributes := Attributes - [faRequired];
end;

function TFieldDef.GetSize: Integer;
begin
  if HasChildDefs and (FSize = 0) then
    Result := FChildDefs.Count else
    Result := FSize;
end;

procedure TFieldDef.SetSize(Value: Integer);
var
  FClass: TFieldClass;
begin
  if HasChildDefs and (DataType <> ftArray) then Exit;
  FSize := Value;
  Changed(False);
  FClass := FieldClass;
  if Assigned(FClass) and (Size <> 0) then FClass.CheckTypeSize(Size);
end;

function TFieldDef.GetChildDefs: TFieldDefs;
begin
  if FChildDefs = nil then
    FChildDefs := TFieldDefs.Create(Self);
  Result := FChildDefs;
end;

procedure TFieldDef.SetChildDefs(Value: TFieldDefs);
begin
  ChildDefs.Assign(Value);
end;

function TFieldDef.HasChildDefs: Boolean;
begin
  Result := (FChildDefs <> nil) and (FChildDefs.Count > 0);
end;

function TFieldDef.AddChild: TFieldDef;
begin
  Result := ChildDefs.AddFieldDef;
end;

function TFieldDef.GetParentDef: TFieldDef;
begin
  Result := TFieldDefs(Collection).ParentDef;
end;

procedure TFieldDef.Assign(Source: TPersistent);
var
  I: Integer;
  S: TFieldDef;
begin
  if Source is TFieldDef then
  begin
    if Collection <> nil then Collection.BeginUpdate;
    try
      S := TFieldDef(Source);
      {FieldNo is defaulted}
      Name := S.Name;
      DataType := S.DataType;
      Size := S.Size;
      Precision := S.Precision;
      Attributes := S.Attributes;
      InternalCalcField := TFieldDef(Source).InternalCalcField;
      if HasChildDefs then ChildDefs.Clear;
      if S.HasChildDefs then
        for I := 0 to S.ChildDefs.Count - 1 do
          with AddChild do Assign(S.ChildDefs[I]);
    finally
      if Collection <> nil then Collection.EndUpdate;
    end;
  end else inherited;
end;

function TFieldDef.CreateFieldComponent(Owner: TComponent;
  ParentField: TObjectField = nil; FieldName: string = ''): TField;
var
  FieldClassType: TFieldClass;
begin
  FieldClassType := GetFieldClass;
  if FieldClassType = nil then DatabaseErrorFmt(SUnknownFieldType, [Name]);
  Result := FieldClassType.Create(Owner);
  try
    Result.Size := Size;
    if FieldName <> '' then
      Result.FieldName := FieldName else
      Result.FieldName := Name;
    Result.Required := faRequired in Attributes;
    Result.ReadOnly := faReadonly in Attributes;
    Result.SetFieldType(DataType);
    if Result is TBCDField then
      TBCDField(Result).FPrecision := Precision
    else if Result is TFMTBCDField then
      TFMTBCDField(Result).FPrecision := Precision;
    if Assigned(ParentField) then
      Result.ParentField := ParentField else
      Result.DataSet := TFieldDefs(Collection).DataSet;
    if ((faFixed in Attributes) or (DataType = ftFixedChar)) and (Result is TStringField) then
      TStringField(Result).FixedChar := True;
    if InternalCalcField then
      Result.FieldKind := fkInternalCalc;
    if (faUnNamed in Attributes) and (Result is TObjectField) then
      TObjectField(Result).SetUnNamed(True);
  except
    Result.Free;
    raise;
  end;
end;

function TFieldDef.CreateField(Owner: TComponent; ParentField: TObjectField = nil;
  const FieldName: string = ''; CreateChildren: Boolean = True): TField;
var
  FieldCount, I: Integer;
begin
  Result := CreateFieldComponent(Owner, ParentField, FieldName);
  if CreateChildren and HasChildDefs then
  begin
    if (DataType = ftArray) then
    begin
      if TFieldDefs(Collection).DataSet.SparseArrays then
        FieldCount := 1 else
        FieldCount := Size;
      for I := 0 to FieldCount - 1 do
        ChildDefs[0].CreateField(nil, TObjectField(Result), Format('%s[%d]',
          [Result.FieldName, I]))
    end else
      for I := 0 to ChildDefs.Count - 1 do
        ChildDefs[I].CreateField(nil, TObjectField(Result), '');
  end;
end;

{ TFieldDefs }

constructor TFieldDefs.Create(AOwner: TPersistent);
var
  ADataSet: TDataSet;
begin
  if AOwner is TFieldDef then
  begin
    FParentDef := TFieldDef(AOwner);
    ADataSet := TFieldDefs(FParentDef.Collection).DataSet
  end else
    ADataSet := AOwner as TDataSet;
  inherited Create(ADataSet, AOwner, TFieldDef);
  if FParentDef <> nil then
    OnUpdate := ChildDefUpdate;
end;

procedure TFieldDefs.SetItemName(AItem: TCollectionItem);
begin
  if GetOwner = DataSet then
    inherited SetItemName(AItem)
  else with TNamedItem(AItem) do
    if Name = '' then
      Name := TFieldDef(Self.GetOwner).Name + Copy(ClassName, 2, 5) + IntToStr(ID+1);
end;

function TFieldDefs.AddFieldDef: TFieldDef;
begin
  Result := TFieldDef(inherited Add);
end;

procedure TFieldDefs.Add(const Name: string; DataType: TFieldType;
  Size: Integer; Required: Boolean);
var
  FieldDef: TFieldDef;
begin
  if Name = '' then DatabaseError(SFieldNameMissing, DataSet);
  BeginUpdate;
  try
    FieldDef := AddFieldDef;
    try
      {FieldNo is defaulted}
      FieldDef.Name := Name;
      FieldDef.DataType := DataType;
      FieldDef.Size := Size;
      { Precision is defaulted }
      FieldDef.Required := Required;
    except
      FieldDef.Free;
      raise;
    end;
  finally
    EndUpdate;
  end;
end;

function TFieldDefs.Find(const Name: string): TFieldDef;
begin
  Result := TFieldDef(inherited Find(Name));
  if Result = nil then DatabaseErrorFmt(SFieldNotFound, [Name], DataSet);
end;

function TFieldDefs.GetFieldDef(Index: Integer): TFieldDef;
begin
  Result := TFieldDef(inherited Items[Index]);
end;

procedure TFieldDefs.SetFieldDef(Index: Integer; Value: TFieldDef);
begin
  inherited Items[Index] := Value;
end;

procedure TFieldDefs.SetHiddenFields(Value: Boolean);
begin
  FHiddenFields := Value;
  Updated := False;
end;

procedure TFieldDefs.Update;
begin
  DataSet.FieldDefList.Updated := False;
  UpdateDefs(DataSet.InitFieldDefs);
end;

procedure TFieldDefs.ChildDefUpdate(Sender: TObject);
begin
  { Need to update based on the UpdateCount of the DataSet's FieldDefs }
  if (DataSet.FieldDefs.UpdateCount = 0) and
     (DataSet.FieldDefs.FInternalUpdateCount = 0) then
    DoUpdate(Sender);
end;

procedure TFieldDefs.FieldDefUpdate(Sender: TObject);
begin
  DoUpdate(Sender);
  DataSet.FieldDefList.Updated := False;
end;

{ TLookupList }

constructor TLookupList.Create;
begin
  FList := TList.Create;
end;

destructor TLookupList.Destroy;
begin
  if FList <> nil then Clear;
  FList.Free;
end;

procedure TLookupList.Add(const AKey, AValue: Variant);
var
  ListEntry: PLookupListEntry;
begin
  New(ListEntry);
  ListEntry.Key := AKey;
  ListEntry.Value := AValue;
  FList.Add(ListEntry);
end;

procedure TLookupList.Clear;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    Dispose(PLookupListEntry(FList.Items[I]));
  FList.Clear;
end;

function TLookupList.ValueOfKey(const AKey: Variant): Variant;
var
  I: Integer;
begin
  Result := Null;
  if not VarIsNull(AKey) then
    for I := 0 to FList.Count - 1 do
      if PLookupListEntry(FList.Items[I]).Key = AKey then
      begin
        Result := PLookupListEntry(FList.Items[I]).Value;
        Break;
      end;
end;

{ TFlatList }

constructor TFlatList.Create(ADataSet: TDataSet);
begin
  FDataSet := ADataSet;
  inherited Create;
  OnChanging := ListChanging;
  FLocked := True;
end;

function TFlatList.FindItem(const Name: string; MustExist: Boolean): TObject;
var
  I: Integer;
begin
  if not Updated then Update;
  I := IndexOf(Name);
  if I > -1 then
    Result := GetObject(I)
  else
  begin
    if MustExist then
      DatabaseErrorFmt(SFieldNotFound, [Name], DataSet);
    Result := nil;
  end;
end;

function TFlatList.GetCount: Integer;
begin
  if not Updated then Update;
  Result := inherited GetCount;
end;

function TFlatList.GetUpdated: Boolean;
begin
  Result := FUpdated;
end;

procedure TFlatList.ListChanging(Sender: TObject);
begin
  if Locked then
    DatabaseError(SReadOnlyProperty, DataSet);
end;

procedure TFlatList.Update;
begin
  if not Updated then
  begin
    Locked := False;
    BeginUpdate;
    try
      Clear;
      UpdateList;
      FUpdated := True;
    finally
      EndUpdate;
      Locked := True;
    end;
  end;
end;

{ TFieldDefList }

function TFieldDefList.GetFieldDef(Index: Integer): TFieldDef;
begin
  if not Updated then Update;
  Result := TFieldDef(Objects[Index]);
end;

function TFieldDefList.Find(const Name: string): TFieldDef;
begin
  Result := TFieldDef(FindItem(Name, False));
end;

function TFieldDefList.FieldByName(const Name: string): TFieldDef;
begin
  Result := TFieldDef(FindItem(Name, True));
end;

procedure TFieldDefList.UpdateList;

  procedure AddFieldDefs(const ParentName: string; const FieldDefs: TFieldDefs);
  var
    ChildCount, J, I: Integer;
    ChildDef, FieldDef: TFieldDef;
    FieldName, ItemName: string;
  begin
    for I := 0 to FieldDefs.Count - 1 do
    begin
      FieldDef := FieldDefs[I];
      FieldName := ParentName+FieldDef.Name;
      AddObject(FieldName, FieldDef);
      if FieldDef.HasChildDefs then
        if FieldDef.DataType = ftArray then
        begin
          ChildDef := FieldDef.ChildDefs[0];
          ChildCount := FieldDef.Size;
          for J := 0 to ChildCount - 1 do
          begin
            ItemName := Format('%s[%d]', [FieldName, J]);
            AddObject(ItemName, ChildDef);
            if ChildDef.DataType = ftADT then
              AddFieldDefs(ItemName+'.', ChildDef.ChildDefs);
          end;
        end
        else if faUnNamed in FieldDef.Attributes then
          AddFieldDefs('',FieldDef.ChildDefs)
        else
          AddFieldDefs(ParentName+FieldDef.Name+'.', FieldDef.ChildDefs);
    end;
  end;

begin
  if DataSet.Active then DataSet.FieldDefs.Update;
  AddFieldDefs('', DataSet.FieldDefs);
end;

function TFieldDefList.GetUpdated: Boolean;
begin
  Result := FUpdated and DataSet.FieldDefs.Updated;
end;

{ TFieldList }

function TFieldList.Find(const Name: string): TField;
begin
  Result := TField(FindItem(Name, False));
end;

function TFieldList.FieldByName(const Name: string): TField;
begin
  Result := TField(FindItem(Name, True));
end;

function TFieldList.GetField(Index: Integer): TField;
begin
  if not Updated then Update;
  Result := TField(Objects[Index]);
end;

procedure TFieldList.UpdateList;

  procedure AddFields(const AFields: TFields);
  var
    I: Integer;
    Field: TField;
  begin
    { Using Fields.FList.Count here to exclude sparse fields }
    for I := 0 to AFields.FList.Count - 1 do
    begin
      Field := AFields[I];
      AddObject(Field.FullName, Field);
      if Field.DataType in [ftADT, ftArray] then
        AddFields(TObjectField(Field).FOwnedFields);
    end;
  end;

begin
  AddFields(DataSet.FFields);
end;

{ TFields }

constructor TFields.Create(ADataSet: TDataSet);
begin
  FList := TList.Create;
  FDataSet := ADataSet;
  FValidFieldKinds := [fkData..fkInternalCalc];
end;

destructor TFields.Destroy;
begin
  if FList <> nil then Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFields.Changed;
begin
  if (FDataSet <> nil) and not (csDestroying in FDataSet.ComponentState) then
    FDataSet.DataEvent(deFieldListChange, 0);
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TFields.CheckFieldKind(FieldKind: TFieldKind; Field: TField);
begin
  if not (FieldKind in ValidFieldKinds) then
    DatabaseError(SInvalidFieldKind, Field);
end;

procedure TFields.Add(Field: TField);
begin
  CheckFieldKind(Field.FieldKind, Field);
  FList.Add(Field);
  Field.FFields := Self;
  Changed;
end;

procedure TFields.Remove(Field: TField);
begin
  FList.Remove(Field);
  Field.FFields := nil;
  Changed;
end;

procedure TFields.Clear;
var
  F: TField;
begin
  while FList.Count > 0 do
  begin
    F := FList.Last;
    F.FDataSet := nil;
    F.Free;
    FList.Delete(FList.Count-1);
  end;
  Changed;
end;

procedure TFieldsGetFieldError(Index: Integer; Dataset: TDataset);
begin  // Performance:  keep string temps and try..finally blocks out of TFields.GetField.
  DatabaseError(Format(SListIndexError, [Index]), DataSet);
end;

function TFields.GetField(Index: Integer): TField;
begin
  if FSparseFields > 0 then
  begin
    if Index >= FSparseFields then
      TFieldsGetFieldError(Index, DataSet);
    Result := FList[0];
    Result.FOffset := Index;
  end else
    Result := FList[Index];
end;

procedure TFields.SetField(Index: Integer; Value: TField);
begin
  Fields[Index].Assign(Value);
end;

function TFields.GetCount: Integer;
begin
  if (FSparseFields > 0) and (FList.Count > 0) then
    Result := FSparseFields else
    Result := FList.Count;
end;

function TFields.IndexOf(Field: TField): Integer;
begin
  Result := FList.IndexOf(Field);
end;

procedure TFields.CheckFieldName(const FieldName: string);
begin
  if FieldName = '' then DatabaseError(SFieldNameMissing, DataSet);
  if FindField(FieldName) <> nil then
    DatabaseErrorFmt(SDuplicateFieldName, [FieldName], DataSet);
end;

procedure TFields.CheckFieldNames(const FieldNames: string);
var
  Pos: Integer;
begin
  Pos := 1;
  while Pos <= Length(FieldNames) do
    FieldByName(ExtractFieldName(FieldNames, Pos));
end;

procedure TFields.GetFieldNames(List: TStrings);
var
  I: Integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    for I := 0 to FList.Count - 1 do
      List.Add(TField(FList.Items[I]).FieldName)
  finally
    List.EndUpdate;
  end;
end;

function TFields.FindField(const FieldName: string): TField;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Result := FList.Items[I];
    if AnsiCompareText(Result.FFieldName, FieldName) = 0 then Exit;
  end;
  Result := nil;
end;

function TFields.FieldByName(const FieldName: string): TField;
begin
  Result := FindField(FieldName);
  if Result = nil then DatabaseErrorFmt(SFieldNotFound, [FieldName], DataSet);
end;

function TFields.FieldByNumber(FieldNo: Integer): TField;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Result := FList.Items[I];
    if Result.FieldNo = FieldNo then Exit;
  end;
  Result := nil;
end;

procedure TFields.SetFieldIndex(Field: TField; Value: Integer);
var
  CurIndex, Count: Integer;
begin
  CurIndex := FList.IndexOf(Field);
  if CurIndex >= 0 then
  begin
    Count := FList.Count;
    if Value < 0 then Value := 0;
    if Value >= Count then Value := Count - 1;
    if Value <> CurIndex then
    begin
      FList.Delete(CurIndex);
      FList.Insert(Value, Field);
      Field.PropertyChanged(True);
      Changed;
    end;
  end;
end;

{ TField }

constructor TField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVisible := True;
  FValidChars := [#0..#255];
  FProviderFlags := [pfInWhere, pfInUpdate]
end;

destructor TField.Destroy;
begin
  if FDataSet <> nil then
  begin
    FDataSet.Close;
    if FFields <> nil then
      FFields.Remove(Self);
  end;
  FLookupList.Free;
  inherited Destroy;
end;

function TField.AccessError(const TypeName: string): EDatabaseError;
begin
  Result := EDatabaseError.CreateResFmt(@SFieldAccessError,
    [DisplayName, TypeName]);
end;

procedure TField.Assign(Source: TPersistent);
begin
  if Source = nil then
    Clear
  else if Source is TField then
    Value := TField(Source).Value
  else
    inherited Assign(Source);
end;

procedure TField.AssignValue(const Value: TVarRec);

  procedure Error;
  begin
    DatabaseErrorFmt(SFieldValueError, [DisplayName]);
  end;

begin
  with Value do
    case VType of
      vtInteger:
        AsInteger := VInteger;
      vtBoolean:
        AsBoolean := VBoolean;
      vtChar:
        AsString := VChar;
      vtExtended:
        AsFloat := VExtended^;
      vtString:
        AsString := VString^;
      vtPointer:
        if VPointer <> nil then Error;
      vtPChar:
        AsString := VPChar;
      vtObject:
        if (VObject = nil) or (VObject is TPersistent) then
          Assign(TPersistent(VObject))
        else
          Error;
      vtAnsiString:
        AsString := string(VAnsiString);
      vtCurrency:
        AsCurrency := VCurrency^;
      vtVariant:
        if not VarIsClear(VVariant^) then AsVariant := VVariant^;
      vtWideString:
        AsString := WideString(VWideString);
    else
      Error;
    end;
end;

procedure TField.Bind(Binding: Boolean);
begin
  if FFieldKind = fkLookup then
    if Binding then
    begin
      if FLookupCache then
        RefreshLookupList
      else
        ValidateLookupInfo(True);
   end;
end;

procedure TField.CalcLookupValue;
begin
  if FLookupCache then
    Value := LookupList.ValueOfKey(FDataSet.FieldValues[FKeyFields])
  else if (FLookupDataSet <> nil) and FLookupDataSet.Active then
    Value := FLookupDataSet.Lookup(FLookupKeyFields,
      FDataSet.FieldValues[FKeyFields], FLookupResultField);
end;

procedure TField.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TField.CheckInactive;
begin
  if FDataSet <> nil then FDataSet.CheckInactive;
end;

procedure TField.Clear;
begin
  SetData(nil);
end;

procedure TField.CopyData(Source, Dest: Pointer);
begin
  Move(Source^, Dest^, DataSize);
end;

procedure TField.DataChanged;
begin
  FDataSet.DataEvent(deFieldChange, Longint(Self));
end;

procedure TField.DefineProperties(Filer: TFiler);

  function AttributeSetStored: Boolean;
  begin
    if Assigned(Filer.Ancestor) then
      Result := CompareText(FAttributeSet, TField(Filer.Ancestor).FAttributeSet) <> 0
    else
      Result := FAttributeSet <> '';
  end;

  function CalculatedStored: Boolean;
  begin
    if Assigned(Filer.Ancestor) then
      Result := Calculated <> TField(Filer.Ancestor).Calculated else
      Result := Calculated;
  end;

  function LookupStored: Boolean;
  begin
    if Assigned(Filer.Ancestor) then
      Result := Lookup <> TField(Filer.Ancestor).Lookup else
      Result := Lookup;
  end;

begin
  Filer.DefineProperty('AttributeSet', ReadAttributeSet, WriteAttributeSet,
    AttributeSetStored);
  { For backwards compatibility }
  Filer.DefineProperty('Calculated', ReadCalculated, WriteCalculated,
    CalculatedStored);
  Filer.DefineProperty('Lookup', ReadLookup, WriteLookup, LookupStored);
end;

procedure TField.FocusControl;
var
  Field: TField;
begin
  if (FDataSet <> nil) and FDataSet.Active then
  begin
    Field := Self;
    FDataSet.DataEvent(deFocusControl, Longint(@Field));
  end;
end;

procedure TField.FreeBuffers;
begin
end;

function TField.GetAsBoolean: Boolean;
begin
  raise AccessError('Boolean'); { Do not localize }
end;

function TField.GetAsByteArray: Variant;
begin
  VarClear(Result);
  if not GetData(@Result, False) then Result := Null;
end;

function TField.GetAsBCD: TBcd;
begin
  CurrToBcd(GetAsCurrency, Result);
end;

function TField.GetAsCurrency: Currency;
begin
  Result := GetAsFloat;
end;

function TField.GetAsDateTime: TDateTime;
begin
  raise AccessError('DateTime'); { Do not localize }
end;

function TField.GetAsFloat: Double;
begin
  raise AccessError('Float'); { Do not localize }
end;

function TField.GetAsInteger: Longint;
begin
  raise AccessError('Integer'); { Do not localize }
end;

function TField.GetAsSQLTimeStamp: TSQLTimeStamp;
begin
  raise AccessError('SQLTimeStamp'); { Do not localize }
end;

function TField.GetAsString: string;
begin
  Result := GetClassDesc;
end;

function TField.GetAsVariant: Variant;
begin
  raise AccessError('Variant'); { Do not localize }
end;

function TField.GetCalculated: Boolean;
begin
  Result := FFieldKind = fkCalculated;
end;

function TField.GetCanModify: Boolean;
begin
  if FieldNo > 0 then
    if DataSet.State <> dsSetKey then
      Result := not ReadOnly and DataSet.CanModify else
      Result := IsIndexField
  else
    Result := False;
end;

function TField.GetClassDesc: string;
var
  I, L: Integer;
  S: string[63];
begin
  S := ClassName;
  I := 1;
  L := Length(S);
  if S[1] = 'T' then I := 2;
  if (L-I >= 5) and (CompareText(Copy(S, L - 4, 5), 'FIELD') = 0) then Dec(L, 5);
  FmtStr(Result, '(%s)', [Copy(S, I, L + 1 - I)]);
  if not IsNull then Result := AnsiUpperCase(Result);
end;

function TField.GetData(Buffer: Pointer; NativeFormat: Boolean = True): Boolean;
begin
  if FDataSet = nil then DatabaseErrorFmt(SDataSetMissing, [DisplayName]);
  if FValidating then
  begin
    Result := LongBool(FValueBuffer);
    if Result and (Buffer <> nil) then
      CopyData(FValueBuffer, Buffer);
  end else
    Result := FDataSet.GetFieldData(Self, Buffer, NativeFormat);
end;

function TField.GetDataSize: Integer;
begin
  Result := 0;
end;

function TField.GetDefaultWidth: Integer;
begin
  Result := 10;
end;

function TField.GetDisplayLabel: string;
begin
  Result := GetDisplayName;
end;

function TField.GetDisplayName: string;
begin
  if FDisplayLabel <> '' then
    Result := FDisplayLabel else
    Result := FFieldName;
end;

function TField.GetDisplayText: string;
begin
  Result := '';
  if Assigned(FOnGetText) then
    FOnGetText(Self, Result, True) else
    GetText(Result, True);
end;

function TField.GetDisplayWidth: Integer;
begin
  if FDisplayWidth > 0 then
    Result := FDisplayWidth else
    Result := GetDefaultWidth;
end;

function TField.GetEditText: string;
begin
  Result := '';
  if Assigned(FOnGetText) then
    FOnGetText(Self, Result, False) else
    GetText(Result, False);
end;

function TField.GetFieldNo: Integer;
var
  ParentField: TObjectField;
begin
  Result := FFieldNo;
  if (FParentField = nil) or IsBlob or (FieldKind <> fkData) then Exit;
  if Offset > 0 then
    Inc(Result, Offset) else
  begin
    ParentField := FParentField;
    while ParentField <> nil do
    begin
      if ParentField.OffSet > 0 then
      begin
        Inc(Result, ParentField.OffSet * (ParentField.Size+1));
        Break;
      end;
      ParentField := ParentField.ParentField;
    end;
  end;
end;

function TField.GetFullName: string;
begin
  if (FParentField = nil) or (DataSet = nil) then
    Result := FieldName else
    Result := DataSet.GetFieldFullName(Self);
end;

function TField.GetHasConstraints: Boolean;
begin
  Result := (CustomConstraint <> '') or (ImportedConstraint <> '') or
   (DefaultExpression <> '');
end;

function TField.GetIndex: Integer;
begin
  if FParentField <> nil then
    Result := FParentField.Fields.IndexOf(Self)
  else if FDataSet <> nil then
    Result := DataSet.FFields.IndexOf(Self)
  else
    Result := -1;
end;

function TField.GetIsIndexField: Boolean;
begin
  if (FDataSet <> nil) and (FParentField = nil) then
    Result := DataSet.GetIsIndexField(Self) else
    Result := False;
end;

class function TField.IsBlob: Boolean;
begin
  Result := False;
end;

function TField.GetIsNull: Boolean;
begin
  Result := not GetData(nil);
end;

function TField.GetLookup: Boolean;
begin
  Result := FFieldKind = fkLookup;
end;

function TField.GetLookupList: TLookupList;
begin
  if not Assigned(FLookupList) then
    FLookupList := TLookupList.Create;
  Result := FLookupList;
end;

procedure TField.GetText(var Text: string; DisplayText: Boolean);
begin
  Text := GetAsString;
end;

function TField.HasParent: Boolean;
begin
  HasParent := True;
end;

function TField.GetNewValue: Variant;
begin
  Result := DataSet.GetStateFieldValue(dsNewValue, Self);
end;

function TField.GetOldValue: Variant;
begin
  Result := DataSet.GetStateFieldValue(dsOldValue, Self);
end;

function TField.GetCurValue: Variant;
begin
  Result := DataSet.GetStateFieldValue(dsCurValue, Self);
end;

function TField.GetParentComponent: TComponent;
begin
  if ParentField <> nil then
    Result := ParentField else
    Result := DataSet;
end;

procedure TField.SetParentComponent(AParent: TComponent);
begin
  if not (csLoading in ComponentState) then
    if AParent is TObjectField then
      ParentField := AParent as TObjectField else
      DataSet := AParent as TDataSet;
end;

function TField.IsValidChar(InputChar: Char): Boolean;
begin
  Result := InputChar in ValidChars;
end;

function TField.IsDisplayLabelStored: Boolean;
begin
  Result := FDisplayLabel <> '';
end;

function TField.IsDisplayWidthStored: Boolean;
begin
  Result := FDisplayWidth > 0;
end;

procedure TField.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FLookupDataSet) then
    FLookupDataSet := nil;
end;

procedure TField.PropertyChanged(LayoutAffected: Boolean);
const
  Events: array[Boolean] of TDataEvent = (deDataSetChange, deLayoutChange);
begin
  if (FDataSet <> nil) and FDataSet.Active then
    FDataSet.DataEvent(Events[LayoutAffected], 0);
end;

procedure TField.ReadAttributeSet(Reader: TReader);
begin
  FAttributeSet := Reader.ReadString;
end;

procedure TField.ReadCalculated(Reader: TReader);
begin
  if Reader.ReadBoolean then
    FFieldKind := fkCalculated;
end;

procedure TField.ReadLookup(Reader: TReader);
begin
  if Reader.ReadBoolean then
    FFieldKind := fkLookup;
end;

procedure TField.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
  if Reader.Parent is TObjectField then
    ParentField := TObjectField(Reader.Parent)
  else if Reader.Parent is TDataSet then
    DataSet := TDataSet(Reader.Parent);
end;

procedure TField.RefreshLookupList;
var
  WasActive: Boolean;
begin
  if FLookupDataSet <> nil then
  begin
    WasActive := FLookupDataSet.Active;
    ValidateLookupInfo(True);
    with FLookupDataSet do
    try
      LookupList.Clear;
      DisableControls;
      try
        First;
        while not Eof do
        begin
          FLookupList.Add(FieldValues[FLookupKeyFields],
            FieldValues[FLookupResultField]);
          Next;
        end;
      finally
        EnableControls;
      end;
    finally
      Active := WasActive;
    end;
  end
  else
    ValidateLookupInfo(False);
end;

procedure TField.SetAsBCD(const Value: TBcd);
var
  Curr: Currency;
begin
  BcdToCurr(Value,Curr);
  SetAsCurrency(Curr);
end;

procedure TField.SetAsBoolean(Value: Boolean);
begin
  raise AccessError('Boolean'); { Do not localize }
end;

procedure TField.SetAsCurrency(Value: Currency);
begin
  SetAsFloat(Value);
end;

procedure TField.SetAsDateTime(Value: TDateTime);
begin
  raise AccessError('DateTime'); { Do not localize }
end;

procedure TField.SetAsFloat(Value: Double);
begin
  raise AccessError('Float'); { Do not localize }
end;

procedure TField.SetAsInteger(Value: Longint);
begin
  raise AccessError('Integer'); { Do not localize }
end;

procedure TField.SetAsSQLTimeStamp(const Value: TSQLTimeStamp);
begin
  raise AccessError('SQLTimeStamp'); { Do not localize }
end;

procedure TField.SetAsString(const Value: string);
begin
  raise AccessError('String'); { Do not localize }
end;

procedure TField.SetAsVariant(const Value: Variant);
begin
  if VarIsNull(Value) then
    Clear
  else
    try
      SetVarValue(Value);
    except
      on EVariantError do DatabaseErrorFmt(SFieldValueError, [DisplayName]);
    end;
end;

procedure TField.SetAsByteArray(const Value: Variant);
begin
  if not (VarIsArray(Value) and (VarArrayDimCount(Value) = 1) and
     ((VarType(Value) and VarTypeMask) = varByte) and
     (VarArrayHighBound(Value, 1) <= DataSize)) then
    DatabaseErrorFmt(SInvalidVarByteArray, [DisplayName]);
  SetData(@Value, False);
end;

procedure TField.SetAlignment(Value: TAlignment);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    PropertyChanged(False);
  end;
end;

procedure TField.SetCalculated(Value: Boolean);
begin
  if Value then
    FieldKind := fkCalculated
  else if FieldKind = fkCalculated then
    FieldKind := fkData;
end;

procedure TField.SetData(Buffer: Pointer; NativeFormat: Boolean = True);
begin
  if FDataSet = nil then DatabaseErrorFmt(SDataSetMissing, [DisplayName]);
  FValueBuffer := Buffer;
  try
    FDataSet.SetFieldData(Self, Buffer, NativeFormat);
  finally
    FValueBuffer := nil;
  end;
end;

procedure TField.SetDataSet(ADataSet: TDataSet);
begin
  if ADataSet <> FDataSet then
  begin
    { Make sure new and old datasets are closed and fieldname is not a dup. }
    if FDataSet <> nil then FDataSet.CheckInactive;
    if ADataSet <> nil then
    begin
      ADataSet.CheckInactive;
      if FieldKind = fkAggregate then
        ADataSet.FAggFields.CheckFieldName(FFieldName) else
        ADataSet.FFields.CheckFieldName(FFieldName);
    end;
    { If ParentField is set and part of a different dataset then clear it }
    if (FParentField <> nil) and (FParentField.DataSet <> ADataSet) then
    begin
      FParentField.FFields.Remove(Self);
      FParentField := nil;
    end
    else if FDataSet <> nil then
    begin
      if FieldKind = fkAggregate then
        FDataSet.FAggFields.Remove(Self) else
        FDataSet.FFields.Remove(Self);
    end;
    { Add to the new dataset's field list, unless parentfield is still set }
    if (ADataSet <> nil) and (FParentField = nil) then
    begin
      if FieldKind = fkAggregate then
        ADataSet.FAggFields.Add(Self) else
        ADataSet.FFields.Add(Self);
    end;
    FDataSet := ADataSet;
  end;
end;

procedure TField.SetParentField(AField: TObjectField);
begin
  if AField <> FParentField then
  begin
    if FDataSet <> nil then FDataSet.CheckInactive;
    if AField <> nil then
    begin
      if AField.DataSet <> nil then AField.DataSet.CheckInactive;
      AField.Fields.CheckFieldName(FFieldName);
      AField.Fields.Add(Self);
      if FDataSet <> nil then FDataSet.FFields.Remove(Self);
      FDataSet := AField.DataSet;
    end
    else if FDataSet <> nil then FDataSet.FFields.Add(Self);
    if FParentField <> nil then FParentField.Fields.Remove(Self);
    FParentField := AField;
  end;
end;

procedure TField.SetDataType(Value: TFieldType);
begin
  FDataType := Value;
end;

procedure TField.SetDisplayLabel(Value: string);
begin
  if Value = FFieldName then Value := '';
  if FDisplayLabel <> Value then
  begin
    FDisplaylabel := Value;
    PropertyChanged(True);
  end;
end;

procedure TField.SetDisplayWidth(Value: Integer);
begin
  if FDisplayWidth <> Value then
  begin
    FDisplayWidth := Value;
    PropertyChanged(True);
  end;
end;

{$IFDEF MSWINDOWS}
procedure TField.SetEditMask(const Value: TEditMask);
{$ENDIF}
{$IFDEF LINUX}
procedure TField.SetEditMask(const Value: string);
{$ENDIF}
begin
  FEditMask := Value;
  PropertyChanged(False);
end;

procedure TField.SetEditText(const Value: string);
begin
  if Assigned(FOnSetText) then FOnSetText(Self, Value) else SetText(Value);
end;

procedure TField.SetFieldKind(Value: TFieldKind);
begin
  if FFieldKind <> Value then
  begin
    if FFields <> nil then
      FFields.CheckFieldKind(Value, Self);
    if (DataSet <> nil) and (DataSet.FDesigner <> nil) then
    with DataSet.Designer do
    begin
      BeginDesign;
      try
        FFieldKind := Value;
      finally
        EndDesign;
      end;
    end else
    begin
      CheckInactive;
      FFieldKind := Value;
    end;
  end;
end;

procedure TField.SetFieldName(const Value: string);
begin
  CheckInactive;
  if (FDataSet <> nil) and (AnsiCompareText(Value, FFieldName) <> 0) then
    FFields.CheckFieldName(Value);
  FFieldName := Value;
  if FDisplayLabel = Value then FDisplayLabel := '';
  if FDataSet <> nil then FDataSet.FFields.Changed;
end;

procedure TField.SetFieldType(Value: TFieldType);
begin
end;

procedure TField.SetIndex(Value: Integer);
begin
  if FFields <> nil then
    FFields.SetFieldIndex(Self, Value)
end;

procedure TField.SetLookup(Value: Boolean);
begin
  if Value then
    FieldKind := fkLookup
  else if FieldKind = fkLookup then
    FieldKind := fkData;
end;

procedure TField.SetLookupDataSet(Value: TDataSet);
begin
  CheckInactive;
  if (Value <> nil) and (Value = FDataSet) then
    DatabaseError(SCircularDataLink, Self);
  FLookupDataSet := Value;
end;

procedure TField.SetLookupKeyFields(const Value: string);
begin
  CheckInactive;
  FLookupKeyFields := Value;
end;

procedure TField.SetLookupResultField(const Value: string);
begin
  CheckInactive;
  FLookupResultField := Value;
end;

procedure TField.SetKeyFields(const Value: string);
begin
  CheckInactive;
  FKeyFields := Value;
end;

procedure TField.SetNewValue(const Value: Variant);
begin
  DataSet.SetStateFieldValue(dsNewValue, Self, Value);
end;

procedure TField.SetLookupCache(const Value: Boolean);
begin
  CheckInactive;
  FLookupCache := Value;
end;

class procedure TField.CheckTypeSize(Value: Integer);
begin
  if (Value <> 0) and not IsBlob then
    DatabaseError(SInvalidFieldSize);
end;

procedure TField.SetSize(Value: Integer);
begin
  CheckInactive;
  CheckTypeSize(Value);
  FSize := Value;
end;

function TField.GetSize: Integer;
begin
  Result := FSize;
end;

procedure TField.SetText(const Value: string);
begin
  SetAsString(Value);
end;

procedure TField.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    PropertyChanged(True);
  end;
end;

procedure TField.SetVarValue(const Value: Variant);
begin
  raise AccessError('Variant'); { Do not localize }
end;

procedure TField.SetVisible(Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    PropertyChanged(True);
  end;
end;

procedure TField.Validate(Buffer: Pointer);
begin
  if Assigned(OnValidate) then
  begin
    { Use the already assigned FValueBuffer if set }
    if FValueBuffer = nil then
      FValueBuffer := Buffer;
    FValidating := True;
    try
      OnValidate(Self);
    finally
      FValidating := False;
    end;
  end;
end;

procedure TField.ValidateLookupInfo(All: Boolean);
begin
  if (All and ((FLookupDataSet = nil) or (FLookupKeyFields = '') or
     (FLookupResultField = ''))) or (FKeyFields = '') then
    DatabaseErrorFmt(SLookupInfoError, [DisplayName]);
  FFields.CheckFieldNames(FKeyFields);
  if All then
  begin
    FLookupDataSet.Open;
    FLookupDataSet.FFields.CheckFieldNames(FLookupKeyFields);
    FLookupDataSet.FieldByName(FLookupResultField);
  end;
end;

procedure TField.WriteAttributeSet(Writer: TWriter);
begin
  Writer.WriteString(FAttributeSet);
end;

procedure TField.WriteCalculated(Writer: TWriter);
begin
  Writer.WriteBoolean(True);
end;

procedure TField.WriteLookup(Writer: TWriter);
begin
  Writer.WriteBoolean(True);
end;

procedure TField.SetAutoGenerateValue(const Value: TAutoRefreshFlag);
begin
  CheckInactive;
  FAutoGenerateValue := Value;
end;

{ TStringField }

constructor TStringField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftString);
  if Size = 0 then Size := 20; { Don't reset descendent settings }
  Transliterate := True;
end;

class procedure TStringField.CheckTypeSize(Value: Integer);
begin
  if Value < 0 then
    DatabaseError(SInvalidFieldSize);
end;

function TStringField.GetAsBCD: TBcd;
begin
  Result := StrToBcd(GetAsString);
end;

function TStringField.GetAsBoolean: Boolean;
var
  S: string;
begin
  S := GetAsString;
  Result := (Length(S) > 0) and (S[1] in ['T', 't', 'Y', 'y']);
end;

function TStringField.GetAsDateTime: TDateTime;
begin
  Result := StrToDateTime(GetAsString);
end;

function TStringField.GetAsFloat: Double;
begin
  Result := StrToFloat(GetAsString);
end;

function TStringField.GetAsInteger: Longint;
begin
  Result := StrToInt(GetAsString);
end;

function TStringField.GetAsSQLTimeStamp: TSQLTimeStamp;
begin
  Result := StrToSQLTimeStamp(GetAsString);
end;

function TStringField.GetAsString: string;
begin
  if not GetValue(Result) then Result := '';
end;

function TStringField.GetAsVariant: Variant;
var
  S: string;
begin
  if GetValue(S) then Result := S else Result := Null;
end;

function TStringField.GetDataSize: Integer;
begin
  Result := Size + 1;
end;

function TStringField.GetDefaultWidth: Integer;
begin
  Result := Size;
end;

procedure TStringField.GetText(var Text: string; DisplayText: Boolean);
begin
  if DisplayText and (EditMaskPtr <> '') then
    Text := FormatMaskText(EditMaskPtr, GetAsString) else
    Text := GetAsString;
end;

function TStringField.GetValue(var Value: string): Boolean;
var
  Temp: String;
  pBuff: PChar;
  Buffer: array[0..dsMaxStringSize] of Char;
begin
  if DataSize > dsMaxStringSize then
  begin
    SetLength(Temp, DataSize);
    pBuff := pChar(Temp);
    Result := GetData(pBuff);
    if Result then
      SetLength(Temp, strlen(PBuff));
  end else
    Result := GetData(@Buffer);
  if Result then
  begin
    if DataSize > dsMaxStringSize then
      Value := Temp
    else
      Value := Buffer;
    if Transliterate and (Value <> '') then
      DataSet.Translate(PChar(Value), PChar(Value), False);
  end;
end;

procedure TStringField.SetAsBCD(const Value: TBcd);
begin
  SetAsString(BcdToStr(Value));
end;

procedure TStringField.SetAsBoolean(Value: Boolean);
const
  Values: array[Boolean] of string[1] = ('F', 'T');
begin
  SetAsString(Values[Value]);
end;

procedure TStringField.SetAsDateTime(Value: TDateTime);
begin
  SetAsString(DateTimeToStr(Value));
end;

procedure TStringField.SetAsFloat(Value: Double);
begin
  SetAsString(FloatToStr(Value));
end;

procedure TStringField.SetAsInteger(Value: Longint);
begin
  SetAsString(IntToStr(Value));
end;

procedure TStringField.SetAsSQLTimeStamp(const Value: TSQLTimeStamp);
var
  SSqlTs: String;
begin
  SSQLTs := SQLTimeStampToStr('', Value);
  SetAsString(SSqlTs);
end;

procedure TStringField.SetAsString(const Value: string);
var
  pBuff: PChar;
  Temp: String;
  Buffer: array[0..dsMaxStringSize] of Char;
begin
  if DataSize > dsMaxStringSize then
  begin
    SetLength(Temp, strlen(PChar(Value))+1);
    pBuff := PChar(Temp);
    StrLCopy(pBuff, PChar(Value), strlen(PChar(Value)));
    if Transliterate then
      DataSet.Translate(pBuff, pBuff, True);
    SetData(pBuff);
  end else 
  begin
    StrLCopy(Buffer, PChar(Value), Size);
    if Transliterate then
      DataSet.Translate(Buffer, Buffer, True);
    SetData(@Buffer);
  end;
end;

procedure TStringField.SetVarValue(const Value: Variant);
begin
  SetAsString(Value);
end;

{ TWideStringField }

class procedure TWideStringField.CheckTypeSize(Value: Integer);
begin
  if (Value < 0) then
    DatabaseError(SInvalidFieldSize);
end;

constructor TWideStringField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftWideString);
end;

procedure TWideStringField.CopyData(Source, Dest: Pointer);
begin
  WideString(Dest^) := WideString(Source^);
end;

function TWideStringField.GetAsString: string;
begin
  Result := GetAsWideString;
end;

function TWideStringField.GetAsVariant: Variant;
var
  S: PWideChar;
begin
  S := nil;
  if GetData(@S, False) then
  begin
    TVarData(Result).VOleStr := PWideChar(S);
    TVarData(Result).VType := varOleStr;
  end else
    Result := Null;
end;

function TWideStringField.GetAsWideString: WideString;
begin
  GetData(@Result, False);
end;

function TWideStringField.GetDataSize: Integer;
begin
  Result := SizeOf(WideString);
end;

procedure TWideStringField.SetAsString(const Value: string);
begin
  SetAsWideString(Value);
end;

procedure TWideStringField.SetAsWideString(const Value: WideString);
var
  TruncValue: WideString;
begin
  if Length(Value) > Size then
  begin
    TruncValue := Copy(Value, 1, Size);
    SetData(@TruncValue, False)
  end else
    SetData(@Value, False);
end;

procedure TWideStringField.SetVarValue(const Value: Variant);
begin
  SetAsWideString(Value);
end;

{ TNumericField }

constructor TNumericField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Alignment := taRightJustify;
end;

procedure TNumericField.RangeError(Value, Min, Max: Extended);
begin
  DatabaseErrorFmt(SFieldRangeError, [Value, DisplayName, Min, Max]);
end;

procedure TNumericField.SetDisplayFormat(const Value: string);
begin
  if FDisplayFormat <> Value then
  begin
    FDisplayFormat := Value;
    PropertyChanged(False);
  end;
end;

procedure TNumericField.SetEditFormat(const Value: string);
begin
  if FEditFormat <> Value then
  begin
    FEditFormat := Value;
    PropertyChanged(False);
  end;
end;

{ TIntegerField }

constructor TIntegerField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftInteger);
  FMinRange := Low(Longint);
  FMaxRange := High(Longint);
  ValidChars := ['+', '-', '0'..'9'];
end;

procedure TIntegerField.CheckRange(Value, Min, Max: Longint);
begin
  if (Value < Min) or (Value > Max) then RangeError(Value, Min, Max);
end;

function TIntegerField.GetAsFloat: Double;
begin
  Result := GetAsInteger;
end;

function TIntegerField.GetAsInteger: Longint;
begin
  if not GetValue(Result) then Result := 0;
end;

function TIntegerField.GetAsString: string;
var
  L: Longint;
begin
  if GetValue(L) then Str(L, Result) else Result := '';
end;

function TIntegerField.GetAsVariant: Variant;
var
  L: Longint;
begin
  if GetValue(L) then Result := L else Result := Null;
end;

function TIntegerField.GetDataSize: Integer;
begin
  Result := SizeOf(Integer);
end;

procedure TIntegerField.GetText(var Text: string; DisplayText: Boolean);
var
  L: Longint;
  FmtStr: string;
begin
  if GetValue(L) then
  begin
    if DisplayText or (FEditFormat = '') then
      FmtStr := FDisplayFormat else
      FmtStr := FEditFormat;
    if FmtStr = '' then Str(L, Text) else Text := FormatFloat(FmtStr, L);
  end else
    Text := '';
end;

function TIntegerField.GetValue(var Value: Longint): Boolean;
var
  Data: record
    case Integer of
      0: (I: Smallint);
      1: (W: Word);
      2: (L: Longint);
  end;
begin
  Data.L := 0;
  Result := GetData(@Data);
  if Result then
    case DataType of
      ftSmallint: Value := Data.I;
      ftWord: Value := Data.W;
    else
      Value := Data.L;
    end;
end;

procedure TIntegerField.SetAsFloat(Value: Double);
begin
  SetAsInteger(Integer(Round(Value)));
end;

procedure TIntegerField.SetAsInteger(Value: Longint);
begin
  if (FMinValue <> 0) or (FMaxValue <> 0) then
    CheckRange(Value, FMinValue, FMaxValue) else
    CheckRange(Value, FMinRange, FMaxRange);
  SetData(@Value);
end;

procedure TIntegerField.SetAsString(const Value: string);
var
  E: Integer;
  L: Longint;
begin
  if Value = '' then Clear else
  begin
    Val(Value, L, E);
    if E <> 0 then DatabaseErrorFmt(SInvalidIntegerValue, [Value, DisplayName]);
    SetAsInteger(L);
  end;
end;

procedure TIntegerField.SetMaxValue(Value: Longint);
begin
  CheckRange(Value, FMinRange, FMaxRange);
  FMaxValue := Value;
end;

procedure TIntegerField.SetMinValue(Value: Longint);
begin
  CheckRange(Value, FMinRange, FMaxRange);
  FMinValue := Value;
end;

procedure TIntegerField.SetVarValue(const Value: Variant);
begin
  SetAsInteger(Value);
end;

{ TSmallintField }

constructor TSmallintField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftSmallint);
  FMinRange := Low(Smallint);
  FMaxRange := High(Smallint);
end;

function TSmallintField.GetDataSize: Integer;
begin
  Result := SizeOf(SmallInt);
end;

{ TLargeintField }

constructor TLargeintField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftLargeint);
  ValidChars := ['+', '-', '0'..'9'];
end;

procedure TLargeintField.CheckRange(Value, Min, Max: Largeint);
begin
  if (Value < Min) or (Value > Max) then RangeError(Value, Min, Max);
end;

function TLargeintField.GetAsFloat: Double;
begin
  Result := GetAsLargeint;
end;

function TLargeintField.GetAsInteger: Longint;
var
  L: LargeInt;
begin
  if GetValue(L) then Result := Longint(L) else Result := 0;
end;

function TLargeintField.GetAsLargeint: Largeint;
begin
  if not GetValue(Result) then Result := 0;
end;

function TLargeintField.GetAsString: string;
var
  L: Largeint;
begin
  if GetValue(L) then Str(L, Result) else Result := '';
end;

function TLargeintField.GetAsVariant: Variant;
begin
  if IsNull then
    Result := Null else
  begin
    Result := GetAsLargeInt;
  end;
end;

function TLargeintField.GetDataSize: Integer;
begin
  Result := SizeOf(Largeint);
end;

function TLargeintField.GetDefaultWidth: Integer;
begin
  Result := 15;
end;

procedure TLargeintField.GetText(var Text: string; DisplayText: Boolean);
var
  L: Largeint;
  FmtStr: string;
begin
  if GetValue(L) then
  begin
    if DisplayText or (FEditFormat = '') then
      FmtStr := FDisplayFormat else
      FmtStr := FEditFormat;
    if FmtStr = '' then Str(L, Text) else Text := FormatFloat(FmtStr, L);
  end else
    Text := '';
end;

function TLargeintField.GetValue(var Value: Largeint): Boolean;
begin
  Result := GetData(@Value);
end;

procedure TLargeintField.SetAsFloat(Value: Double);
begin
  SetAsLargeint(Round(Value));
end;

procedure TLargeintField.SetAsInteger(Value: Longint);
begin
  SetAsLargeInt(Value);
end;

procedure TLargeintField.SetAsLargeint(Value: Largeint);
begin
  if (FMinValue <> 0) or (FMaxValue <> 0) then
    CheckRange(Value, FMinValue, FMaxValue);
  SetData(@Value);
end;

procedure TLargeintField.SetAsString(const Value: string);
var
  E: Integer;
  L: Largeint;
begin
  if Value = '' then Clear else
  begin
    Val(Value, L, E);
    if E <> 0 then DatabaseErrorFmt(SInvalidIntegerValue, [Value, DisplayName]);
    SetAsLargeint(L);
  end;
end;

procedure TLargeintField.SetVarValue(const Value: Variant);
begin
  raise AccessError('Variant');
end;

{ TWordField }

constructor TWordField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftWord);
  FMinRange := Low(Word);
  FMaxRange := High(Word);
end;

function TWordField.GetDataSize: Integer;
begin
  Result := SizeOf(Word);
end;

{ TAutoIncField }

constructor TAutoIncField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftAutoInc);
end;

{ TFloatField }

constructor TFloatField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftFloat);
  FPrecision := 15;
  ValidChars := [DecimalSeparator, '+', '-', '0'..'9', 'E', 'e'];
end;

function TFloatField.GetAsFloat: Double;
begin
  if not GetData(@Result) then Result := 0;
end;

function TFloatField.GetAsInteger: Longint;
begin
  Result := Longint(Round(GetAsFloat));
end;

function TFloatField.GetAsString: string;
var
  F: Double;
begin
  if GetData(@F) then Result := FloatToStr(F) else Result := '';
end;

function TFloatField.GetAsVariant: Variant;
var
  F: Double;
begin
  if GetData(@F) then Result := F else Result := Null;
end;

function TFloatField.GetDataSize: Integer;
begin
  Result := SizeOf(Double);
end;

procedure TFloatField.GetText(var Text: string; DisplayText: Boolean);
var
  Format: TFloatFormat;
  FmtStr: string;
  Digits: Integer;
  F: Double;
begin
  if GetData(@F) then
  begin
    if DisplayText or (FEditFormat = '') then
      FmtStr := FDisplayFormat else
      FmtStr := FEditFormat;
    if FmtStr = '' then
    begin
      if FCurrency then
      begin
        if DisplayText then Format := ffCurrency else Format := ffFixed;
        Digits := CurrencyDecimals;
      end
      else begin
        Format := ffGeneral;
        Digits := 0;
      end;
      Text := FloatToStrF(F, Format, FPrecision, Digits);
    end else
      Text := FormatFloat(FmtStr, F);
  end else
    Text := '';
end;

procedure TFloatField.SetAsFloat(Value: Double);
begin
  if FCheckRange and ((Value < FMinValue) or (Value > FMaxValue)) then
    RangeError(Value, FMinValue, FMaxValue);
  SetData(@Value);
end;

procedure TFloatField.SetAsInteger(Value: Longint);
begin
  SetAsFloat(Value);
end;

procedure TFloatField.SetAsString(const Value: string);
var
  F: Extended;
begin
  if Value = '' then Clear else
  begin
    if not TextToFloat(PChar(Value), F, fvExtended) then
      DatabaseErrorFmt(SInvalidFloatValue, [Value, DisplayName]);
    SetAsFloat(F);
  end;
end;

procedure TFloatField.SetCurrency(Value: Boolean);
begin
  if FCurrency <> Value then
  begin
    FCurrency := Value;
    PropertyChanged(False);
  end;
end;

procedure TFloatField.SetMaxValue(Value: Double);
begin
  FMaxValue := Value;
  UpdateCheckRange;
end;

procedure TFloatField.SetMinValue(Value: Double);
begin
  FMinValue := Value;
  UpdateCheckRange;
end;

procedure TFloatField.SetPrecision(Value: Integer);
begin
  if Value < 2 then Value := 2;
  if Value > 15 then Value := 15;
  if FPrecision <> Value then
  begin
    FPrecision := Value;
    PropertyChanged(False);
  end;
end;

procedure TFloatField.SetVarValue(const Value: Variant);
begin
  SetAsFloat(Value);
end;

procedure TFloatField.UpdateCheckRange;
begin
  FCheckRange := (FMinValue <> 0) or (FMaxValue <> 0);
end;

{ TCurrencyField }

constructor TCurrencyField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftCurrency);
  FCurrency := True;
end;

{ TBooleanField }

constructor TBooleanField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftBoolean);
  LoadTextValues;
end;

function TBooleanField.GetAsBoolean: Boolean;
var
  B: WordBool;
begin
  if GetData(@B) then Result := B else Result := False;
end;

function TBooleanField.GetAsString: string;
var
  B: WordBool;
begin
  if GetData(@B) then Result := FTextValues[B] else Result := '';
end;

function TBooleanField.GetAsVariant: Variant;
var
  B: WordBool;
begin
  if GetData(@B) then Result := B else Result := Null;
end;

function TBooleanField.GetDataSize: Integer;
begin
  Result := SizeOf(WordBool);
end;

function TBooleanField.GetDefaultWidth: Integer;
begin
  if Length(FTextValues[False]) > Length(FTextValues[True]) then
    Result := Length(FTextValues[False]) else
    Result := Length(FTextValues[True]);
end;

procedure TBooleanField.LoadTextValues;
begin
  FTextValues[False] := STextFalse;
  FTextValues[True] := STextTrue;
end;

procedure TBooleanField.SetAsBoolean(Value: Boolean);
var
  B: WordBool;
begin
  if Value then Word(B) := 1 else Word(B) := 0;
  SetData(@B);
end;

procedure TBooleanField.SetAsString(const Value: string);
var
  L: Integer;
begin
  L := Length(Value);
  if L = 0 then
  begin
    if Length(FTextValues[False]) = 0 then SetAsBoolean(False) else
      if Length(FTextValues[True]) = 0 then SetAsBoolean(True) else
        Clear;
  end else
  begin
    if AnsiCompareText(Value, Copy(FTextValues[False], 1, L)) = 0 then
      SetAsBoolean(False)
    else
      if AnsiCompareText(Value, Copy(FTextValues[True], 1, L)) = 0 then
        SetAsBoolean(True)
      else
        DatabaseErrorFmt(SInvalidBoolValue, [Value, DisplayName]);
  end;
end;

procedure TBooleanField.SetDisplayValues(const Value: string);
var
  P: Integer;
begin
  if FDisplayValues <> Value then
  begin
    FDisplayValues := Value;
    if Value = '' then LoadTextValues else
    begin
      P := Pos(';', Value);
      if P = 0 then P := 256;
      FTextValues[False] := Copy(Value, P + 1, 255);
      FTextValues[True] := Copy(Value, 1, P - 1);
    end;
    PropertyChanged(True);
  end;
end;

procedure TBooleanField.SetVarValue(const Value: Variant);
begin
  SetAsBoolean(Value);
end;

{ TDateTimeField }

constructor TDateTimeField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftDateTime);
end;

procedure TDateTimeField.CopyData(Source, Dest: Pointer);
begin
  TDateTime(Dest^) := TDateTime(Source^);
end;

function TDateTimeField.GetAsDateTime: TDateTime;
begin
  if not GetValue(Result) then Result := 0;
end;

function TDateTimeField.GetAsFloat: Double;
begin
  Result := GetAsDateTime;
end;

function TDateTimeField.GetAsString: string;
begin
  GetText(Result, False);
end;

function TDateTimeField.GetAsVariant: Variant;
var
  D: TDateTime;
begin
  if GetValue(D) then Result := VarFromDateTime(D) else Result := Null;
end;

function TDateTimeField.GetDataSize: Integer;
begin
  Result := SizeOf(TDateTime);
end;

function TDateTimeField.GetDefaultWidth: Integer;
begin
  Result := DataSize * 2 + 2;
end;

procedure TDateTimeField.GetText(var Text: string; DisplayText: Boolean);
var
  F: string;
  D: TDateTime;
begin
  if GetValue(D) then
  begin
    if DisplayText and (FDisplayFormat <> '') then
      F := FDisplayFormat
    else
      case DataType of
        ftDate: F := ShortDateFormat;
        ftTime: F := LongTimeFormat;
      end;
    DateTimeToString(Text, F, D);
  end else
    Text := '';
end;

function TDateTimeField.GetValue(var Value: TDateTime): Boolean;
begin
  Result := GetData(@Value, False);
end;

procedure TDateTimeField.SetAsDateTime(Value: TDateTime);
begin
  SetData(@Value, False);
end;

procedure TDateTimeField.SetAsFloat(Value: Double);
begin
  SetAsDateTime(Value);
end;

procedure TDateTimeField.SetAsString(const Value: string);
var
  DateTime: TDateTime;
begin
  if Value = '' then Clear else
  begin
    case DataType of
      ftDate: DateTime := StrToDate(Value);
      ftTime: DateTime := StrToTime(Value);
    else
      DateTime := StrToDateTime(Value);
    end;
    SetAsDateTime(DateTime);
  end;
end;

procedure TDateTimeField.SetDisplayFormat(const Value: string);
begin
  if FDisplayFormat <> Value then
  begin
    FDisplayFormat := Value;
    PropertyChanged(False);
  end;
end;

procedure TDateTimeField.SetVarValue(const Value: Variant);
begin
  SetAsDateTime(VarToDateTime(Value));
end;

{ TSQLTimeStampField }

constructor TSQLTimeStampField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftTimeStamp);
end;

procedure TSQLTimeStampField.CopyData(Source, Dest: Pointer);
begin
  TSQLTimeStamp(Dest^) := TSQLTimeStamp(Source^);
end;

function TSQLTimeStampField.GetAsFloat: Double;
begin
  Result := Double(GetAsDateTime);
end;

function TSQLTimeStampField.GetAsDateTime: TDateTime;
var
  ts: TSQLTimeStamp;
begin
  if not GetValue(ts) then 
    Result := 0 
  else
    Result := SQLTimeStampToDateTime(ts);
end;

function TSQLTimeStampField.GetAsSQLTimeStamp: TSQLTimeStamp;
begin
  if not GetValue(Result) then Result := NullSQLTimeStamp;
end;

function TSQLTimeStampField.GetAsString: string;
begin
  GetText(Result, False);
end;

function TSQLTimeStampField.GetAsVariant: Variant;
var
  D: TSQLTimeStamp;
begin
  if GetValue(D) then
    Result := VarSQLTimeStampCreate(TSQLTimeStamp(D))
  else Result := Null;
end;

function TSQLTimeStampField.GetDataSize: Integer;
begin
  Result := SizeOf(TSQLTimeStamp);
end;

function TSQLTimeStampField.GetDefaultWidth: Integer;
begin
  Result := DataSize * 2 + 2;
end;

procedure TSQLTimeStampField.GetText(var Text: string; DisplayText: Boolean);
var
  F: string;
  D: TSQLTimeStamp;
begin
  if GetValue(D) then
  begin
    if DisplayText and (FDisplayFormat <> '') then
      F := FDisplayFormat
    else
     F := '';
    Text := SQLTimeStampToStr(F, D);
  end else
    Text := '';
end;

function TSQLTimeStampField.GetValue(var Value: TSQLTimeStamp): Boolean;
begin
  Result := GetData(@Value, False);
end;

procedure TSQLTimeStampField.SetAsSQLTimeStamp(const Value: TSQLTimeStamp);
begin
  SetData(@Value, False);
end;

procedure TSQLTimeStampField.SetAsFloat(Value: Double);
begin
  SetAsDateTime(TDateTime(Value));
end;

procedure TSQLTimeStampField.SetAsDateTime(Value: TDateTime);
var
  ts: TSQLTimeStamp;
begin
  if Value = 0 then Clear else
  begin
    ts := DateTimeToSQLTimeStamp(Value);
    SetAsSQLTimeStamp(ts);
  end;
end;

procedure TSQLTimeStampField.SetAsString(const Value: string);
begin
  if Value = '' then Clear else
  SetAsSQLTimeStamp(StrToSQLTimeStamp(Value));
end;

procedure TSQLTimeStampField.SetDisplayFormat(const Value: string);
begin
  if FDisplayFormat <> Value then
  begin
    FDisplayFormat := Value;
    PropertyChanged(False);
  end;
end;

procedure TSQLTimeStampField.SetVarValue(const Value: Variant);
begin
  if VarIsClear(Value) then
    DatabaseError(SUnassignedVar);
  SetAsSqlTimeStamp(VarToSqlTimeStamp(Value));
end;

{ TDateField }

constructor TDateField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftDate);
end;

function TDateField.GetDataSize: Integer;
begin
  Result := SizeOf(Integer);
end;

{ TTimeField }

constructor TTimeField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftTime);
end;

procedure TBinaryField.CopyData(Source, Dest: Pointer);
begin
  POleVariant(Dest)^ := POleVariant(Source)^;
end;

function TTimeField.GetDataSize: Integer;
begin
  Result := SizeOf(Integer);
end;

{ TBinaryField }

constructor TBinaryField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

class procedure TBinaryField.CheckTypeSize(Value: Integer);
begin
  if (Value = 0) then DatabaseError(SInvalidFieldSize);
end;

function TBinaryField.GetAsString: string;
var
  Len: Integer;
  Data: Variant;
  PData: Pointer;
begin
  Data := GetAsByteArray;
  if VarIsNull(Data) then
    Result := ''
  else
  begin
    Len := VarArrayHighBound(Data, 1) + 1;
    PData := VarArrayLock(Data);
    try
      SetLength(Result, Len);
      Move(PData^, Pointer(Result)^, Len);
    finally
      VarArrayUnlock(Data);
    end;
  end;
end;

procedure TBinaryField.SetAsString(const Value: string);
var
  Len: Integer;
  Data: Variant;
  PData: Pointer;
begin
  if Value = '' then Clear else
  begin
    Len := Length(Value);
    if Len > Size then Len := Size;
    Data := VarArrayCreate([0,Len-1], varByte);
    PData := VarArrayLock(Data);
    try
      Move(Pointer(Value)^, PData^, Len);
    finally
      VarArrayUnlock(Data);
    end;
    SetAsByteArray(Data);
  end;
end;

function TBinaryField.GetAsVariant: Variant;
begin
  Result := GetAsByteArray;
end;

procedure TBinaryField.SetVarValue(const Value: Variant);
begin
  SetAsByteArray(Value);
end;

procedure TBinaryField.GetText(var Text: string; DisplayText: Boolean);
begin
  Text := inherited GetAsString;
end;

procedure TBinaryField.SetText(const Value: string);
begin
  raise AccessError('Text');
end;

{ TBytesField }

constructor TBytesField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftBytes);
  Size := 16;
end;

function TBytesField.GetDataSize: Integer;
begin
  Result := Size;
end;

{ TVarBytesField }

constructor TVarBytesField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftVarBytes);
  Size := 16;
end;

function TVarBytesField.GetDataSize: Integer;
begin
  Result := Size + SizeOf(Word) {Length Prefix};
end;

procedure TVarBytesField.SetAsByteArray(const Value: Variant);
var
  Data: Pointer;
begin
  { If size of variant array is equal to data, assume a length prefix is included }
  if VarIsArray(Value) and ((VarArrayHighBound(Value, 1) + 1) = DataSize) then
  begin
    Data := VarArrayLock(Value);
    try
      SetData(Data, True);
    finally
      VarArrayUnlock(Value);
    end
  end else
    inherited;
end;

{ TBCDField }

constructor TBCDField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftBCD);
  Size := 4;
  ValidChars := [DecimalSeparator, '+', '-', '0'..'9'];
end;

class procedure TBCDField.CheckTypeSize(Value: Integer);
begin
  { For BCD fields, the scale is stored in the size property.
    We allow values up to 32 here even though the currency data type
    only supports up to 4 digits of scale.  The developer can check
    for sizes > 4 to determine if the value from the server may have
    been rounded }
  if Value > 32 then DatabaseError(SInvalidFieldSize);
end;

function TBCDField.GetAsBCD: TBcd;
var
  Cur: System.Currency;
begin
  if not GetValue(Cur) then
    Result := NullBcd
  else
    CurrToBcd(Cur, Result);
end;

function TBCDField.GetAsCurrency: Currency;
begin
  if not GetValue(Result) then Result := 0;
end;

function TBCDField.GetAsFloat: Double;
begin
  Result := GetAsCurrency;
end;

function TBCDField.GetAsInteger: Longint;
begin
  Result := Longint(Round(GetAsCurrency));
end;

function TBCDField.GetAsString: string;
var
  C: System.Currency;
begin
  if GetValue(C) then Result := CurrToStr(C) else Result := '';
end;

function TBCDField.GetAsVariant: Variant;
var
  C: System.Currency;
begin
  if GetValue(C) then Result := C else Result := Null;
end;

function TBCDField.GetDataSize: Integer;
begin
  Result := SizeOf(TBcd);
end;

function TBCDField.GetDefaultWidth: Integer;
begin
  if FPrecision > 0 then
    Result := FPrecision + 1 else
    Result := inherited GetDefaultWidth;
end;

procedure TBCDField.GetText(var Text: string; DisplayText: Boolean);
var
  Format: TFloatFormat;
  Digits: Integer;
  FmtStr: string;
  C: System.Currency;
begin
  try
    if GetData(@C, False) then
    begin
      if DisplayText or (EditFormat = '') then
        FmtStr := DisplayFormat else
        FmtStr := EditFormat;
      if FmtStr = '' then
      begin
        if FCurrency then
        begin
          if DisplayText then Format := ffCurrency else Format := ffFixed;
          Digits := CurrencyDecimals;
        end
        else begin
          Format := ffGeneral;
          Digits := 0;
        end;
        Text := CurrToStrF(C, Format, Digits);
      end else
        Text := FormatCurr(FmtStr, C);
    end else
      Text := '';
  except
    on E: Exception do
      Text := SBCDOverflow;
  end;
end;

function TBCDField.GetValue(var Value: Currency): Boolean;
begin
  Result := GetData(@Value, False);
end;


procedure TBCDField.SetAsBCD(const Value: TBcd);
var
  C: System.Currency;
begin
  BcdToCurr(Value,C);
  SetAsCurrency(C);
end;

procedure TBCDField.SetAsCurrency(Value: Currency);
begin
  if FCheckRange and ((Value < FMinValue) or (Value > FMaxValue)) then
    RangeError(Value, FMinValue, FMaxValue);
  SetData(@Value, False);
end;

procedure TBCDField.SetAsFloat(Value: Double);
begin
  SetAsCurrency(Value);
end;

procedure TBCDField.SetAsInteger(Value: Longint);
begin
  SetAsCurrency(Value);
end;

procedure TBCDField.SetAsString(const Value: string);
var
  C: System.Currency;
begin
  if Value = '' then Clear else
  begin
    if not TextToFloat(PChar(Value), C, fvCurrency) then
      DatabaseErrorFmt(SInvalidFloatValue, [Value, DisplayName]);
    SetAsCurrency(C);
  end;
end;

procedure TBCDField.SetCurrency(Value: Boolean);
begin
  if FCurrency <> Value then
  begin
    FCurrency := Value;
    PropertyChanged(False);
  end;
end;

procedure TBCDField.SetMaxValue(Value: Currency);
begin
  FMaxValue := Value;
  UpdateCheckRange;
end;

procedure TBCDField.SetMinValue(Value: Currency);
begin
  FMinValue := Value;
  UpdateCheckRange;
end;

procedure TBCDField.SetPrecision(Value: Integer);
begin
  if (DataSet <> nil) then
    DataSet.CheckInactive;
  if Value < 0 then Value := 0;
  if Value > 32 then Value := 32;
  if FPrecision <> Value then
  begin
    FPrecision := Value;
    PropertyChanged(False);
  end;
end;

procedure TBCDField.SetVarValue(const Value: Variant);
begin
  SetAsCurrency(Value);
end;

procedure TBCDField.UpdateCheckRange;
begin
  FCheckRange := (FMinValue <> 0) or (FMaxValue <> 0);
end;

procedure TBCDField.CopyData(Source, Dest: Pointer);
begin
  System.Currency(Dest^) := System.Currency(Source^);
end;

{ TFMTBCDField }

constructor TFMTBCDField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftFMTBCD);
  Size := 8;
  ValidChars := [DecimalSeparator, '+', '-', '0'..'9'];
  FMinValue := '';
  FMaxValue := '';
end;

class procedure TFMTBCDField.CheckTypeSize(Value: Integer);
begin
  { For BCD fields, the scale is stored in the size property.
    We allow values up to 32 here even though the currency data type
    only supports up to 4 digits of scale.  The developer can check
    for sizes > 4 to determine if the value from the server may have
    been rounded }
  if Value > MAXFMTBcdFractionSize then DatabaseError(SInvalidFieldSize);
end;

function TFMTBCDField.GetAsBCD: TBcd;
begin
  if not GetValue(Result) then
    Result := NullBcd;
end;

function TFMTBCDField.GetAsCurrency: Currency;
begin
  Result := GetAsFloat;
end;

function TFMTBCDField.GetAsFloat: Double;
var
  bcd: TBcd;
begin
  if not GetValue(bcd) then
    Result := 0
  else
    Result := BcdToDouble(bcd);  
end;

function TFMTBCDField.GetAsInteger: Longint;
begin
  Result := Longint(Round(GetAsFloat));
end;

function TFMTBCDField.GetAsString: string;
var
  bcd: TBcd;
begin
  if GetValue(bcd) then Result := BcdToStr(bcd) else Result := '';
end;

function TFMTBCDField.GetAsVariant: Variant;
var
  Bcd: TBcd;
begin
  if GetValue(Bcd) then Result := VarFMTBcdCreate(Bcd) else Result := Null;
end;

function TFMTBCDField.GetDataSize: Integer;
begin
  Result := SizeOf(TBcd);
end;

function TFMTBCDField.GetDefaultWidth: Integer;
begin
  if FPrecision > 0 then
    Result := FPrecision + 1 else
    Result := inherited GetDefaultWidth;
end;

procedure TFMTBCDField.GetText(var Text: string; DisplayText: Boolean);
var
  Format: TFloatFormat;
  Digits: Integer;
  FmtStr: string;
  Bcd: TBcd;
begin
  try
    if GetData(@Bcd, False) then
    begin
      if DisplayText or (EditFormat = '') then
        FmtStr := DisplayFormat else
        FmtStr := EditFormat;
      if FmtStr = '' then
      begin
        if FCurrency then
        begin
          if DisplayText then Format := ffCurrency else Format := ffFixed;
          Digits := CurrencyDecimals;
        end
        else begin
          Format := ffGeneral;
          Digits := 0;
        end;
        Text := BcdToStrF(Bcd, Format, FPrecision, Digits);
      end else
        Text := FormatBcd(FmtStr, Bcd);
    end else
      Text := '';
  except
    on E: Exception do
      Text := SBCDOverflow;
  end;
end;

function TFMTBCDField.GetValue(var Value: TBcd): Boolean;
begin
  Result := GetData(@Value, False);
end;


procedure TFMTBCDField.BcdRangeError(Value: Variant; Max, Min: String);
begin
  DataBaseErrorFmt(sBcdFieldRangeError, [Value, Self.FieldName,
                   Max, Min]);
end;

procedure TFMTBCDField.SetAsBCD(const Value: TBcd);
var
  V, VMax, VMin: Variant;
begin
  V := VarFMTBcdCreate(Value);
  if FCheckRange then
  begin
    VMax := VarFMTBcdCreate(FMaxValue, Self.Precision, Self.Size);
    VMin := VarFMTBcdCreate(FMinValue, Self.Precision, Self.Size);
    if (V < VMin) or (V > VMax) then
      BcdRangeError(V, VMin, VMax);
  end;
  SetData(@Value,False);
end;

procedure TFMTBCDField.SetAsCurrency(Value: Currency);
var
  VMax, VMin: Variant;
  FValue: TBcd;
begin
  CurrToBcd(Value, FValue, MaxBcdPrecision, MaxBcdScale);
  if FCheckRange then
  begin
    VMax := VarFMTBcdCreate(FMaxValue, Self.Precision, Self.Size);
    VMin := VarFMTBcdCreate(FMinValue, Self.Precision, Self.Size);
    if (Value < VMin) or (Value > VMax) then
      BcdRangeError(Value, VMin, VMax);
  end;
  SetData(@FValue, False);
end;

procedure TFMTBCDField.SetAsFloat(Value: Double);
begin
  SetAsCurrency(Value);
end;

procedure TFMTBCDField.SetAsInteger(Value: Longint);
begin
  SetAsCurrency(Value);
end;

procedure TFMTBCDField.SetAsString(const Value: string);
var
  Bcd: TBcd;
begin
  if Value = '' then Clear else
  begin
    Bcd := StrToBcd(Value);
    SetAsBCD(Bcd);
  end;
end;

procedure TFMTBCDField.SetCurrency(Value: Boolean);
begin
  if FCurrency <> Value then
  begin
    FCurrency := Value;
    PropertyChanged(False);
  end;
end;

procedure TFMTBCDField.SetMaxValue(Value: String);
begin
  FMaxValue := Value;
  UpdateCheckRange;
end;

procedure TFMTBCDField.SetMinValue(Value: String);
begin
  FMinValue := Value;
  UpdateCheckRange;
end;

procedure TFMTBCDField.SetPrecision(Value: Integer);
begin
  if (DataSet <> nil) then
    DataSet.CheckInactive;
  if Value < 0 then Value := 0;
  if Value > MaxFMTBcdFractionSize then Value := MaxFMTBcdFractionSize;
  if FPrecision <> Value then
  begin
    FPrecision := Value;
    PropertyChanged(False);
  end;
end;

procedure TFMTBCDField.SetVarValue(const Value: Variant);
begin
  SetAsBCD(VarToBcd(Value));
end;

procedure TFMTBCDField.UpdateCheckRange;
begin
  FCheckRange := (FMinValue <> '') or (FMaxValue <> '');
end;

procedure TFMTBCDField.CopyData(Source, Dest: Pointer);
begin
  TBcd(Dest^) := TBcd(Source^);
end;

{ TBlobField }

constructor TBlobField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftBlob);
  FGraphicHeader := True;
end;

procedure TBlobField.Assign(Source: TPersistent);
var
  StreamPersist: IStreamPersist;
begin
  if Source is TBlobField then
  begin
    LoadFromBlob(TBlobField(Source));
    Exit;
  end;

  if Source is TStrings then
  begin
    LoadFromStrings(TStrings(Source));
    Exit;
  end;

  if SupportsStreamPersist(Source, StreamPersist) then
  begin
    LoadFromStreamPersist(StreamPersist);
    Exit;
  end;

  inherited Assign(Source);
end;

function TBlobField.SupportsStreamPersist(const Persistent: TPersistent;
  var StreamPersist: IStreamPersist): Boolean;
begin
   Result := (Persistent is TInterfacedPersistent) and
     (TInterfacedPersistent(Persistent).QueryInterface(IStreamPersist, StreamPersist) = S_OK);
end;

procedure TBlobField.AssignTo(Dest: TPersistent);
var
  StreamPersist: IStreamPersist;
begin
  if Dest is TStrings then
  begin
    SaveToStrings(TStrings(Dest));
    Exit;
  end;

  if SupportsStreamPersist(Dest, StreamPersist) then
  begin
    SaveToStreamPersist(StreamPersist);
    Exit;
  end;

  inherited AssignTo(Dest);
end;

procedure TBlobField.Clear;
begin
  DataSet.CreateBlobStream(Self, bmWrite).Free;
end;

procedure TBlobField.FreeBuffers;
begin
  if FModified then
  begin
    DataSet.CloseBlob(Self);
    FModified := False;
  end;
end;

function TBlobField.GetAsString: string;
var
  Len: Integer;
begin
  with DataSet.CreateBlobStream(Self, bmRead) do
    try
      Len := Size;
      SetString(Result, nil, Len);
      ReadBuffer(Pointer(Result)^, Len);
    finally
      Free;
    end;
end;

function TBlobField.GetAsVariant: Variant;
begin
  Result := GetAsString;
end;

function TBlobField.GetBlobSize: Integer;
begin
  with DataSet.CreateBlobStream(Self, bmRead) do
    try
      Result := Size;
    finally
      Free;
    end;
end;

function TBlobField.GetClassDesc: string;
begin
  Result := Format('(%s)', [FieldtypeNames[Datatype]]);
  if not IsNull then Result := AnsiUpperCase(Result);
end;

function TBlobField.GetBlobType: TBlobType;
begin
  Result := TBlobType(DataType);
end;

function TBlobField.GetIsNull: Boolean;
begin
  if Modified then
  begin
    with DataSet.CreateBlobStream(Self, bmRead) do
    try
      Result := (Size = 0);
    finally
      Free;
    end;
  end else
    Result := inherited GetIsNull;
end;

function TBlobField.GetModified: Boolean;
begin
  Result := FModified and (FModifiedRecord = DataSet.ActiveRecord);
end;

procedure TBlobField.GetText(var Text: string; DisplayText: Boolean);
begin
  Text := inherited GetAsString;
end;

class function TBlobField.IsBlob: Boolean;
begin
  Result := True;
end;

procedure TBlobField.LoadFromBlob(Blob: TBlobField);
var
  BlobStream: TStream;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmWrite);
  try
    Blob.SaveToStream(BlobStream);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TBlobField.LoadFromStream(Stream: TStream);
begin
  with DataSet.CreateBlobStream(Self, bmWrite) do
  try
    CopyFrom(Stream, 0);
  finally
    Free;
  end;
end;

procedure TBlobField.LoadFromStrings(Strings: TStrings);
var
  BlobStream: TStream;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmWrite);
  try
    Strings.SaveToStream(BlobStream);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.LoadFromStreamPersist(StreamPersist: IStreamPersist);
var
  Header: TGraphicHeader;
  BlobStream: TStream;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmWrite);
  try
    if GraphicHeader and (DataType = ftGraphic) or (DataType = ftTypedBinary) then
    begin
      Header.Count := 1;
      Header.HType := $0100;
      Header.Size := 0;
      BlobStream.Write(Header, SizeOf(Header));
      StreamPersist.SaveToStream(BlobStream);
      Header.Size := BlobStream.Position - SizeOf(Header);
      BlobStream.Position := 0;
      BlobStream.Write(Header, SizeOf(Header));
    end else
      StreamPersist.SaveToStream(BlobStream);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.SaveToFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TBlobField.SaveToStream(Stream: TStream);
var
  BlobStream: TStream;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmRead);
  try
    Stream.CopyFrom(BlobStream, 0);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.SaveToStrings(Strings: TStrings);
var
  BlobStream: TStream;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmRead);
  try
    Strings.LoadFromStream(BlobStream);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.SaveToStreamPersist(StreamPersist: IStreamPersist);
var
  BlobStream: TStream;
  Size: Longint;
  Header: TGraphicHeader;
begin
  BlobStream := DataSet.CreateBlobStream(Self, bmRead);
  try
    Size := BlobStream.Size;
    if Size >= SizeOf(TGraphicHeader) then
    begin
      BlobStream.Read(Header, SizeOf(Header));
      if (Header.Count <> 1) or (Header.HType <> $0100) or
        (Header.Size <> Size - SizeOf(Header)) then
        BlobStream.Position := 0;
    end;
    StreamPersist.LoadFromStream(BlobStream);
  finally
    BlobStream.Free;
  end;
end;

procedure TBlobField.SetAsString(const Value: string);
begin
  with DataSet.CreateBlobStream(Self, bmWrite) do
    try
      WriteBuffer(Pointer(Value)^, Length(Value));
    finally
      Free;
    end;
end;

procedure TBlobField.SetBlobType(Value: TBlobType);
begin
  SetFieldType(Value);
end;

procedure TBlobField.SetFieldType(Value: TFieldType);
begin
  if Value in [Low(TBlobType)..High(TBlobType)] then SetDataType(Value);
end;

procedure TBlobField.SetModified(Value: Boolean);
begin
  FModified := Value;
  if FModified then
    FModifiedRecord := DataSet.ActiveRecord;
end;

procedure TBlobField.SetText(const Value: string);
begin
  raise AccessError('Text');
end;

procedure TBlobField.SetVarValue(const Value: Variant);
begin
  SetAsString(Value);
end;

{ TMemoField }

constructor TMemoField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftMemo);
  Transliterate := True;
end;

{ TGraphicField }

constructor TGraphicField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftGraphic);
end;

{ TObjectField }

constructor TObjectField.Create(AOwner: TComponent);
begin
  FOwnedFields := TFields.Create(nil);
  FFields := FOwnedFields;
  inherited Create(AOwner);
end;

destructor TObjectField.Destroy;
begin
  inherited Destroy;
  FOwnedFields.Free;
end;

procedure TObjectField.ReadUnNamed(Reader: TReader);
begin
  SetUnNamed(Reader.ReadBoolean);
end;

procedure TObjectField.WriteUnNamed(Writer: TWriter);
begin
  Writer.WriteBoolean(UnNamed);
end;

procedure TObjectField.DefineProperties(Filer: TFiler);

  function UnNamedStored: Boolean;
  begin
    if Assigned(Filer.Ancestor) then
      Result := UnNamed <> TObjectField(Filer.Ancestor).UnNamed else
      Result := UnNamed;
  end;

begin
  inherited;
  Filer.DefineProperty('UnNamed', ReadUnNamed, WriteUnNamed, UnNamedStored);
end;

procedure TObjectField.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  Field: TField;
begin
  for I := 0 to FOwnedFields.Count - 1 do
  begin
    Field := FOwnedFields[I];
    if Field.Owner = Root then Proc(Field);
  end;
end;

procedure TObjectField.SetChildOrder(Component: TComponent; Order: Integer);
var
  F: TField;
begin
  F := Component as TField;
  if FFields.IndexOf(F) >= 0 then
    F.Index := Order;
end;

function TObjectField.GetDefaultWidth: Integer;
var
  I: Integer;
begin
  Result := 10;
  if FOwnedFields.Count > 0 then
  begin
    for I := 0 to FOwnedFields.Count - 1 do
      Inc(Result, FOwnedFields[I].GetDefaultWidth);
    Result := Result div 2;
  end;
end;

function TObjectField.GetHasConstraints: Boolean;
var
  I: Integer;
begin
  Result := inherited GetHasConstraints;
  if not Result then
    for I := 0 to FFields.Count - 1 do
    begin
      Result := FFields[I].HasConstraints;
      if Result then Break;
    end;
end;

procedure TObjectField.SetFieldKind(Value: TFieldKind);
var
  I: Integer;
begin
  if FFieldKind <> Value then
  begin
    if (DataSet <> nil) and (DataSet.FDesigner <> nil) then
    with DataSet.Designer do
    begin
      BeginDesign;
      try
        FFieldKind := Value;
        for I := 0 to FFields.Count - 1 do
          FFields[I].FFieldKind := Value;
      finally
        EndDesign;
      end;
    end else
    begin
      CheckInactive;
      FFieldKind := Value;
      for I := 0 to FFields.Count - 1 do
        FFields[I].FFieldKind := Value;
    end;
  end;
end;

procedure TObjectField.DataSetChanged;
var
  I: Integer;
begin
  FOwnedFields.FDataSet := DataSet;
  for I := 0 to FOwnedFields.Count - 1 do
    FOwnedFields[I].DataSet := DataSet;
  if (DataSet <> nil) and not DataSet.ObjectView then
    DataSet.ObjectView := True;
end;

procedure TObjectField.SetDataSet(ADataSet: TDataSet);
begin
  FFields := FOwnedFields;
  inherited SetDataSet(ADataSet);
  DataSetChanged;
end;

procedure TObjectField.SetParentField(AField: TObjectField);
begin
  FFields := FOwnedFields;
  inherited SetParentField(AField);
  DataSetChanged;
end;

class procedure TObjectField.CheckTypeSize(Value: Integer);
begin
  { Size is computed, no validation }
end;

procedure TObjectField.FreeBuffers;
var
  I: Integer;
begin
  for I := 0 to FOwnedFields.Count - 1 do
    FOwnedFields[I].FreeBuffers;
end;

function TObjectField.GetFieldCount: Integer;
begin
  Result := Fields.Count;
end;

function TObjectField.GetFields: TFields;
begin
  Result := FFields;
end;

function TObjectField.GetAsString: string;

  function ValueToStr(const V: Variant): string;
  var
    S: string;
    V2: Variant;
    HighBound, I: Integer;
    Sep: string;
  begin
    Result := '';
    if VarIsArray(V) then
    begin
      HighBound := VarArrayHighBound(V, 1);
      Sep := '';
      for I := 0 to HighBound do
      begin
        V2 := V[I];
        if VarIsArray(V2) then
          S := ValueToStr(V2) else
          S := VarToStr(V2);
        Result := Result + Sep + S;
        if I = 0 then Sep := ListSeparator + ' ';
      end;
    end else
      Result := VarToStr(V);
    if Result <> '' then
      Result := '('+Result+')';
  end;

begin
  if (FFields = FOwnedFields) and (FFields.Count > 0) then
    Result := ValueToStr(GetAsVariant) else
    Result := inherited GetAsString;
end;

function TObjectField.GetFieldValue(Index: Integer): Variant;
begin
  Result := FFields[Index].Value;
end;

procedure TObjectField.SetFieldValue(Index: Integer; const Value: Variant);
begin
  FFields[Index].Value := Value;
end;

function TObjectField.GetAsVariant: Variant;
var
  I: Integer;
begin
  if IsNull then Result := Null else
  begin
    Result := VarArrayCreate([0, FieldCount - 1], varVariant);
    for I := 0 to FieldCount - 1 do
      Result[I] := GetFieldValue(I);
  end;
end;

procedure TObjectField.SetVarValue(const Value: Variant);
var
  Count, I: Integer;
begin
  Count := VarArrayHighBound(Value, 1) + 1;
  if Count > Size then Count := Size;
  for I := 0 to Count - 1  do
    SetFieldValue(I, Value[I]);
end;

procedure TObjectField.SetUnNamed(Value: Boolean);
begin
  FUnNamed := Value;
end;

{ TADTField }

constructor TADTField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFields.OnChange := FieldsChanged;
  SetDataType(ftADT);
end;

procedure TADTField.FieldsChanged(Sender: TObject);
begin
  FTotalSize := 0;
end;

function TADTField.GetSize: Integer;

  procedure CalcTotalSize(Fields: TFields; var TotalSize: Integer);
  var
    I: Integer;
  begin
    Inc(TotalSize, Fields.Count);
    for I := 0 to Fields.Count - 1 do
      if Fields[I].DataType = ftADT then
        CalcTotalSize((Fields[I] as TADTField).Fields, TotalSize);
  end;

begin
  if FTotalSize = 0 then
  begin
    CalcTotalSize(FFields, FTotalSize);
  end;
  Result := FTotalSize;
end;

{ TArrayField }

constructor TArrayField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftArray);
  Size := 10;
end;

procedure TArrayField.Bind(Binding: Boolean);
begin
  inherited Bind(Binding);
  if DataSet.SparseArrays then
    FFields.FSparseFields := FSize;
end;

procedure TArrayField.SetSize(Value: Integer);
begin
  CheckInactive;
  FSize := Value;
end;

{ TDataSetField }

constructor TDataSetField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftDataSet);
end;

destructor TDataSetField.Destroy;
begin
  AssignNestedDataSet(nil);
  FOwnedDataSet.Free;
  inherited Destroy;
end;

procedure TDataSetField.SetIncludeObjectField(Value: Boolean);
begin
  if Assigned(FNestedDataSet) then
    FNestedDataSet.CheckInactive;
  FIncludeObjectField := Value;
end;

procedure TDataSetField.Bind(Binding: Boolean);
begin
  inherited Bind(Binding);
  if Assigned(FNestedDataSet) then
  begin
    if Binding then
    begin
      if FNestedDataSet.State = dsInActive then FNestedDataSet.Open;
    end
    else
      FNestedDataSet.Close;
  end;
end;

function TDataSetField.GetFields: TFields;
begin
  if FNestedDataSet = nil then
    GetNestedDataSet;
  Result := inherited GetFields;
end;

function TDataSetField.GetNestedDataSet: TDataSet;
begin
  if (FNestedDataSet = nil) and not (csReading in DataSet.ComponentState) then
    FNestedDataSet := DataSet.CreateNestedDataSet(Self);
  Result := FNestedDataSet;
end;

procedure TDataSetField.AssignNestedDataSet(Value: TDataSet);
begin
  if Assigned(FNestedDataSet) then
  begin
    FNestedDataSet.Close;
    FNestedDataSet.FDataSetField := nil;
    if Assigned(DataSet) then
      DataSet.NestedDataSets.Remove(FNestedDataSet);
  end;
  if Assigned(Value) then
  begin
    DataSet.NestedDataSets.Add(Value);
    FFields := Value.Fields;
  end else
    FFields := FOwnedFields;
  FNestedDataSet := Value;
end;

function TDataSetField.GetCanModify: Boolean;
begin
  Result := inherited GetCanModify and Assigned(NestedDataSet) and
    FNestedDataSet.Active;
end;

{ TReferenceField }

constructor TReferenceField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftReference);
end;

procedure TReferenceField.Assign(Source: TPersistent);
begin
  { Assign reference from an object table }
  if Source is TDataSet then
    inherited Assign(TDataSet(Source).Fields[0]) else
    inherited Assign(Source);
end;

function TReferenceField.GetDataSize: Integer;
begin
  Result := FSize + 2;
end;

function TVariantField.GetDefaultWidth: Integer;
begin
  Result := 15;
end;

function TReferenceField.GetAsVariant: Variant;
begin
  Result := GetAsByteArray;
end;

procedure TReferenceField.SetVarValue(const Value: Variant);
begin
  SetAsByteArray(Value);
end;

{ TVariantField }

constructor TVariantField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftVariant);
end;

class procedure TVariantField.CheckTypeSize(Value: Integer);
begin
  { No validation }
end;

function TVariantField.GetAsBCD: TBcd;
begin
  Result := VarToBcd(GetAsVariant);
end;

function TVariantField.GetAsBoolean: Boolean;
begin
  Result := GetAsVariant;
end;

function TVariantField.GetAsDateTime: TDateTime;
begin
  Result := GetAsVariant;
end;

function TVariantField.GetAsSqlTimeStamp: TSqlTimeStamp;
begin
  Result := VarToSQLTimeStamp(GetAsVariant);
end;

function TVariantField.GetAsFloat: Double;
begin
  Result := GetAsVariant;
end;

function TVariantField.GetAsInteger: Longint;
begin
  Result := GetAsVariant;
end;

function TVariantField.GetAsString: string;
begin
  Result := VarToStr(GetAsVariant);
end;

function TVariantField.GetAsVariant: Variant;
begin
  if not GetData(@Result) then
    Result := Null;
end;

procedure TVariantField.SetAsBCD(const Value: TBcd);
begin
  SetVarValue(VarFMTBcdCreate(Value));
end;

procedure TVariantField.SetAsBoolean(Value: Boolean);
begin
  SetVarValue(Value);
end;

procedure TVariantField.SetAsDateTime(Value: TDateTime);
begin
  SetVarValue(Value);
end;

procedure TVariantField.SetAsSqlTimeStamp(const Value: TSqlTimeStamp);
begin
  SetVarValue(VarSqlTimeStampCreate(Value));
end;

procedure TVariantField.SetAsFloat(Value: Double);
begin
  SetVarValue(Value);
end;

procedure TVariantField.SetAsInteger(Value: Longint);
begin
  SetVarValue(Value);
end;

procedure TVariantField.SetAsString(const Value: string);
begin
  SetVarValue(Value);
end;

procedure TVariantField.SetVarValue(const Value: Variant);
begin
  SetData(@Value);
end;

{ TInterfaceField }

constructor TInterfaceField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftInterface);
end;

class procedure TInterfaceField.CheckTypeSize(Value: Integer);
begin
  { No validation }
end;

function TInterfaceField.GetAsVariant: Variant;
var
  I: IUnknown;
begin
  I := GetValue;
  if not Assigned(I) then
    Result := Null else
    Result := GetValue;
end;

function TInterfaceField.GetValue: IUnknown;
begin
  if not GetData(@Result) then
    Result := nil;
end;

procedure TInterfaceField.SetValue(const Value: IUnknown);
begin
  SetData(@Value);
end;

procedure TInterfaceField.SetVarValue(const Value: Variant);
begin
  SetValue(IUnknown(Value));
end;

{ TIDispatchField }

constructor TIDispatchField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftIDispatch);
end;

function TIDispatchField.GetValue: IDispatch;
begin
  if not GetData(@Result) then
    Result := nil;
end;

procedure TIDispatchField.SetValue(const Value: IDispatch);
begin
  SetData(@Value);
end;

{ TGuidField }

constructor TGuidField.Create(AOwner: TComponent);
begin
  Size := 38; { Length(GuidString) }
  inherited Create(AOwner);
  SetDataType(ftGuid);
end;

class procedure TGuidField.CheckTypeSize(Value: Integer);
begin
  if Value <> 38 { Length(GuidString) } then
    DatabaseError(SInvalidFieldSize);
end;

function TGuidField.GetAsGuid: TGUID;
var
  S: string;
begin
  S := GetAsString;
  if S <> '' then
    Result := StringToGuid(S) else
    Result := GUID_NULL;
end;

function TGuidField.GetDefaultWidth: Integer;
begin
  Result := 38;
end;

procedure TGuidField.SetAsGuid(const Value: TGUID);
begin
  SetAsString(GuidToString(Value));
end;

{ TAggregateField }

constructor TAggregateField.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetDataType(ftUnknown);
  FVisible := False;
  FFieldKind := fkAggregate;
  FPrecision := 15;
end;

procedure TAggregateField.SetHandle(Value: Pointer);
begin
  FHandle := Value;
end;

function TAggregateField.GetHandle: Pointer;
begin
  Result := FHandle;
end;

procedure TAggregateField.Reset;
begin
  if (DataSet <> nil) and not (csLoading in ComponentState) then
    if DataSet.FDesigner <> nil then
    begin
      DataSet.Designer.BeginDesign;
      try
        DataSet.ResetAggField(Self);
      finally
        DataSet.Designer.EndDesign;
      end;
    end else
      DataSet.CheckInactive;
end;

procedure TAggregateField.SetActive(Value: Boolean);
begin
  if Value <> FActive then
  begin
    FActive := Value;
    try
      Reset;
    except
      FActive := False;
      raise;
    end;
  end;
end;

procedure TAggregateField.SetGroupingLevel(Value: Integer);
var
  Old: Integer;
begin
  if Value <> FGroupingLevel then
  begin
    Old := FGroupingLevel;
    try
      FGroupingLevel := Value;
      Reset;
    except
      FGroupingLevel := Old;
      raise;
    end;
  end;
end;

procedure TAggregateField.SetIndexName(Value: String);
var
  Old: String;
begin
  if Value <> FIndexName then
  begin
    try
      Old := FIndexName;
      FIndexName := Value;
      Reset;
    except
      FIndexName := Old;
      raise;
    end;
  end;
end;

procedure TAggregateField.SetExpression(Value: String);
var
  Old: String;
begin
  if Value <> FExpression then
  begin
    try
      Old := FExpression;
      FExpression := Value;
      Reset;
    except
      FExpression := Old;
      raise;
    end;
  end;
end;

procedure TAggregateField.GetText(var Text: string; DisplayText: Boolean);
var
  Format: TFloatFormat;
  FmtStr: string;
  Digits: Integer;
  V: Variant;
begin
  Text := '';
  V := Dataset.GetAggregateValue(Self);
  if VarIsNull(V) then
    Exit;
  if FResultType in [ftFloat, ftCurrency] then
  begin
    if DisplayText then
      FmtStr := FDisplayFormat;
    if FmtStr = '' then
    begin
      if FCurrency then
      begin
        if DisplayText then Format := ffCurrency else Format := ffFixed;
        Digits := CurrencyDecimals;
      end
      else begin
        Format := ffGeneral;
        Digits := 0;
      end;
      Text := FloatToStrF(V, Format, FPrecision, Digits);
    end else
      Text := FormatFloat(FmtStr, V);
  end else if FResultType in [ftDate, ftTime, ftDatetime] then
  begin
    if DisplayText and (FDisplayFormat <> '') then
      FmtStr := FDisplayFormat
    else
      case DataType of
        ftDate: FmtStr := ShortDateFormat;
        ftTime: FmtStr := LongTimeFormat;
      end;
    DateTimeToString(Text, FmtStr, V);
  end else
    Text := VarToStr(V);
end;

function TAggregateField.GetAsString: string;
begin
  Result := VarToStr(Dataset.GetAggregateValue(Self));
end;

function TAggregateField.GetAsVariant: Variant;
begin
  Result := Dataset.GetAggregateValue(Self);
end;

procedure TAggregateField.SetDisplayFormat(const Value: string);
begin
  if FDisplayFormat <> Value then
  begin
    FDisplayFormat := Value;
    PropertyChanged(False);
  end;
end;

procedure TAggregateField.SetCurrency(Value: Boolean);
begin
  if FCurrency <> Value then
  begin
    FCurrency := Value;
    PropertyChanged(False);
  end;
end;

procedure TAggregateField.SetPrecision(Value: Integer);
begin
  if Value < 2 then Value := 2;
  if Value > 15 then Value := 15;
  if FPrecision <> Value then
  begin
    FPrecision := Value;
    PropertyChanged(False);
  end;
end;


{ TIndexDef }

constructor TIndexDef.Create(Owner: TIndexDefs; const Name, Fields: string;
  Options: TIndexOptions);
begin
  inherited Create(Owner);
  FName := Name;
  FFieldExpression := Fields;
  FOptions := Options;
end;

procedure TIndexDef.Assign(ASource: TPersistent);
var
  S: TIndexDef;
begin
  if ASource is TIndexDef then
  begin
    if Collection <> nil then Collection.BeginUpdate;
    try
      S := TIndexDef(ASource);
      Options := S.Options;
      Name := S.Name;
      Source := S.Source;
      Expression := S.Expression;
      Fields := S.Fields;
      GroupingLevel := S.GroupingLevel;
    finally
      if Collection <> nil then Collection.EndUpdate;
    end;
  end else inherited;
end;

procedure TIndexDef.SetOptions(Value: TIndexOptions);
begin
  if Value <> FOptions then
  begin
    FOptions := Value;
    Changed(False);
  end;
end;

procedure TIndexDef.SetSource(const Value: string);
begin
  if Value <> FSource then
  begin
    FSource := Value;
    Changed(False);
  end;
end;

function TIndexDef.GetExpression: string;
begin
  if ixExpression in Options then Result := FFieldExpression else Result := '';
end;

procedure TIndexDef.SetExpression(const Value: string);
begin
  if (Value <> FFieldExpression) or
    ((Value <> '') and not (ixExpression in Options)) then
  begin
    Include(FOptions, ixExpression);
    FFieldExpression := Value;
    Changed(False);
  end;
end;

function TIndexDef.GetFields: string;
begin
  if ixExpression in Options then Result := '' else Result := FFieldExpression;
end;

procedure TIndexDef.SetFields(const Value: string);
begin
  if (Value <> FFieldExpression) or (ixExpression in Options) then
  begin
    Exclude(FOptions, ixExpression);
    FFieldExpression := Value;
    Changed(False);
  end;
end;

procedure TIndexDef.SetDescFields(const Value: string);
begin
  if Value <> FDescFields then
  begin
    if Value <> '' then
      Include(FOptions, ixDescending);
    FDescFields := Value;
    Changed(False);
  end;
end;

procedure TIndexDef.SetCaseInsFields(const Value: string);
begin
  if Value <> FCaseInsFields then
  begin
    if Value <> '' then
      Include(FOptions, ixCaseInsensitive);
    FCaseInsFields := Value;
    Changed(False);
  end;
end;

function TIndexDef.GetDisplayName: string;
begin
  Result := inherited GetDisplayName;
  if (Result = '') and
     (ixPrimary in FOptions) then
    Result := '<Primary>'; { do not localize }
end;

{ TIndexDefs }

constructor TIndexDefs.Create(ADataSet: TDataSet);
begin
  inherited Create(ADataSet, ADataSet, TIndexDef);
  FDataSet := ADataSet;
end;

function TIndexDefs.AddIndexDef: TIndexDef;
begin
  Result := TIndexDef(inherited Add);
end;

procedure TIndexDefs.Add(const Name, Fields: string; Options: TIndexOptions);
var
  IndexDef: TIndexDef;
begin
  if IndexOf(Name) >= 0 then
    DatabaseErrorFmt(SDuplicateIndexName, [Name], DataSet);
  IndexDef := AddIndexDef;
  IndexDef.Name := Name;
  IndexDef.Fields := Fields;
  IndexDef.Options := Options;
end;

function TIndexDefs.FindIndexForFields(const Fields: string): TIndexDef;
begin
  Result := GetIndexForFields(Fields, False);
  if Result = nil then
    DatabaseErrorFmt(SNoIndexForFields, [Fields], DataSet);
end;

function TIndexDefs.GetIndexForFields(const Fields: string;
  CaseInsensitive: Boolean): TIndexDef;
var
  Exact: Boolean;
  I, L: Integer;
begin
  Update;
  L := Length(Fields);
  Exact := True;
  while True do
  begin
    for I := 0 to Count - 1 do
    begin
      Result := Items[I];
      if (Result.Options * [ixDescending, ixExpression] = []) and
        (not CaseInsensitive or (ixCaseInsensitive in Result.Options)) then
        if Exact then
          if AnsiCompareText(Fields, Result.Fields) = 0 then Exit
          else { not exact match }
        else
          if (AnsiCompareText(Fields, Copy(Result.Fields, 1, L)) = 0) and
            ((Length(Result.Fields) = L) or
            (Result.Fields[L + 1] = ';')) then Exit;
    end;
    if not Exact then Break;
    Exact := False;
  end;
  Result := nil;
end;

function TIndexDefs.Find(const Name: string): TIndexDef;
begin
  Result := TIndexDef(inherited Find(Name));
  if Result = nil then DatabaseErrorFmt(SIndexNotFound, [Name], DataSet);
end;

function TIndexDefs.GetIndexDef(Index: Integer): TIndexDef;
begin
  Result := TIndexDef(inherited Items[Index]);
end;

procedure TIndexDefs.SetIndexDef(Index: Integer; Value: TIndexDef);
begin
  inherited Items[Index] := Value;
end;

procedure TIndexDefs.Update;
begin
  if Assigned(DataSet) then
    UpdateDefs(DataSet.UpdateIndexDefs);
end;

{ TDataLink }

constructor TDataLink.Create;
begin
  inherited Create;
  FBufferCount := 1;
end;

destructor TDataLink.Destroy;
begin
  FActive := False;
  FEditing := False;
  FDataSourceFixed := False;
  SetDataSource(nil);
  inherited Destroy;
end;

procedure TDataLink.UpdateRange;
var
  Min, Max: Integer;
begin
  Min := DataSet.FActiveRecord - FBufferCount + 1;
  if Min < 0 then Min := 0;
  Max := DataSet.FRecordCount - FBufferCount;
  if Max < 0 then Max := 0;
  if Max > DataSet.FActiveRecord then Max := DataSet.FActiveRecord;
  if FFirstRecord < Min then FFirstRecord := Min;
  if FFirstRecord > Max then FFirstRecord := Max;
  if (FFirstRecord <> 0) and
     (DataSet.FActiveRecord - FFirstRecord < FBufferCount - 1) then
    Dec(FFirstRecord);
end;

function TDataLink.GetDataSet: TDataSet;
begin
  if DataSource <> nil then Result := DataSource.DataSet else Result := nil;
end;

procedure TDataLink.SetDataSource(ADataSource: TDataSource);
begin
  if FDataSource <> ADataSource then
  begin
    if FDataSourceFixed then DatabaseError(SDataSourceChange, FDataSource);
    if FDataSource <> nil then FDataSource.RemoveDataLink(Self);
    if ADataSource <> nil then ADataSource.AddDataLink(Self);
  end;
end;

procedure TDataLink.SetReadOnly(Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    UpdateState;
  end;
end;

procedure TDataLink.SetActive(Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if Value then UpdateRange else FFirstRecord := 0;
    ActiveChanged;
  end;
end;

procedure TDataLink.SetEditing(Value: Boolean);
begin
  if FEditing <> Value then
  begin
    FEditing := Value;
    EditingChanged;
  end;
end;

procedure TDataLink.UpdateState;
begin
  SetActive((DataSource <> nil) and (DataSource.State <> dsInactive));
  SetEditing((DataSource <> nil) and (DataSource.State in dsEditModes) and
    not FReadOnly);
end;

procedure TDataLink.UpdateRecord;
begin
  FUpdating := True;
  try
    UpdateData;
  finally
    FUpdating := False;
  end;
end;

function TDataLink.Edit: Boolean;
begin
  if not FReadOnly and (DataSource <> nil) then DataSource.Edit;
  Result := FEditing;
end;

function TDataLink.GetActiveRecord: Integer;
begin
  if DataSource.State = dsSetKey then
    Result := 0 else
    Result := DataSource.DataSet.FActiveRecord - FFirstRecord;
end;

procedure TDataLink.SetActiveRecord(Value: Integer);
begin
  if DataSource.State <> dsSetKey then
    DataSource.DataSet.FActiveRecord := Value + FFirstRecord;
end;

procedure TDataLink.SetBufferCount(Value: Integer);
begin
  if FBufferCount <> Value then
  begin
    FBufferCount := Value;
    if Active then
    begin
      UpdateRange;
      DataSet.UpdateBufferCount;
      UpdateRange;
    end;
  end;
end;

function TDataLink.GetRecordCount: Integer;
begin
  if DataSource.State = dsSetKey then Result := 1 else
  begin
    Result := DataSource.DataSet.FRecordCount;
    if Result > FBufferCount then Result := FBufferCount;
  end;
end;

procedure TDataLink.DataEvent(Event: TDataEvent; Info: Longint);
var
  Active, First, Last, Count: Integer;
begin
  if Event = deUpdateState then UpdateState else
    if FActive then
      case Event of
        deFieldChange, deRecordChange:
          if not FUpdating then RecordChanged(TField(Info));
        deDataSetChange, deDataSetScroll, deLayoutChange:
          begin
            Count := 0;
            if DataSource.State <> dsSetKey then
            begin
              Active := DataSource.DataSet.FActiveRecord;
              First := FFirstRecord + Info;
              Last := First + FBufferCount - 1;
              if Active > Last then Count := Active - Last else
                if Active < First then Count := Active - First;
              FFirstRecord := First + Count;
            end;
            case Event of
              deDataSetChange: DataSetChanged;
              deDataSetScroll: DataSetScrolled(Count);
              deLayoutChange: LayoutChanged;
            end;
          end;
        deUpdateRecord:
          UpdateRecord;
        deCheckBrowseMode:
          CheckBrowseMode;
        deFocusControl:
          FocusControl(TFieldRef(Info));
      end;
end;

procedure TDataLink.ActiveChanged;
begin
end;

procedure TDataLink.CheckBrowseMode;
begin
end;

procedure TDataLink.DataSetChanged;
begin
  RecordChanged(nil);
end;

procedure TDataLink.DataSetScrolled(Distance: Integer);
begin
  DataSetChanged;
end;

procedure TDataLink.EditingChanged;
begin
end;

function TDataLink.ExecuteAction(Action: TBasicAction): Boolean;
begin
  if Action.HandlesTarget(DataSource) then
  begin
    Action.ExecuteTarget(DataSource);
    Result := True;
  end
  else Result := False;
end;

procedure TDataLink.FocusControl(Field: TFieldRef);
begin
end;

procedure TDataLink.LayoutChanged;
begin
  DataSetChanged;
end;

procedure TDataLink.RecordChanged(Field: TField);
begin
end;

function TDataLink.UpdateAction(Action: TBasicAction): Boolean;
begin
  if Action.HandlesTarget(DataSource) then
  begin
    Action.UpdateTarget(DataSource);
    Result := True;
  end
  else Result := False;
end;

procedure TDataLink.UpdateData;
begin
end;

function TDataLink.GetBOF: Boolean;
begin
  Result := DataSet.BOF;
end;

function TDataLink.GetEOF: Boolean;
begin
  Result := DataSet.EOF;
end;

function TDataLink.GetBufferCount: Integer;
begin
  Result := FBufferCount;
end;

function TDataLink.MoveBy(Distance: Integer): Integer;
begin
  Result := DataSet.MoveBy(Distance);
end;

{ TDetailDataLink }

function TDetailDataLink.GetDetailDataSet: TDataSet;
begin
  Result := nil;
end;

{ TMasterDataLink }

constructor TMasterDataLink.Create(DataSet: TDataSet);
begin
  inherited Create;
  FDataSet := DataSet;
  FFields := TList.Create;
end;

destructor TMasterDataLink.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

procedure TMasterDataLink.ActiveChanged;
begin
  FFields.Clear;
  if Active then
    try
      DataSet.GetFieldList(FFields, FFieldNames);
    except
      FFields.Clear;
      raise;
    end;
  if FDataSet.Active and not (csDestroying in FDataSet.ComponentState) then
    if Active and (FFields.Count > 0) then
    begin
      if Assigned(FOnMasterChange) then FOnMasterChange(Self);
    end else
      if Assigned(FOnMasterDisable) then FOnMasterDisable(Self);
end;

procedure TMasterDataLink.CheckBrowseMode;
begin
  if FDataSet.Active then FDataSet.CheckBrowseMode;
end;

function TMasterDataLink.GetDetailDataSet: TDataSet;
begin
  Result := FDataSet;
end;

procedure TMasterDataLink.LayoutChanged;
begin
  ActiveChanged;
end;

procedure TMasterDataLink.RecordChanged(Field: TField);
begin
  if (DataSource.State <> dsSetKey) and FDataSet.Active and
    (FFields.Count > 0) and ((Field = nil) or
    (FFields.IndexOf(Field) >= 0)) and
     Assigned(FOnMasterChange) then
    FOnMasterChange(Self);
end;

procedure TMasterDataLink.SetFieldNames(const Value: string);
begin
  if FFieldNames <> Value then
  begin
    FFieldNames := Value;
    ActiveChanged;
  end;
end;

{ TDataSource }

constructor TDataSource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLinks := TList.Create;
  FEnabled := True;
  FAutoEdit := True;
{$IFDEF MSWINDOWS}
  RPR;
{$ENDIF}
end;

destructor TDataSource.Destroy;
begin
  FOnStateChange := nil;
  SetDataSet(nil);
  while FDataLinks.Count > 0 do RemoveDataLink(FDataLinks.Last);
  FDataLinks.Free;
  inherited Destroy;
end;

procedure TDataSource.Edit;
begin
  if AutoEdit and (State = dsBrowse) then DataSet.Edit;
end;

procedure TDataSource.SetState(Value: TDataSetState);
var
  PriorState: TDataSetState;
begin
  if FState <> Value then
  begin
    PriorState := FState;
    FState := Value;
    NotifyDataLinks(deUpdateState, 0);
    if not (csDestroying in ComponentState) then
    begin
      if Assigned(FOnStateChange) then FOnStateChange(Self);
      if PriorState = dsInactive then
        if Assigned(FOnDataChange) then FOnDataChange(Self, nil);
    end;
  end;
end;

procedure TDataSource.UpdateState;
begin
  if Enabled and (DataSet <> nil) then
    SetState(DataSet.State) else
    SetState(dsInactive);
end;

function TDataSource.IsLinkedTo(DataSet: TDataSet): Boolean;
var
  DataSource: TDataSource;
begin
  Result := True;
  while DataSet <> nil do
  begin
    if (DataSet.DataSetField <> nil) and
       (DataSet.DataSetField.DataSet.GetDataSource = Self) then Exit;
    DataSource := DataSet.GetDataSource;
    if DataSource = nil then Break;
    if DataSource = Self then Exit;
    DataSet := DataSource.DataSet;
  end;
  Result := False;
end;

procedure TDataSource.SetDataSet(ADataSet: TDataSet);
begin
  if IsLinkedTo(ADataSet) then DatabaseError(SCircularDataLink, Self);
  if FDataSet <> nil then FDataSet.RemoveDataSource(Self);
  if ADataSet <> nil then ADataSet.AddDataSource(Self);
end;

procedure TDataSource.SetEnabled(Value: Boolean);
begin
  FEnabled := Value;
  UpdateState;
end;

procedure TDataSource.AddDataLink(DataLink: TDataLink);
begin
  FDataLinks.Add(DataLink);
  DataLink.FDataSource := Self;
  if DataSet <> nil then DataSet.UpdateBufferCount;
  DataLink.UpdateState;
end;

procedure TDataSource.RemoveDataLink(DataLink: TDataLink);
begin
  DataLink.FDataSource := nil;
  FDataLinks.Remove(DataLink);
  DataLink.UpdateState;
  if DataSet <> nil then DataSet.UpdateBufferCount;
end;

procedure TDataSource.NotifyLinkTypes(Event: TDataEvent; Info: Longint;
  LinkType: Boolean);
var
  I: Integer;
begin
  for I := FDataLinks.Count - 1 downto 0 do
    with TDataLink(FDataLinks[I]) do
      if LinkType = VisualControl then
        DataEvent(Event, Info);
end;

procedure TDataSource.NotifyDataLinks(Event: TDataEvent; Info: Longint);
begin
  { Notify non-visual links (i.e. details), before visual controls }
  NotifyLinkTypes(Event, Info, False);
  NotifyLinkTypes(Event, Info, True);
end;

procedure TDataSource.DataEvent(Event: TDataEvent; Info: Longint);
begin
  if Event = deUpdateState then UpdateState else
    if FState <> dsInactive then
    begin
      NotifyDataLinks(Event, Info);
      case Event of
        deFieldChange:
          if Assigned(FOnDataChange) then FOnDataChange(Self, TField(Info));
        deRecordChange, deDataSetChange, deDataSetScroll, deLayoutChange:
          if Assigned(FOnDataChange) then FOnDataChange(Self, nil);
        deUpdateRecord:
          if Assigned(FOnUpdateData) then FOnUpdateData(Self);
      end;
    end;
end;

{ TCheckConstraint }

procedure TCheckConstraint.Assign(Source: TPersistent);
begin
  if Source is TCheckConstraint then
  begin
    ImportedConstraint := TCheckConstraint(Source).ImportedConstraint;
    CustomConstraint := TCheckConstraint(Source).CustomConstraint;
    ErrorMessage := TCheckConstraint(Source).ErrorMessage;
  end
  else inherited Assign(Source);
end;

function TCheckConstraint.GetDisplayName: string;
begin
  Result := ImportedConstraint;
  if Result = '' then Result := CustomConstraint;
  if Result = '' then Result := inherited GetDisplayName;
end;

procedure TCheckConstraint.SetImportedConstraint(const Value: string);
begin
  if ImportedConstraint <> Value then
  begin
    FImportedConstraint := Value;
    Changed(True);
  end;
end;

procedure TCheckConstraint.SetCustomConstraint(const Value: string);
begin
  if CustomConstraint <> Value then
  begin
    FCustomConstraint := Value;
    Changed(True);
  end;
end;

procedure TCheckConstraint.SetErrorMessage(const Value: string);
begin
  if ErrorMessage <> Value then
  begin
    FErrorMessage := Value;
    Changed(True);
  end;
end;

{ TCheckConstraints }

constructor TCheckConstraints.Create(Owner: TPersistent);
begin
  inherited Create(TCheckConstraint);
  FOwner := Owner;
end;

function TCheckConstraints.Add: TCheckConstraint;
begin
  Result := TCheckConstraint(inherited Add);
end;

function TCheckConstraints.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TCheckConstraints.GetItem(Index: Integer): TCheckConstraint;
begin
  Result := TCheckConstraint(inherited GetItem(Index));
end;

procedure TCheckConstraints.SetItem(Index: Integer; Value: TCheckConstraint);
begin
  inherited SetItem(Index, Value);
end;

{ TParams }

constructor TParams.Create;
begin
  FOwner := nil;
  inherited Create(TParam);
end;

constructor TParams.Create(Owner: TPersistent);
begin
  FOwner := Owner;
  inherited Create(TParam);
end;

procedure TParams.Update(Item: TCollectionItem);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].FParamRef := nil;
  inherited Update(Item);
end;

function TParams.GetItem(Index: Integer): TParam;
begin
  Result := TParam(inherited Items[Index]);
  Result := Result.ParamRef;
end;

procedure TParams.SetItem(Index: Integer; Value: TParam);
begin
  inherited SetItem(Index, TCollectionItem(Value));
end;

function TParams.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TParams.GetDataSet: TDataSet;
begin
  if FOwner is TDataSet then
    Result := TDataSet(FOwner) else
    Result := nil;
end;

procedure TParams.AssignTo(Dest: TPersistent);
begin
  if Dest is TParams then TParams(Dest).Assign(Self)
  else inherited AssignTo(Dest);
end;

procedure TParams.AssignValues(Value: TParams);
var
  I: Integer;
  P: TParam;
begin
  for I := 0 to Value.Count - 1 do
  begin
    P := FindParam(Value[I].Name);
    if P <> nil then
      P.Assign(Value[I]);
  end;
end;

procedure TParams.AddParam(Value: TParam);
begin
  Value.Collection := Self;
end;

procedure TParams.RemoveParam(Value: TParam);
begin
  Value.Collection := nil;
end;

function TParams.CreateParam(FldType: TFieldType; const ParamName: string;
  ParamType: TParamType): TParam;
begin
  Result := Add as TParam;
  Result.ParamType := ParamType;
  Result.Name := ParamName;
  Result.DataType :=  FldType;
end;

function TParams.IsEqual(Value: TParams): Boolean;
var
  I: Integer;
begin
  Result := Count = Value.Count;
  if Result then
    for I := 0 to Count - 1 do
    begin
      Result := Items[I].IsEqual(Value.Items[I]);
      if not Result then Break;
    end
end;

function TParams.ParamByName(const Value: string): TParam;
begin
  Result := FindParam(Value);
  if Result = nil then
    DatabaseErrorFmt(SParameterNotFound, [Value], GetDataSet);
end;

function TParams.FindParam(const Value: string): TParam;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Result := TParam(inherited Items[I]);
    if AnsiCompareText(Result.Name, Value) = 0 then Exit;
  end;
  Result := nil;
end;

procedure TParams.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', ReadBinaryData, nil, False);
end;

procedure TParams.ReadBinaryData(Stream: TStream);
var
  I, Temp, NumItems: Integer;
  Buffer: array[0..2047] of Char;
  TempStr: string;
  Version: Word;
  Bool: Boolean;
begin
  Clear;
  with Stream do
  begin
    ReadBuffer(Version, SizeOf(Version));
    if Version > 2 then DatabaseError(SInvalidVersion);
    NumItems := 0;
    if Version = 2 then
      ReadBuffer(NumItems, SizeOf(NumItems)) else
      ReadBuffer(NumItems, 2);
    for I := 0 to NumItems - 1 do
      with TParam(Add) do
      begin
        Temp := 0;
        if Version = 2 then
          ReadBuffer(Temp, SizeOf(Temp)) else
          ReadBuffer(Temp, 1);
        SetLength(TempStr, Temp);
        ReadBuffer(PChar(TempStr)^, Temp);
        Name := TempStr;
        ReadBuffer(FParamType, SizeOf(FParamType));
        ReadBuffer(FDataType, SizeOf(FDataType));
        if DataType <> ftUnknown then
        begin
          Temp := 0;
          if Version = 2 then
            ReadBuffer(Temp, SizeOf(Temp)) else
            ReadBuffer(Temp, 2);
          ReadBuffer(Buffer, Temp);
          if DataType in [ftBlob, ftGraphic..ftTypedBinary,ftOraBlob,ftOraClob] then
            SetBlobData(@Buffer, Temp) else
            SetData(@Buffer);
        end;
        ReadBuffer(Bool, SizeOf(Bool));
        if Bool then FData := NULL;
        ReadBuffer(FBound, SizeOf(FBound));
      end;
  end;
end;

function TParams.GetParamValue(const ParamName: string): Variant;
var
  I: Integer;
  Params: TList;
begin
  if Pos(';', ParamName) <> 0 then
  begin
    Params := TList.Create;
    try
      GetParamList(Params, ParamName);
      Result := VarArrayCreate([0, Params.Count - 1], varVariant);
      for I := 0 to Params.Count - 1 do
        Result[I] := TParam(Params[I]).Value;
    finally
      Params.Free;
    end;
  end else
    Result := ParamByName(ParamName).Value
end;

procedure TParams.SetParamValue(const ParamName: string;
  const Value: Variant);
var
  I: Integer;
  Params: TList;
begin
  if Pos(';', ParamName) <> 0 then
  begin
    Params := TList.Create;
    try
      GetParamList(Params, ParamName);
      for I := 0 to Params.Count - 1 do
        TParam(Params[I]).Value := Value[I];
    finally
      Params.Free;
    end;
  end else
    ParamByName(ParamName).Value := Value;
end;

procedure TParams.GetParamList(List: TList; const ParamNames: string);
var
  Pos: Integer;
begin
  Pos := 1;
  while Pos <= Length(ParamNames) do
    List.Add(ParamByName(ExtractFieldName(ParamNames, Pos)));
end;

function TParams.ParseSQL(SQL: String; DoCreate: Boolean): String;
const
  Literals = ['''', '"', '`'];
var
  Value, CurPos, StartPos: PChar;
  CurChar: Char;
  Literal: Boolean;
  EmbeddedLiteral: Boolean;
  Name: string;

  function NameDelimiter: Boolean;
  begin
    Result := CurChar in [' ', ',', ';', ')', #13, #10];
  end;

  function IsLiteral: Boolean;
  begin
    Result := CurChar in Literals;
  end;

  function StripLiterals(Buffer: PChar): string;
  var
    Len: Word;
    TempBuf: PChar;

    procedure StripChar;
    begin
      if TempBuf^ in Literals then
        StrMove(TempBuf, TempBuf + 1, Len - 1);
      if TempBuf[StrLen(TempBuf) - 1] in Literals then
        TempBuf[StrLen(TempBuf) - 1] := #0;
    end;

  begin
    Len := StrLen(Buffer) + 1;
    TempBuf := AllocMem(Len);
    try
      StrCopy(TempBuf, Buffer);
      StripChar;
      Result := StrPas(TempBuf);
    finally
      FreeMem(TempBuf, Len);
    end;
  end;

begin
  Result := SQL;
  Value := PChar(Result);
  if DoCreate then Clear;
  CurPos := Value;
  Literal := False;
  EmbeddedLiteral := False;
  repeat
    while (CurPos^ in LeadBytes) do Inc(CurPos, 2);
    CurChar := CurPos^;
    if (CurChar = ':') and not Literal and ((CurPos + 1)^ <> ':') then
    begin
      StartPos := CurPos;
      while (CurChar <> #0) and (Literal or not NameDelimiter) do
      begin
        Inc(CurPos);
        while (CurPos^ in LeadBytes) do Inc(CurPos, 2);
        CurChar := CurPos^;
        if IsLiteral then
        begin
          Literal := Literal xor True;
          if CurPos = StartPos + 1 then EmbeddedLiteral := True;
        end;
      end;
      CurPos^ := #0;
      if EmbeddedLiteral then
      begin
        Name := StripLiterals(StartPos + 1);
        EmbeddedLiteral := False;
      end
      else Name := StrPas(StartPos + 1);
      if DoCreate then
        TParam(Add).Name := Name;
      CurPos^ := CurChar;
      StartPos^ := '?';
      Inc(StartPos);
      StrMove(StartPos, CurPos, StrLen(CurPos) + 1);
      CurPos := StartPos;
    end
    else if (CurChar = ':') and not Literal and ((CurPos + 1)^ = ':') then
      StrMove(CurPos, CurPos + 1, StrLen(CurPos) + 1)
    else if IsLiteral then Literal := Literal xor True;
    Inc(CurPos);
  until CurChar = #0;
end;

{ TParam }

constructor TParam.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  ParamType := ptUnknown;
  DataType := ftUnknown;
  FSize := 0;
  FPrecision := 0;
  FNumericScale := 0;
  FData := Unassigned;
  FBound := False;
  FNull := True;
  FNativeStr := '';
end;

constructor TParam.Create(AParams: TParams; AParamType: TParamType);
begin
  Create(AParams);  
  ParamType := AParamType;
end;

function TParam.IsEqual(Value: TParam): Boolean;
begin
  Result := (VarType(FData) = VarType(Value.FData)) and
    (VarIsClear(FData) or (FData = Value.FData)) and
    (Name = Value.Name) and (DataType = Value.DataType) and
    (IsNull = Value.IsNull) and(Bound = Value.Bound) and
    (ParamType = Value.ParamType);
end;

function TParam.IsParamStored: Boolean;
begin
  Result := Bound;
end;

function TParam.ParamRef: TParam;
begin
  if not Assigned(FParamRef) then
    if Assigned(Collection) and (Name <> '') then
      FParamRef := TParams(Collection).ParamByName(Name) else
      FParamRef := Self;
  Result := FParamRef;
end;

function TParam.GetIsNull: Boolean;
begin
  Result := FNull or VarIsNull(FData) or VarIsClear(FData);
end;

function TParam.GetParamType: TParamType;
begin
  Result := ParamRef.FParamType;
end;

procedure TParam.SetParamType(Value: TParamType);
begin
  ParamRef.FParamType := Value;
end;

function TParam.GetDataType: TFieldType;
begin
  Result := ParamRef.FDataType;
end;

procedure TParam.SetDataType(Value: TFieldType);
const
  VarTypeMap: array[TFieldType] of Integer = (varError, varOleStr, varSmallint,
    varInteger, varSmallint, varBoolean, varDouble, varCurrency, varCurrency,
    varDate, varDate, varDate, varOleStr, varOleStr, varInteger, varOleStr,
    varOleStr, varOleStr, varOleStr, varOleStr, varOleStr, varOleStr, varError,
    varOleStr, varOleStr, varError, varError, varError, varError, varError,
    varOleStr, varOleStr, varVariant, varUnknown, varDispatch, varOleStr, varOleStr,varOleStr);
var
  vType: Integer;
begin
  ParamRef.FDataType := Value;
  if Assigned(DataSet) and (csDesigning in DataSet.ComponentState) and
     (not ParamRef.IsNull) then
  begin
    vType := VarTypeMap[Value];
    if vType <> varError then
    try
      VarCast(ParamRef.FData, ParamRef.FData, vType);
    except
      ParamRef.Clear;
    end else
      ParamRef.Clear;
  end else
    ParamRef.Clear;
end;

function TParam.GetDataSize: Integer;
begin
  Result := 0;
  case DataType of
    ftUnknown: DatabaseErrorFmt(SUnknownFieldType, [Name], DataSet);
    ftString, ftFixedChar, ftMemo, ftADT: Result := Length(VarToStr(FData)) + 1;
    ftBoolean: Result := SizeOf(WordBool);
    ftBCD, ftFMTBcd: Result := SizeOf(TBcd);
    ftTimeStamp: Result := SizeOf( TSqlTimeStamp );
    ftDateTime,
    ftCurrency,
    ftFloat: Result := SizeOf(Double);
    ftTime,
    ftDate,
    ftAutoInc,
    ftInteger: Result := SizeOf(Integer);
    ftSmallint: Result := SizeOf(SmallInt);
    ftWord: Result := SizeOf(Word);
    ftBytes, ftVarBytes:
      if VarIsArray(FData) then
        Result := VarArrayHighBound(FData, 1) + 1 else
        Result := 0;
    ftBlob, ftGraphic..ftTypedBinary,ftOraClob,ftOraBlob: Result := Length(VarToStr(FData));
    ftArray, ftDataSet,
    ftReference, ftCursor: Result := 0;
  else
    DatabaseErrorFmt(SBadFieldType, [Name], DataSet);
  end;
end;

procedure TParam.GetData(Buffer: Pointer);
var
  P: Pointer;
begin
  case DataType of
    ftUnknown: DatabaseErrorFmt(SUnknownFieldType, [Name], DataSet);
    ftString, ftFixedChar, ftMemo, ftAdt:
      StrMove(Buffer, PChar(GetAsString), Length(GetAsString) + 1);
    ftSmallint: SmallInt(Buffer^) := GetAsInteger;
    ftWord: Word(Buffer^) := GetAsInteger;
    ftAutoInc,
    ftInteger: Integer(Buffer^) := GetAsInteger;
    ftTime: Integer(Buffer^) := DateTimeToTimeStamp(AsDateTime).Time;
    ftDate: Integer(Buffer^) := DateTimeToTimeStamp(AsDateTime).Date;
    ftDateTime:  Double(Buffer^) := TimeStampToMSecs(DateTimeToTimeStamp(AsDateTime));
    ftBCD: CurrToBCD(AsBCD, TBcd(Buffer^));
    ftFMTBCD: TBcd(Buffer^) := AsFMTBcd;
    ftCurrency,
    ftFloat: Double(Buffer^) := GetAsFloat;
    ftTimeStamp:  TSQLTimeStamp(Buffer^) := AsSQLTimeStamp;
    ftBoolean: Word(Buffer^) := Ord(GetAsBoolean);
    ftBytes, ftVarBytes:
    begin
      if VarIsArray(FData) then
      begin
        P := VarArrayLock(FData);
        try
          Move(P^, Buffer^, VarArrayHighBound(FData, 1) + 1);
        finally
          VarArrayUnlock(FData);
        end;
      end;
    end;
    ftBlob, ftGraphic..ftTypedBinary,ftOraBlob,ftOraClob:
      Move(PChar(GetAsString)^, Buffer^, Length(GetAsString));
    ftArray, ftDataSet,
    ftReference, ftCursor: {Nothing};
  else
    DatabaseErrorFmt(SBadFieldType, [Name], DataSet);
  end;
end;

procedure TParam.SetBlobData(Buffer: Pointer; Size: Integer);
var
  DataStr: string;
begin
  SetLength(DataStr, Size);
  Move(Buffer^, PChar(DataStr)^, Size);
  AsBlob := DataStr;
end;

procedure TParam.SetData(Buffer: Pointer);
var
  Value: Currency;
  TimeStamp: TTimeStamp;
begin
  case DataType of
    ftUnknown: DatabaseErrorFmt(SUnknownFieldType, [Name], DataSet);
    ftString, ftFixedChar: Self.Value := StrPas(Buffer);
    ftWord: AsWord := Word(Buffer^);
    ftSmallint: AsSmallInt := Smallint(Buffer^);
    ftInteger, ftAutoInc: AsInteger := Integer(Buffer^);
    ftTime:
      begin
        TimeStamp.Time := LongInt(Buffer^);
        TimeStamp.Date := DateDelta;
        AsTime := TimeStampToDateTime(TimeStamp);
      end;
    ftDate:
      begin
        TimeStamp.Time := 0;
        TimeStamp.Date := Integer(Buffer^);
        AsDate := TimeStampToDateTime(TimeStamp);
      end;
    ftDateTime:
      begin
        TimeStamp.Time := 0;
        TimeStamp.Date := Integer(Buffer^);
        AsDateTime := TimeStampToDateTime(MSecsToTimeStamp(Double(Buffer^)));
      end;
    ftTimeStamp:
      AsSqlTimeStamp := TSqlTimeStamp(Buffer^);
    ftBCD:
      if BCDToCurr(TBcd(Buffer^), Value) then
        AsBCD := Value else
        AsBCD := 0;
    ftFMTBcd:
      AsFMTBcd := TBcd(Buffer^);
    ftCurrency: AsCurrency := Double(Buffer^);
    ftFloat: AsFloat := Double(Buffer^);
    ftBoolean: AsBoolean := WordBool(Buffer^);
    ftMemo: AsMemo := StrPas(Buffer);
    ftCursor: FData := 0;
    ftBlob, ftGraphic..ftTypedBinary,ftOraBlob,ftOraClob:
      SetBlobData(Buffer, StrLen(PChar(Buffer)));
  else
    DatabaseErrorFmt(SBadFieldType, [Name], DataSet);
  end;
end;

procedure TParam.SetText(const Value: string);
begin
  Self.Value := Value;
end;

procedure TParam.Assign(Source: TPersistent);

  procedure LoadFromStreamPersist(const StreamPersist: IStreamPersist);
  var
    MS: TMemoryStream;
  begin
    MS := TMemoryStream.Create;
    try
      StreamPersist.SaveToStream(MS);
      LoadFromStream(MS, ftGraphic);
    finally
      MS.Free;
    end;
  end;

  procedure LoadFromStrings(Source: TSTrings);
  begin
    AsMemo := Source.Text;
  end;

var
  StreamPersist: IStreamPersist;
begin
  if Source is TParam then
    AssignParam(TParam(Source))
  else if Source is TField then
    AssignField(TField(Source))
  else if Source is TStrings then
    LoadFromStrings(TStrings(Source))
  else if Supports(Source, IStreamPersist, StreamPersist) then
    LoadFromStreamPersist(StreamPersist)
  else
    inherited Assign(Source);
end;

procedure TParam.AssignTo(Dest: TPersistent);
begin
  if Dest is TField then
    TField(Dest).Value := FData else
    inherited AssignTo(Dest);
end;

procedure TParam.AssignParam(Param: TParam);
begin
  if Param <> nil then
  begin
    FDataType := Param.DataType;
    if Param.IsNull then
      Clear else
      Value := Param.FData;
    FBound := Param.Bound;
    Name := Param.Name;
    if ParamType = ptUnknown then ParamType := Param.ParamType;
    Size := Param.Size;
    Precision := Param.Precision;
    NumericScale := Param.NumericScale;
  end;
end;

procedure TParam.AssignFieldValue(Field: TField; const Value: Variant);
begin
  if Field <> nil then
  begin
    if (Field.DataType = ftString) and TStringField(Field).FixedChar then
      DataType := ftFixedChar
    else if (Field.DataType = ftMemo) and (Field.Size > 255) then
      DataType := ftString
    else
      DataType := Field.DataType;
    if VarIsNull(Value) then
      Clear else
      Self.Value := Value;
    Size := Field.DataSize;
    if Field.DataType in [ftBcd, ftFMTBcd] then
      NumericScale := Field.Size;
    FBound := True;
  end;
end;

procedure TParam.AssignField(Field: TField);
begin
  if Field <> nil then
  begin
    AssignFieldValue(Field, Field.Value);
    Name := Field.FieldName;
  end;
end;

procedure TParam.Clear;
begin
  FNull := True;
  FData := Unassigned;
end;

function TParam.GetDataSet: TDataSet;
begin
  if not Assigned(Collection) then
    Result := nil else
    Result := TParams(Collection).GetDataSet;
end;

function TParam.GetDisplayName: string;
begin
  if FName = '' then
    Result := inherited GetDisplayName else
    Result := FName;
end;

procedure TParam.SetAsBoolean(Value: Boolean);
begin
  FDataType := ftBoolean;
  Self.Value := Value;
end;

function TParam.GetAsBoolean: Boolean;
begin
  if IsNull then
    Result := False else
    Result := FData;
end;

procedure TParam.SetAsFloat(const Value: Double);
begin
  FDataType := ftFloat;
  Self.Value := Value;
end;

function TParam.GetAsFloat: Double;
begin
  if IsNull then
    Result := 0 else
    Result := FData;
end;

procedure TParam.SetAsCurrency(const Value: Currency);
begin
  FDataType := ftCurrency;
  Self.Value := Value;
end;

function TParam.GetAsCurrency: Currency;
begin
  if IsNull then
    Result := 0 else
    Result := FData;
end;

procedure TParam.SetAsBCD(const Value: Currency);
begin
  FDataType := ftBCD;
  Self.Value := Value;
end;

function TParam.GetAsBCD: Currency;
begin
  if IsNull then
    Result := 0 else
    Result := FData;
end;

procedure TParam.SetAsFMTBCD(const Value: TBcd);
begin
  FDataType := ftFMTBCD;
  Self.Value := VARFMTBcdCreate(Value);
end;

function TParam.GetAsFMTBCD: TBcd;
begin
  if IsNull then
    Result := NullBcd else
    Result := VarToBcd(FData);
end;

procedure TParam.SetAsSQLTimeStamp(const Value: TSQLTimeStamp);
begin
  FDataType := ftTimeStamp;
  Self.Value := VarSQLTimeStampCreate(Value);
end;

function TParam.GetAsSQLTimeStamp: TSQLTimeStamp;
begin
  if IsNull then
    Result := NullSqlTimeStamp else
    Result := VarToSQLTimeStamp(FData);
end;

procedure TParam.SetAsInteger(Value: Longint);
begin
  FDataType := ftInteger;
  Self.Value := Value;
end;

function TParam.GetAsInteger: Longint;
begin
  if IsNull then
    Result := 0 else
    Result := FData;
end;

procedure TParam.SetAsWord(Value: LongInt);
begin
  FDataType := ftWord;
  Self.Value := Value;
end;

procedure TParam.SetAsSmallInt(Value: LongInt);
begin
  FDataType := ftSmallint;
  Self.Value := Value;
end;

procedure TParam.SetAsString(const Value: string);
begin
  if FDataType <> ftFixedChar then FDataType := ftString;
  Self.Value := Value;
end;

function TParam.GetAsString: string;
begin
  if IsNull then
    Result := ''
  else if DataType = ftBoolean then
  begin
    if FData then
      Result := STextTrue else
      Result := STextFalse;
  end else
    Result := FData;
end;

procedure TParam.SetAsDate(const Value: TDateTime);
begin
  FDataType := ftDate;
  Self.Value := Value;
end;

procedure TParam.SetAsTime(const Value: TDateTime);
begin
  FDataType := ftTime;
  Self.Value := Value
end;

procedure TParam.SetAsDateTime(const Value: TDateTime);
begin
  FDataType := ftDateTime;
  Self.Value := Value
end;

function TParam.GetAsDateTime: TDateTime;
begin
  if IsNull then
    Result := 0 else
    Result := VarToDateTime(FData);
end;

procedure TParam.SetAsVariant(const Value: Variant);
begin
  if ParamRef = Self then
  begin
    FBound := not VarIsClear(Value);
    FNull := VarIsClear(Value) or VarIsNull(Value);
    if FDataType = ftUnknown then
      case VarType(Value) of
        varSmallint, varShortInt, varByte: FDataType := ftSmallInt;
        varWord, varInteger: FDataType := ftInteger;
        varCurrency: FDataType := ftBCD;
        varLongWord, varSingle, varDouble: FDataType := ftFloat;
        varDate: FDataType := ftDateTime;
        varBoolean: FDataType := ftBoolean;
        varString, varOleStr: if FDataType <> ftFixedChar then FDataType := ftString;
        varInt64: FDataType := ftLargeInt;
      else
        if VarType(Value) = varSQLTimeStamp then
          FDataType := ftTimeStamp
        else if VarType(Value) = varFMTBcd then
          FDataType := ftFMTBcd
        else 
          FDataType := ftUnknown;
      end;
    FData := Value;
  end else
    ParamRef.SetAsVariant(Value);
end;

function TParam.GetAsVariant: Variant;
begin
  Result := ParamRef.FData;
end;

procedure TParam.SetAsMemo(const Value: string);
begin
  FDataType := ftMemo;
  Self.Value := Value;
end;

function TParam.GetAsMemo: string;
begin
  if IsNull then
    Result := '' else
    Result := FData;
end;

procedure TParam.SetAsBlob(const Value: TBlobData);
begin
  FDataType := ftBlob;
  Self.Value := Value;
end;

procedure TParam.LoadFromFile(const FileName: string; BlobType: TBlobType);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStream(Stream, BlobType);
  finally
    Stream.Free;
  end;
end;

procedure TParam.LoadFromStream(Stream: TStream; BlobType: TBlobType);
var
  DataStr: string;
  Len: Integer;
begin
  with Stream do
  begin
    FDataType := BlobType;
    Position := 0;
    Len := Size;
    SetLength(DataStr, Len);
    ReadBuffer(Pointer(DataStr)^, Len);
    Self.Value := DataStr;
  end;
end;

{ TDataSet }

constructor TDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsUniDirectional := False;
  FFieldDefs := TFieldDefs.Create(Self);
  FFieldDefList := TFieldDefList.Create(Self);
  FFields := TFields.Create(Self);
  FFieldList := TFieldList.Create(Self);
  FDataSources := TList.Create;
  FAutoCalcFields := True;
  FConstraints := TCheckConstraints.Create(Self);
  FNestedDataSetClass := Self.ClassType;
  FAggFields := TFields.Create(Self);
  FAggFields.ValidFieldKinds := [fkAggregate];
  FFieldNoOfs := 1;
  ClearBuffers;
{$IFDEF MSWINDOWS}
  RPR;
{$ENDIF}
end;

destructor TDataSet.Destroy;
begin
  Destroying;
  Close;
  SetDataSetField(nil);
  FreeAndNil(FDesigner);
  if FDataSources <> nil then
    while FDataSources.Count > 0 do
      RemoveDataSource(FDataSources.Last);
  FreeAndNil(FDataSources);
  FreeAndNil(FFields);
  FreeAndNil(FAggFields);
  FreeAndNil(FFieldList);
  FreeAndNil(FFieldDefList);
  FreeAndNil(FFieldDefs);
  FreeAndNil(FConstraints);
  FreeAndNil(FNestedDataSets);
  inherited Destroy;
end;

procedure TDataSet.SetName(const Value: TComponentName);
var
  OldName: TComponentName;

  procedure RenameFields(Fields: TFields);
  var
    I: Integer;
    Field: TField;
    FieldName, NamePrefix: TComponentName;
  begin
    for I := 0 to Fields.Count - 1 do
    begin
      Field := Fields[I];
      if Field.Owner = Owner then
      begin
        FieldName := Field.Name;
        NamePrefix := FieldName;
        if Length(NamePrefix) > Length(OldName) then
        begin
          SetLength(NamePrefix, Length(OldName));
          if CompareText(OldName, NamePrefix) = 0 then
          begin
            System.Delete(FieldName, 1, Length(OldName));
            System.Insert(Value, FieldName, 1);
            try
              Field.Name := FieldName;
            except
              on EComponentError do {Ignore rename errors };
            end;
          end;
        end;
        if Field.DataType in [ftADT, ftArray] then
          RenameFields(TObjectField(Field).Fields);
      end;
    end;
  end;

begin
  OldName := Name;
  inherited SetName(Value);
  { In design mode the name of the fields should track the data set name }
  if (csDesigning in ComponentState) and (Name <> OldName) then
  begin
    RenameFields(Fields);
    RenameFields(AggFields);
  end;
end;

procedure TDataSet.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  Field: TField;
begin
  for I := 0 to FFields.Count - 1 do
  begin
    Field := FFields[I];
    if Field.Owner = Root then Proc(Field);
  end;
  for I := 0 to FAggFields.Count - 1 do
  begin
    Field := FAggFields[I];
    if Field.Owner = Root then Proc(Field);
  end;
end;

procedure TDataSet.SetChildOrder(Component: TComponent; Order: Integer);
var
  F: TField;
begin
  F := Component as TField;
  if FFields.IndexOf(F) >= 0 then
    F.Index := Order;
end;

procedure TDataSet.Loaded;
begin
  inherited Loaded;
  try
    if FStreamedActive then Active := True;
  except
    if csDesigning in ComponentState then
      InternalHandleException else
      raise;
  end;
end;

procedure TDataSet.SetState(Value: TDataSetState);
begin
  if FState <> Value then
  begin
    FState := Value;
    FModified := False;
    DataEvent(deUpdateState, 0);
  end;
end;

procedure TDataSet.SetModified(Value: Boolean);
begin
  FModified := Value;
end;

function TDataSet.CreateNestedDataSet(DataSetField: TDataSetField): TDataSet;
begin
  Result := TDataSet(NestedDataSetClass.NewInstance);
  Result.Create(DataSetField);
  try
    Result.ObjectView := True;
    Result.DataSetField := DataSetField;
  except
    Result.Free;
    raise;
  end;
end;

procedure TDataSet.SetDataSetField(const Value: TDataSetField);
begin
  if Value <> FDataSetField then
  begin
    if (Value <> nil) and ((Value.DataSet = Self) or
       ((Value.DataSet.GetDataSource <> nil) and
        (Value.DataSet.GetDataSource.DataSet = Self))) then
      DatabaseError(SCircularDataLink, Self);
    if Assigned(Value) and not InheritsFrom(Value.DataSet.FNestedDataSetClass) then
      DatabaseErrorFmt(SNestedDataSetClass, [Value.DataSet.FNestedDataSetClass.ClassName], Self);
    if Active then Close;
    if Assigned(FDataSetField) then
      FDataSetField.AssignNestedDataSet(nil);
    FDataSetField := Value;
    if Assigned(Value) then
    begin
      Value.AssignNestedDataSet(Self);
      if Value.DataSet.Active then Open;
    end;
  end;
end;

function TDataSet.GetNestedDataSets: TList;
begin
  if FNestedDataSets = nil then
    FNestedDataSets := TList.Create;
  Result := FNestedDataSets;
end;

function TDataSet.GetFound: Boolean;
begin
  Result := FFound;
end;

procedure TDataSet.SetFound(const Value: Boolean);
begin
  FFound := Value;
end;

procedure TDataSet.SetObjectView(const Value: Boolean);
begin
  CheckInactive;
  FObjectView := Value;
end;

procedure TDataSet.SetSparseArrays(Value: Boolean);
begin
  CheckInactive;
  FSparseArrays := Value;
end;

procedure TDataSet.SetConstraints(Value: TCheckConstraints);
begin
  FConstraints.Assign(Value);
end;

procedure TDataSet.SetUniDirectional(const Value: Boolean);
begin
  FIsUnidirectional := Value;
end;

function TDataSet.SetTempState(const Value: TDataSetState): TDataSetState;
begin
  Result := FState;
  FState := Value;
  Inc(FDisableCount);
  FModified := False;
end;

procedure TDataSet.RestoreState(const Value: TDataSetState);
begin
  FState := Value;
  Dec(FDisableCount);
  FModified := False;
end;

procedure TDataSet.Open;
begin
  Active := True;
end;

procedure TDataSet.Close;
begin
  Active := False;
end;

procedure TDataSet.CheckBiDirectional;
begin
  if IsUniDirectional then DatabaseError(SDataSetUniDirectional, Self);
end;

procedure TDataSet.CheckInactive;
begin
  if Active then
    if ([csUpdating, csDesigning] * ComponentState) <> [] then
      Close else
      DatabaseError(SDataSetOpen, Self);
end;

procedure TDataSet.CheckActive;
begin
  if State = dsInactive then DatabaseError(SDataSetClosed, Self);
end;

function TDataSet.GetActive: Boolean;
begin
  Result := not (State in [dsInactive, dsOpening]);
end;

procedure TDataSet.SetActive(Value: Boolean);
begin
  if (csReading in ComponentState) then
  begin
    FStreamedActive := Value;
  end
  else
    if Active <> Value then
    begin
      if Value then
      begin
        DoBeforeOpen;
        try
          OpenCursor;
        finally
          if State <> dsOpening then
            OpenCursorComplete;
        end;
      end else
      begin
        if not (csDestroying in ComponentState) then DoBeforeClose;
        SetState(dsInactive);
        CloseCursor;
        if not (csDestroying in ComponentState) then DoAfterClose;
      end;
    end;
end;

procedure TDataSet.DoInternalOpen;
begin
  FDefaultFields := FieldCount = 0;
  InternalOpen;
  FInternalOpenComplete := True;
  UpdateBufferCount;
  FBOF := True;
end;

procedure TDataSet.OpenCursorComplete;
begin
  try
    if State = dsOpening then
      DoInternalOpen;
  finally
    if FInternalOpenComplete then
    begin
      SetState(dsBrowse);
      DoAfterOpen;
    end else
    begin
      SetState(dsInactive);
      CloseCursor;
    end;
  end;
end;

procedure TDataSet.OpenCursor(InfoQuery: Boolean = False);
begin
  if InfoQuery then
    InternalInitFieldDefs
  else if State <> dsOpening then
    DoInternalOpen;
end;

procedure TDataSet.CloseCursor;
begin
  BlockReadSize := 0;
  FInternalOpenComplete := False;
  FreeFieldBuffers;
  ClearBuffers;
  SetBufListSize(0);
  InternalClose;
  FBufferCount := 0;
  FDefaultFields := False;
end;

procedure TDataSet.OpenParentDataSet(ParentDataSet: TDataSet);
begin
  if not ParentDataSet.IsCursorOpen then
  begin
    { Temporarily set the our State to dsOpening to prevent recursive calls to
      Open by TDataSetField.Bind }
    FState := dsOpening;
    try
      ParentDataSet.Open;
    finally
      FState := dsInActive;
    end;
  end;
  if ParentDataSet.State <> dsInsert then
    ParentDataSet.UpdateCursorPos;
end;

{ Provider helpers }

procedure TDataSet.GetDetailDataSets(List: TList);
var
  I, J: Integer;
begin
  List.Clear;
  for I := FDataSources.Count - 1 downto 0 do
    with TDataSource(FDataSources[I]) do
      for J := FDataLinks.Count - 1 downto 0 do
        if (TDataLink(FDataLinks[J]) is TDetailDataLink) and
           (TDetailDataLink(FDataLinks[J]).DetailDataSet <> nil) and
           (TDetailDataLink(FDataLinks[J]).DetailDataSet.DataSetField = nil) then
          List.Add(TDetailDataLink(FDataLinks[J]).DetailDataSet);
end;

procedure TDataSet.GetDetailLinkFields(MasterFields, DetailFields: TList);
begin
end;

{ Field Management }

procedure TDataSet.DefChanged(Sender: TObject);
begin
end;

procedure TDataSet.InitFieldDefs;
begin
  if IsCursorOpen or (Assigned(FDesigner) and FDesigner.FSaveActive) then
    InternalInitFieldDefs
  else
    try
      OpenCursor(True);
    finally
      CloseCursor;
    end;
end;

procedure TDataSet.InitFieldDefsFromFields;

  procedure CreateFieldDefs(Fields: TFields; FieldDefs: TFieldDefs);
  var
    I: Integer;
    F: TField;
    FieldDef: TFieldDef;
  begin
    for I := 0 to Fields.Count - 1 do
    begin
      F := Fields[I];
      with F do
      if FieldKind = fkData then
      begin
        FieldDef := FieldDefs.AddFieldDef;
        FieldDef.Name := FieldName;
        FieldDef.DataType := DataType;
        FieldDef.Size := Size;
        if Required then
          FieldDef.Attributes := [faRequired];
        if ReadOnly then
          FieldDef.Attributes := FieldDef.Attributes + [faReadonly];
        if (DataType = ftBCD) and (F is TBCDField) then
          FieldDef.Precision := TBCDField(F).Precision
        else if (DataType = ftFMTBcd) and (F is TFMTBCDField) then
          FieldDef.Precision := TFMTBCDField(F).Precision;
        if F is TObjectField then
          CreateFieldDefs(TObjectField(F).Fields, FieldDef.ChildDefs);
      end;
    end;
  end;

begin
  { Create FieldDefs from persistent fields if needed }
  if FieldDefs.Count = 0 then
  begin
    Inc(FieldDefs.FInternalUpdateCount);
    FieldDefs.BeginUpdate;
    try
      CreateFieldDefs(FFields, FieldDefs);
    finally
      FieldDefs.EndUpdate;
      Dec(FieldDefs.FInternalUpdateCount);
    end;
  end;
end;

procedure TDataSet.SetFieldDefs(Value: TFieldDefs);
begin
  FieldDefs.Assign(Value);
end;

function TDataSet.GetFieldClass(FieldType: TFieldType): TFieldClass;
begin
  Result := DefaultFieldClasses[FieldType];
end;

function TDataSet.GetFieldFullName(Field: TField): string;
var
  ParentField: TObjectField;
begin
  Result := Field.FieldName;
  ParentField := Field.ParentField;
  while ParentField <> nil do
  begin
    if (ParentField.DataType <> ftArray) and not ParentField.UnNamed then
      Result := Format('%s.%s', [ParentField.FieldName, Result]);
    ParentField := ParentField.ParentField;
  end;
end;

procedure TDataSet.CreateFields;
var
  I: Integer;

  procedure SetKeyFields;
  var
    Pos, j: Integer;
    KeyFields, FieldName: string;
  begin
    KeyFields := PSGetKeyFields;
    Pos := 1;
    while Pos <= Length(KeyFields) do
    begin
      FieldName := ExtractFieldName(KeyFields, Pos);
      for j := 0 to FieldCount - 1 do
        if AnsiCompareText(FieldName, Fields[j].FieldName) = 0 then
        begin
          Fields[j].ProviderFlags := Fields[j].ProviderFlags + [pfInKey];
          break;
        end;
    end;
  end;

begin
  if ObjectView then
  begin
    for I := 0 to FieldDefs.Count - 1 do
      with FieldDefs[I] do
        if (DataType <> ftUnknown) and
          not ((faHiddenCol in Attributes) and not FIeldDefs.HiddenFields) then
          CreateField(Self);
  end else
  begin
    for I := 0 to FieldDefList.Count - 1 do
      with FieldDefList[I] do
        if (DataType <> ftUnknown) and not (DataType in ObjectFieldTypes) and
          not ((faHiddenCol in Attributes) and not FIeldDefs.HiddenFields) then
          CreateField(Self, nil, FieldDefList.Strings[I]);
  end;
  SetKeyFields;
end;

procedure TDataSet.DestroyFields;
begin
  FFields.Clear;
  if Assigned(FNestedDataSets) then
    FNestedDataSets.Clear;
end;

procedure TDataSet.CheckFieldCompatibility(Field: TField; FieldDef: TFieldDef);
const
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftInteger, ftInteger, ftInteger, ftBoolean, ftFloat,
    ftFloat, ftBCD, ftDateTime, ftDateTime, ftDateTime, ftBytes, ftVarBytes,
    ftInteger, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftUnknown,
    ftString, ftUnknown, ftLargeInt, ftADT, ftArray, ftReference, ftDataSet,
    ftBlob, ftBlob, ftVariant, ftInterface, ftInterface, ftString, ftTimeStamp, ftFMTBcd);

  CheckTypeSizes = [ftBytes, ftVarBytes, ftBCD, ftReference];

begin
  with Field do
  begin
    if (BaseFieldTypes[DataType] <> BaseFieldTypes[FieldDef.DataType]) then
      DatabaseErrorFmt(SFieldTypeMismatch, [DisplayName,
        FieldTypeNames[DataType], FieldTypeNames[FieldDef.DataType]], Self);
    if (DataType in CheckTypeSizes) and (Size <> FieldDef.Size) then
        DatabaseErrorFmt(SFieldSizeMismatch, [DisplayName, Size,
          FieldDef.Size], Self);
  end;
end;

procedure TDataSet.BindFields(Binding: Boolean);
const
  CalcFieldTypes = [ftString, ftSmallint, ftInteger, ftWord, ftBoolean,
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftDate, ftTime, ftDateTime,
    ftTimeStamp, ftVariant, ftLargeInt, ftWideString];

  procedure DoBindFields(Fields: TFields);
  var
    I, FieldIndex: Integer;
    FieldDef: TFieldDef;
  begin
    for I := 0 to Fields.Count - 1 do
    with Fields[I] do
    begin
      if Binding then
      begin
        if FieldKind in [fkCalculated, fkLookup] then
        begin
          if not (DataType in CalcFieldTypes) then
            DatabaseErrorFmt(SInvalidCalcType, [DisplayName], Self);
          FFieldNo := -1;
          FOffset := FCalcFieldsSize;
          Inc(FCalcFieldsSize, DataSize + 1);
        end else
        if FieldKind = fkAggregate then
          FFieldNo := -1
        else
        begin
          FieldDef := nil;
          FieldIndex := FieldDefList.IndexOf(FullName);
          if FieldIndex <> -1 then
            FieldDef := FieldDefList[FieldIndex] else
            DatabaseErrorFmt(SFieldNotFound, [DisplayName], Self);
          if FieldKind = fkInternalCalc then
            FFieldNo := FieldDef.FieldNo else
            FFieldNo := FieldIndex + FFieldNoOfs;
          CheckFieldCompatibility(Fields[I], FieldDef);
          if FieldDef.InternalCalcField then
            FInternalCalcFields := True;
          if IsBlob then
          begin
            FSize := FieldDef.Size;
            FOffset := FBlobFieldCount;
            Inc(FBlobFieldCount);
          end;
        end;
        Bind(True);
      end else
      begin
        Bind(False);
        FFieldNo := 0;
      end;
      if Fields[I].DataType in [ftADT, ftArray] then
        DoBindFields(TObjectField(Fields[I]).Fields);
    end;
  end;

begin
  FCalcFieldsSize := 0;
  FBlobFieldCount := 0;
  FInternalCalcFields := False;
  DoBindFields(Fields);
end;

procedure TDataSet.FreeFieldBuffers;
var
  I: Integer;
begin
  for I := 0 to FFields.Count - 1 do FFields[I].FreeBuffers;
end;

function TDataSet.GetFieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TDataSet.GetBlobFieldData(FieldNo: Integer; var Buffer: TBlobByteData): Integer;
var
  Stream: TStream;
begin
  Stream := CreateBlobStream(FieldByNumber(FieldNo) as TBlobField, bmRead);
  try
    Result := Stream.Size;
    if Result > 0 then
    begin
      if Length(Buffer) <= Result then
        SetLength(Buffer, Result + Result div 4);
      Stream.Read(Buffer[0], Result);
    end;
  finally
    Stream.Free;
  end;
end;

function TDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
end;

function TDataSet.GetFieldData(FieldNo: Integer; Buffer: Pointer): Boolean;
begin
  Result := GetFieldData(FieldByNumber(FieldNo), Buffer);
end;

function TDataSet.GetFieldData(Field: TField; Buffer: Pointer;
  NativeFormat: Boolean): Boolean;
var
  Temp: String;
  pBuff: PChar;
  NativeBuf: array[0..dsMaxStringSize] of Char;
begin
  if NativeFormat then
    Result := GetFieldData(Field, Buffer) else
  if Field.DataSize > dsMaxStringSize then
  begin
    SetLength(Temp, Field.DataSize);
    pBuff := pChar(Temp);
    Result := GetFieldData(Field, pBuff);
    if Field.DataType = ftString then
      SetLength(Temp, strlen(PChar(pBuff)));
    if Result then
      DataConvert(Field, pBuff, Buffer, False);
  end else
  begin
    Result := GetFieldData(Field, @NativeBuf);
    if Result then
      DataConvert(Field, @NativeBuf, Buffer, False);
  end;
end;

procedure TDataSet.SetFieldData(Field: TField; Buffer: Pointer;
  NativeFormat: Boolean);
var
  Temp: String;
  pBuff: PChar;
  NativeBuf: array[0..dsMaxStringSize] of Char;
begin
  if NativeFormat then
    SetFieldData(Field, Buffer)
  else if Field.DataSize > dsMaxStringSize then
  begin
    SetLength(Temp,Field.DataSize);
    pBuff := PChar(Temp);
    if Buffer <> nil then
      DataConvert(Field, Buffer, pBuff, True);
    SetFieldData(Field, pBuff);
  end else
  begin
    if Buffer <> nil then
      DataConvert(Field, Buffer, @NativeBuf, True);
    SetFieldData(Field, @NativeBuf);
  end;
end;

procedure TDataSet.SetFieldData(Field: TField; Buffer: Pointer);
begin
end;

function TDataSet.GetFieldValue(const FieldName: string): Variant;
var
  I: Integer;
  Fields: TList;
begin
  if Pos(';', FieldName) <> 0 then
  begin
    Fields := TList.Create;
    try
      GetFieldList(Fields, FieldName);
      Result := VarArrayCreate([0, Fields.Count - 1], varVariant);
      for I := 0 to Fields.Count - 1 do
        Result[I] := TField(Fields[I]).Value;
    finally
      Fields.Free;
    end;
  end else
    Result := FieldByName(FieldName).Value
end;

procedure TDataSet.SetFieldValue(const FieldName: string;
  const Value: Variant);
var
  I: Integer;
  Fields: TList;
begin
  if Pos(';', FieldName) <> 0 then
  begin
    Fields := TList.Create;
    try
      GetFieldList(Fields, FieldName);
      for I := 0 to Fields.Count - 1 do
        TField(Fields[I]).Value := Value[I];
    finally
      Fields.Free;
    end;
  end else
    FieldByName(FieldName).Value := Value;
end;

function TDataSet.FieldByName(const FieldName: string): TField;
begin
  Result := FindField(FieldName);
  if Result = nil then DatabaseErrorFmt(SFieldNotFound, [FieldName], Self);
end;

function TDataSet.FieldByNumber(FieldNo: Integer): TField;
begin
  Result := FFields.FieldByNumber(FieldNo);
end;

function TDataSet.FindField(const FieldName: string): TField;
begin
  Result := FFields.FindField(FieldName);
  if (Result = nil) and ObjectView then
    Result := FieldList.Find(FieldName);
  if Result = nil then
    Result := FAggFields.FindField(FieldName);
end;

procedure TDataSet.GetFieldNames(List: TStrings);
begin
  if FFields.Count > 0 then
    List.Assign(FieldList)
  else
  begin
    FieldDefs.Update;
    List.Assign(FieldDefList);
  end;
end;

function TDataSet.GetStateFieldValue(State: TDataSetState; Field: TField): Variant;
var
  SaveState: TDataSetState;
begin
  if Field.FieldKind in [fkData, fkInternalCalc] then
  begin
    SaveState := FState;
    FState := State;
    try
      Result := Field.AsVariant;
    finally
      FState := SaveState;
    end;
  end else
    Result := NULL;
end;

procedure TDataSet.SetStateFieldValue(State: TDataSetState; Field: TField; const Value: Variant);
var
  SaveState: TDataSetState;
begin
  if Field.FieldKind <> fkData then Exit;
  SaveState := FState;
  FState := State;
  try
    Field.AsVariant := Value;
  finally
    FState := SaveState;
  end;
end;

procedure TDataSet.CloseBlob(Field: TField);
begin
end;

function TDataSet.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
begin
  Result := nil;
end;

procedure TDataSet.SetDefaultFields(const Value: Boolean);
begin
  FDefaultFields := Value;
end;

procedure TDataSet.DataConvert(Field: TField; Source, Dest: Pointer; ToNative: Boolean);

  { DateTime Conversions }

  function NativeToDateTime(DataType: TFieldType; Data: TDateTimeRec): TDateTime;
  var
    TimeStamp: TTimeStamp;
  begin
    case DataType of
      ftDate:
        begin
          TimeStamp.Time := 0;
          TimeStamp.Date := Data.Date;
        end;
      ftTime:
        begin
          TimeStamp.Time := Data.Time;
          TimeStamp.Date := DateDelta;
        end;
    else
      try
        TimeStamp := MSecsToTimeStamp(Data.DateTime);
      except
        TimeStamp.Time := 0;
        TimeStamp.Date := 0;
      end;
    end;
    Result := TimeStampToDateTime(TimeStamp);
  end;

  function DateTimeToNative(DataType: TFieldType; Data: TDateTime): TDateTimeRec;
  var
    TimeStamp: TTimeStamp;
  begin
    TimeStamp := DateTimeToTimeStamp(Data);
    case DataType of
      ftDate: Result.Date := TimeStamp.Date;
      ftTime: Result.Time := TimeStamp.Time;
    else
      Result.DateTime := TimeStampToMSecs(TimeStamp);
    end;
  end;

  { Byte Field Conversions }

  procedure BufferToByteArray(Data: Pointer; DataSize: Integer; var VarArray: OleVariant);
  var
    PVarData: Pointer;
  begin
    VarArray := VarArrayCreate([0, DataSize - 1], varByte);
    PVarData := VarArrayLock(VarArray);
    try
      Move(Data^, PVarData^, DataSize);
    finally
      VarArrayUnlock(VarArray);
    end;
  end;

  procedure ByteArrayToBuffer(const Data: OleVariant; Buffer: Pointer; var DataSize: Word);
  var
    PVarData: Pointer;
  begin
    DataSize := VarArrayHighBound(Data, 1)+1;
    PVarData := VarArrayLock(Data);
    try
      Move(PVarData^, Buffer^, DataSize);
      if DataSize < Field.DataSize then
        FillChar((PChar(Buffer)+DataSize)^, Field.DataSize - DataSize, 0);
    finally
      VarArrayUnlock(Data);
    end;
  end;

var
  DataSize: Word;
begin
  case Field.DataType of
    ftDate, ftTime, ftDateTime:
      if ToNative then
        TDateTimeRec(Dest^) := DateTimeToNative(Field.DataType, TDateTime(Source^)) else
        TDateTime(Dest^) := NativeToDateTime(Field.DataType, TDateTimeRec(Source^));
    ftTimeStamp:
        TSQLTimeStamp(Dest^) := TSQLTimeStamp(Source^);
    ftBCD:
    begin
      if ToNative then
        CurrToBCD(Currency(Source^), TBcd(Dest^), 32, Field.Size) else
        if not BCDToCurr(TBcd(Source^), Currency(Dest^)) then
          raise EOverFlow.CreateFmt(SFieldOutOfRange, [Field.DisplayName]);
      end;
    ftFMTBCD:
      TBcd(Dest^) := TBcd(Source^);
    ftBytes:
      if ToNative then
        ByteArrayToBuffer(POleVariant(Source)^, Dest, DataSize) else
        BufferToByteArray(Source, Field.DataSize, POleVariant(Dest)^);
    ftVarBytes:
      if ToNative then
        ByteArrayToBuffer(POleVariant(Source)^, PChar(Dest)+2, PWord(Dest)^) else
        BufferToByteArray(PChar(Source)+2, PWord(Source)^, POleVariant(Dest)^);
  end;
end;

{ Index Related }

function TDataSet.GetIsIndexField(Field: TField): Boolean;
begin
  Result := False;
end;

procedure TDataSet.UpdateIndexDefs;
begin
end;

{ Datasource/Datalink Interaction }

function TDataSet.GetDataSource: TDataSource;
begin
  Result := nil;
end;

function TDataSet.IsLinkedTo(DataSource: TDataSource): Boolean;
var
  DataSet: TDataSet;
begin
  Result := True;
  while DataSource <> nil do
  begin
    DataSet := DataSource.DataSet;
    if DataSet = nil then Break;
    if DataSet = Self then Exit;
    if (DataSet.DataSetField <> nil) and
       (DataSet.DataSetField.DataSet = Self) then Exit;
    DataSource := DataSet.DataSource;
  end;
  Result := False;
end;

procedure TDataSet.AddDataSource(DataSource: TDataSource);
begin
  FDataSources.Add(DataSource);
  DataSource.FDataSet := Self;
  UpdateBufferCount;
  DataSource.UpdateState;
end;

procedure TDataSet.RemoveDataSource(DataSource: TDataSource);
begin
  DataSource.FDataSet := nil;
  FDataSources.Remove(DataSource);
  DataSource.UpdateState;
  UpdateBufferCount;
end;

procedure TDataSet.DataEvent(Event: TDataEvent; Info: Longint);

  procedure UpdateCalcFields;
  begin
    if State <> dsSetKey then
    begin
      if FInternalCalcFields and (TField(Info).FieldKind = fkData) then
        RefreshInternalCalcFields(ActiveBuffer)
      else if (FCalcFieldsSize <> 0) and FAutoCalcFields and
        (TField(Info).FieldKind = fkData) then
        CalculateFields(ActiveBuffer);
      TField(Info).Change;
    end;
  end;

  procedure NotifyDetails;
  var
    I: Integer;
  begin
    if Assigned(FNestedDataSets) then
    begin
      if State <> dsInsert then UpdateCursorPos;
      for I := 0 to FNestedDataSets.Count - 1 do
        with TDataSet(FNestedDataSets[I]) do
          if Active then DataEvent(deParentScroll, 0);
    end;
    if (State = dsBlockRead) then
      for I := 0 to FDataSources.Count - 1 do
        TDataSource(FDataSources[I]).NotifyLinkTypes(Event, Info, False);
  end;

  procedure CheckNestedBrowseMode;
  var
    I: Integer;
  begin
    if Assigned(FNestedDataSets) then
      for I := 0 to FNestedDataSets.Count - 1 do
        with TDataSet(FNestedDataSets[I]) do
          if Active then CheckBrowseMode;
  end;

var
  I: Integer;
  NotifyDataSources: Boolean;
begin
  NotifyDataSources := not (ControlsDisabled or (State = dsBlockRead));
  case Event of
    deFieldChange:
      begin
        if TField(Info).FieldKind in [fkData, fkInternalCalc] then
          SetModified(True);
        UpdateCalcFields;
      end;
    deFieldListChange:
      FieldList.Updated := False;
    dePropertyChange:
      FieldDefs.Updated := False;
    deCheckBrowseMode:
      CheckNestedBrowseMode;
    deDataSetChange, deDataSetScroll:
      NotifyDetails;
    deLayoutChange:
      begin
        FieldList.Updated := False;
        if ControlsDisabled then
          FEnableEvent := deLayoutChange;
      end;
    deUpdateState:
      if ControlsDisabled then
      begin
        Event := deDisabledStateChange;
        Info := Integer(State <> dsInactive);
        NotifyDataSources := True;
      end;
  end;

  if NotifyDataSources then
  begin
    for I := 0 to FDataSources.Count - 1 do
      TDataSource(FDataSources[I]).DataEvent(Event, Info);
    if FDesigner <> nil then FDesigner.DataEvent(Event, Info);
  end;
end;

function TDataSet.ControlsDisabled: Boolean;
begin
  Result := FDisableCount <> 0;
end;

procedure TDataSet.DisableControls;
begin
  if FDisableCount = 0 then
  begin
    FDisableState := FState;
    FEnableEvent := deDataSetChange;
  end;
  Inc(FDisableCount);
end;

procedure TDataSet.EnableControls;
begin
  if FDisableCount <> 0 then
  begin
    Dec(FDisableCount);
    if FDisableCount = 0 then
    begin
      if FDisableState <> FState then DataEvent(deUpdateState, 0);
      if (FDisableState <> dsInactive) and (FState <> dsInactive) then
        DataEvent(FEnableEvent, 0);
    end;
  end;
end;

procedure TDataSet.UpdateRecord;
begin
  if not (State in dsEditModes) then DatabaseError(SNotEditing, Self);
  DataEvent(deUpdateRecord, 0);
end;

{ Buffer Management }

function TDataSet.AllocRecordBuffer: PChar;
begin
  Result := nil;
end;

procedure TDataSet.FreeRecordBuffer(var Buffer: PChar);
begin
end;

procedure TDataSet.SetBufListSize(Value: Integer);
var
  FBufListSize, I: Integer;
  NewList: TBufferList;
begin
  FBufListSize := High(FBuffers) + 1;
  if FBufListSize <> Value then
  begin
    if Value > 0 then
      SetLength(NewList, Value) else
      NewList := nil;
    if FBufListSize > Value then
    begin
      { Shrinking the list }
      if Value <> 0 then
        Move(Pointer(FBuffers)^, Pointer(NewList)^, Value * SizeOf(PChar));
      { Free the buffers we no longer need }
      for I := Value to FBufListSize - 1 do
        FreeRecordBuffer(FBuffers[I]);
    end else
    begin
      { Growing the list }
      if FBufListSize <> 0 then
        Move(Pointer(FBuffers)^, Pointer(NewList)^, FBufListSize * SizeOf(PChar));
      I := FBufListSize;
      try
        while I < Value do
        begin
          NewList[I] := AllocRecordBuffer;
          Inc(I);
        end;
      except
        while I > FBufListSize do
        begin
          FreeRecordBuffer(NewList[I]);
          Dec(I);
        end;
        raise;
      end;
    end;
    FBuffers := NewList;
  end;
end;

procedure TDataSet.SetBufferCount(Value: Integer);
var
  I, Delta: Integer;
  DataLink: TDataLink;

  procedure AdjustFirstRecord(Delta: Integer);
  var
    DataLink: TDataLink;
  begin
    if Delta <> 0 then
    begin
      DataLink := FFirstDataLink;
      while DataLink <> nil do
      begin
        if DataLink.Active then Inc(DataLink.FFirstRecord, Delta);
        DataLink := DataLink.FNext;
      end;
    end;
  end;

begin
  if FBufferCount <> Value then
  begin
    if (FBufferCount > Value) and (FRecordCount > 0) then
    begin
      Delta := FActiveRecord;
      DataLink := FFirstDataLink;
      while DataLink <> nil do
      begin
        if DataLink.Active and (DataLink.FFirstRecord < Delta) then
          Delta := DataLink.FFirstRecord;
        DataLink := DataLink.FNext;
      end;
      if (Delta + Value) >= Length(FBuffers) then
        Delta := Length(FBuffers) - Value - 1;
      for I := 0 to Value - 1 do MoveBuffer(I + Delta, I);
      Dec(FActiveRecord, Delta);
      if FCurrentRecord <> -1 then Dec(FCurrentRecord, Delta);
      if FRecordCount > Value then FRecordCount := Value;
      AdjustFirstRecord(-Delta);
    end;
    SetBufListSize(Value + 1);
    FBufferCount := Value;
    if not (csDestroying in ComponentState) then
    begin
      GetNextRecords;
      AdjustFirstRecord(GetPriorRecords);
    end;
  end;
end;

procedure TDataSet.UpdateBufferCount;
var
  I, J, MaxBufferCount: Integer;
  DataLink: TDataLink;
begin
  if IsCursorOpen then
  begin
    MaxBufferCount := 1;
    FFirstDataLink := nil;
    for I := FDataSources.Count - 1 downto 0 do
      with TDataSource(FDataSources[I]) do
        for J := FDataLinks.Count - 1 downto 0 do
        begin
          DataLink := FDataLinks[J];
          DataLink.FNext := FFirstDataLink;
          FFirstDataLink := DataLink;
          if DataLink.FBufferCount > MaxBufferCount then
            MaxBufferCount := DataLink.FBufferCount;
        end;
    SetBufferCount(MaxBufferCount);
  end;
end;

procedure TDataSet.SetCurrentRecord(Index: Integer);
var
  Buffer: PChar;
begin
  if (FCurrentRecord <> Index) or (FDataSetField <> nil) then
  begin
    if (DataSetField <> nil) and (DataSetField.DataSet.State <> dsInsert) then
      DataSetField.DataSet.UpdateCursorPos;
    if not IsUniDirectional then
    begin
      Buffer := FBuffers[Index];
      case GetBookmarkFlag(Buffer) of
        bfCurrent,
        bfInserted: InternalSetToRecord(Buffer);
        bfBOF: InternalFirst;
        bfEOF: InternalLast;
      end;
    end;
    FCurrentRecord := Index;
  end;
end;

function TDataSet.GetBuffer(Index: Integer): PChar;
begin
  if Index <= High(FBuffers) then
    Result := FBuffers[Index]
  else
    Result := nil;
end;

function TDataSet.GetNextRecord: Boolean;
var
  GetMode: TGetMode;
begin
  GetMode := gmNext;
  if FRecordCount > 0 then
  begin
    SetCurrentRecord(FRecordCount - 1);
    if (State = dsInsert) and (FCurrentRecord = FActiveRecord) and
      (GetBookmarkFlag(ActiveBuffer) = bfCurrent) then GetMode := gmCurrent;
  end else if (DataSetField <> nil) and (DataSetField.DataSet.State <> dsInsert) then
    DataSetField.DataSet.UpdateCursorPos;
  Result := (GetRecord(GetBuffer(FRecordCount), GetMode, True) = grOK);
  if Result then
  begin
    if FRecordCount = 0 then
      ActivateBuffers
    else
      if FRecordCount < FBufferCount then
        Inc(FRecordCount) else
        MoveBuffer(0, FRecordCount);
    FCurrentRecord := FRecordCount - 1;
    Result := True;
  end else
    CursorPosChanged;
end;

function TDataSet.GetPriorRecord: Boolean;
begin
  CheckBiDirectional;
  if FRecordCount > 0 then SetCurrentRecord(0);
  Result := (GetRecord(GetBuffer(FRecordCount), gmPrior, True) = grOK);
  if Result then
  begin
    if FRecordCount = 0 then
      ActivateBuffers else
    begin
      MoveBuffer(FRecordCount, 0);
      if FRecordCount < FBufferCount then
      begin
        Inc(FRecordCount);
        Inc(FActiveRecord);
      end;
    end;
    FCurrentRecord := 0;
  end else
    CursorPosChanged;
end;

procedure TDataSet.Resync(Mode: TResyncMode);
var
  Count: Integer;
begin
  if not IsUniDirectional then
  begin
    if rmExact in Mode then
    begin
      CursorPosChanged;
      if GetRecord(FBuffers[FRecordCount], gmCurrent, True) <> grOK then
        DatabaseError(SRecordNotFound, Self);
    end else
      if (GetRecord(FBuffers[FRecordCount], gmCurrent, False) <> grOK) and
        (GetRecord(FBuffers[FRecordCount], gmNext, False) <> grOK) and
        (GetRecord(FBuffers[FRecordCount], gmPrior, False) <> grOK) then
      begin
        ClearBuffers;
        DataEvent(deDataSetChange, 0);
        Exit;
      end;
    if rmCenter in Mode then
      Count := (FBufferCount - 1) div 2 else
      Count := FActiveRecord;
    MoveBuffer(FRecordCount, 0);
    ActivateBuffers;
    try
      while (Count > 0) and GetPriorRecord do Dec(Count);
      GetNextRecords;
      GetPriorRecords;
    finally
      DataEvent(deDataSetChange, 0);
    end;
  end;
end;

procedure TDataSet.MoveBuffer(CurIndex, NewIndex: Integer);
var
  Buffer: PChar;
begin
  if (not IsUniDirectional) and (CurIndex <> NewIndex) then
  begin
    Buffer := FBuffers[CurIndex];
    if CurIndex < NewIndex then
      Move(FBuffers[CurIndex + 1], FBuffers[CurIndex],
        (NewIndex - CurIndex) * SizeOf(Pointer))
    else
      Move(FBuffers[NewIndex], FBuffers[NewIndex + 1],
        (CurIndex - NewIndex) * SizeOf(Pointer));
    FBuffers[NewIndex] := Buffer;
  end;
end;

function TDataSet.ActiveBuffer: PChar;
begin
  Result := FBuffers[FActiveRecord];
end;

function TDataSet.TempBuffer: PChar;
begin
  Result := FBuffers[FRecordCount];
end;

procedure TDataSet.ClearBuffers;
begin
  FRecordCount := 0;
  FActiveRecord := 0;
  FCurrentRecord := -1;
  FBOF := True;
  FEOF := True;
end;

procedure TDataSet.ActivateBuffers;
begin
  FRecordCount := 1;
  FActiveRecord := 0;
  FCurrentRecord := 0;
  FBOF := False;
  FEOF := False;
end;

procedure TDataSet.UpdateCursorPos;
begin
  if FRecordCount > 0 then SetCurrentRecord(FActiveRecord);
end;

procedure TDataSet.CursorPosChanged;
begin
  FCurrentRecord := -1;
end;

function TDataSet.GetCurrentRecord(Buffer: PChar): Boolean;
begin
  Result := False;
end;

function TDataSet.GetNextRecords: Integer;
begin
  Result := 0;
  while (FRecordCount < FBufferCount) and GetNextRecord do Inc(Result);
end;

function TDataSet.GetPriorRecords: Integer;
begin
  Result := 0;
  if not IsUniDirectional then
    while (FRecordCount < FBufferCount) and GetPriorRecord do Inc(Result);
end;

procedure TDataSet.InitRecord(Buffer: PChar);
begin
  InternalInitRecord(Buffer);
  ClearCalcFields(Buffer);
  SetBookmarkFlag(Buffer, bfInserted);
end;

function TDataSet.IsEmpty: Boolean;
begin
  Result := FActiveRecord >= FRecordCount;
end;

procedure TDataSet.GetCalcFields(Buffer: PChar);
var
  SaveState: TDataSetState;
begin
  if (FCalcFieldsSize > 0) or FInternalCalcFields then
  begin
    SaveState := FState;
    FState := dsCalcFields;
    try
      CalculateFields(Buffer);
    finally
      FState := SaveState;
    end;
  end;
end;

procedure TDataSet.CalculateFields(Buffer: PChar);
var
  I: Integer;
begin
  FCalcBuffer := Buffer;
  if (State <> dsInternalCalc) and (IsUniDirectional = False) then
  begin
    ClearCalcFields(CalcBuffer);
    for I := 0 to FFields.Count - 1 do
      with FFields[I] do
        if FieldKind = fkLookup then CalcLookupValue;
  end;
  DoOnCalcFields;
end;

procedure TDataSet.ClearCalcFields(Buffer: PChar);
begin
end;

procedure TDataSet.RefreshInternalCalcFields(Buffer: PChar);
var
  I: Integer;
begin
  for I := 0 to FieldCount - 1 do
    with Fields[I] do
      if (FieldKind = fkInternalCalc) then Value := Value;
end;

{ Navigation }

procedure TDataSet.First;
var
  FReopened: boolean;
begin
  CheckBrowseMode;
  DoBeforeScroll;
  FReopened := False;
  if IsUniDirectional then
  begin
    if not BOF then
    begin             // Need to Close and Reopen dataset: (Midas)
       Active := False;
       Active := True;
    end;
    FReopened := True
  end else
    ClearBuffers;
  try
    InternalFirst;
    if not FReopened then
    begin
      GetNextRecord;
      GetNextRecords;
    end;
  finally
    FBOF := True;
    DataEvent(deDataSetChange, 0);
    DoAfterScroll;
  end;
end;

procedure TDataSet.InternalFirst;
begin
end;

procedure TDataSet.InternalLast;
begin
end;

procedure TDataSet.Last;
begin
  CheckBiDirectional;
  CheckBrowseMode;
  DoBeforeScroll;
  ClearBuffers;
  try
    InternalLast;
    GetPriorRecord;
    GetPriorRecords;
  finally
    FEOF := True;
    DataEvent(deDataSetChange, 0);
    DoAfterScroll;
  end;
end;

function TDataSet.MoveBy(Distance: Integer): Integer;
var
  OldRecordCount, ScrollCount, I: Integer;
begin
  CheckBrowseMode;
  Result := 0;
  DoBeforeScroll;
  if ((Distance > 0) and not FEOF) or ((Distance < 0) and not FBOF) then
  begin
    FBOF := False;
    FEOF := False;
    OldRecordCount := FRecordCount;
    ScrollCount := 0;
    try
      while Distance > 0 do
      begin
        if FActiveRecord < FRecordCount - 1 then Inc(FActiveRecord) else
        begin
          if FRecordCount < FBufferCount then I := 0 else I := 1;
          if GetNextRecord then
          begin
            Dec(ScrollCount, I);
            if FActiveRecord < FRecordCount - 1 then Inc(FActiveRecord);
          end else
          begin
            FEOF := True;
            Break;
          end;
        end;
        Dec(Distance);
        Inc(Result);
      end;
      while Distance < 0 do
      begin
        if FActiveRecord > 0 then Dec(FActiveRecord) else
        begin
          if FRecordCount < FBufferCount then I := 0 else I := 1;
          if GetPriorRecord then
          begin
            Inc(ScrollCount, I);
            if FActiveRecord > 0 then Dec(FActiveRecord);
          end else
          begin
            FBOF := True;
            Break;
          end;
        end;
        Inc(Distance);
        Dec(Result);
      end;
    finally
      if FRecordCount <> OldRecordCount then
        DataEvent(deDataSetChange, 0) else
        DataEvent(deDataSetScroll, ScrollCount);
      DoAfterScroll;
    end;
  end;
end;

procedure TDataSet.Next;
begin
  if BlockReadSize > 0 then
    BlockReadNext else
    MoveBy(1);
end;

procedure TDataSet.BlockReadNext;
begin
  MoveBy(1);
end;

procedure TDataSet.Prior;
begin
  MoveBy(-1);
end;

procedure TDataSet.Refresh;
begin
  DoBeforeRefresh;
  CheckBrowseMode;
  UpdateCursorPos;
  try
    InternalRefresh;
  finally
    Resync([]);
    DoAfterRefresh;
  end;
end;

procedure TDataSet.SetBlockReadSize(Value: Integer);
begin
  if Value > 0 then
  begin
    CheckActive;
    SetState(dsBlockRead);
  end else
    if State = dsBlockRead then SetState(dsBrowse);
  FBlockReadSize := Value;
end;

{ Editing }

procedure TDataSet.CheckParentState;
begin
  if DataSetField <> nil then
    DataSetField.DataSet.Edit;
end;

procedure TDataSet.Edit;
begin
  if not (State in [dsEdit, dsInsert]) then
    if FRecordCount = 0 then Insert else
    begin
      CheckBrowseMode;
      CheckCanModify;
      DoBeforeEdit;
      CheckParentState;
      CheckOperation(InternalEdit, FOnEditError);
      GetCalcFields(ActiveBuffer);
      SetState(dsEdit);
      DataEvent(deRecordChange, 0);
      DoAfterEdit;
    end;
end;

procedure TDataSet.Insert;
var
  Buffer: PChar;
  OldCurrent: TBookmarkStr;
begin
  BeginInsertAppend;
  OldCurrent := Bookmark;
  MoveBuffer(FRecordCount, FActiveRecord);
  Buffer := ActiveBuffer;
  InitRecord(Buffer);
  if FRecordCount = 0 then
    SetBookmarkFlag(Buffer, bfBOF) else
    SetBookmarkData(Buffer, Pointer(OldCurrent));
  if FRecordCount < FBufferCount then Inc(FRecordCount);
  InternalInsert;
  EndInsertAppend;
end;

procedure TDataSet.Append;
var
  Buffer: PChar;
begin
  BeginInsertAppend;
  ClearBuffers;
  Buffer := FBuffers[0];
  InitRecord(Buffer);
  SetBookmarkFlag(Buffer, bfEOF);
  FRecordCount := 1;
  FBOF := False;
  GetPriorRecords;
  InternalInsert;
  EndInsertAppend;
end;

procedure TDataSet.Post;
begin
  UpdateRecord;
  case State of
    dsEdit, dsInsert:
      begin
        DataEvent(deCheckBrowseMode, 0);
        DoBeforePost;
        CheckOperation(InternalPost, FOnPostError);
        FreeFieldBuffers;
        SetState(dsBrowse);
        Resync([]);
        DoAfterPost;
      end;
  end;
end;

procedure TDataSet.Cancel;

  procedure CancelNestedDataSets;
  var
    I: Integer;
  begin
    if Assigned(FNestedDataSets) then
      for I := 0 to FNestedDataSets.Count - 1 do
        with TDataSet(FNestedDataSets[I]) do
          if Active then Cancel;
  end;

var
  DoScrollEvents: Boolean;
begin
  case State of
    dsEdit, dsInsert:
      begin
        CancelNestedDataSets;
        DataEvent(deCheckBrowseMode, 0);
        DoBeforeCancel;
        DoScrollEvents := (State = dsInsert);
        if DoScrollEvents then DoBeforeScroll;
        UpdateCursorPos;
        InternalCancel;
        FreeFieldBuffers;
        SetState(dsBrowse);
        Resync([]);
        DoAfterCancel;
        if DoScrollEvents then DoAfterScroll;
      end;
  end;
end;

procedure TDataSet.Delete;
begin
  CheckActive;
  if State in [dsInsert, dsSetKey] then Cancel else
  begin
    if FRecordCount = 0 then DatabaseError(SDataSetEmpty, Self);
    DataEvent(deCheckBrowseMode, 0);
    DoBeforeDelete;
    DoBeforeScroll;
    CheckOperation(InternalDelete, FOnDeleteError);
    FreeFieldBuffers;
    SetState(dsBrowse);
    Resync([]);
    DoAfterDelete;
    DoAfterScroll;
  end;
end;

procedure TDataSet.BeginInsertAppend;
begin
  CheckBrowseMode;
  CheckCanModify;
  DoBeforeInsert;
  CheckParentState;
  DoBeforeScroll;
end;

procedure TDataSet.EndInsertAppend;
begin
  SetState(dsInsert);
  try
    DoOnNewRecord;
  except
    UpdateCursorPos;
    FreeFieldBuffers;
    SetState(dsBrowse);
    Resync([]);
    raise;
  end;
  FModified := False;
  DataEvent(deDataSetChange, 0);
  DoAfterInsert;
  DoAfterScroll;
end;

procedure TDataSet.AddRecord(const Values: array of const; Append: Boolean);
var
  Buffer: PChar;
begin
  BeginInsertAppend;
  if not Append then UpdateCursorPos;
  DisableControls;
  try
    MoveBuffer(FRecordCount, FActiveRecord);
    try
      Buffer := ActiveBuffer;
      InitRecord(Buffer);
      FState := dsInsert;
      try
        DoOnNewRecord;
        DoAfterInsert;
        SetFields(Values);
        DoBeforePost;
        InternalAddRecord(Buffer, Append);
      finally
        FreeFieldBuffers;
        FState := dsBrowse;
        FModified := False;
      end;
    except
      MoveBuffer(FActiveRecord, FRecordCount);
      raise;
    end;
    Resync([]);
    DoAfterPost;
  finally
    EnableControls;
  end;
end;

procedure TDataSet.InsertRecord(const Values: array of const);
begin
  AddRecord(Values, False);
end;

procedure TDataSet.AppendRecord(const Values: array of const);
begin
  AddRecord(Values, True);
end;

procedure TDataSet.CheckOperation(Operation: TDataOperation;
  ErrorEvent: TDataSetErrorEvent);
var
  Done: Boolean;
  Action: TDataAction;
begin
  Done := False;
  repeat
    try
      UpdateCursorPos;
      Operation;
      Done := True;
    except
      on E: EDatabaseError do
      begin
        Action := daFail;
        if Assigned(ErrorEvent) then ErrorEvent(Self, E, Action);
        if Action = daFail then raise;
        if Action = daAbort then SysUtils.Abort;
      end;
    end;
  until Done;
end;

procedure TDataSet.SetFields(const Values: array of const);
var
  I: Integer;
begin
  for I := 0 to High(Values) do Fields[I].AssignValue(Values[I]);
end;

procedure TDataSet.ClearFields;
begin
  if not (State in dsEditModes) then DatabaseError(SNotEditing, Self);
  DataEvent(deCheckBrowseMode, 0);
  FreeFieldBuffers;
  InternalInitRecord(ActiveBuffer);
  if State <> dsSetKey then GetCalcFields(ActiveBuffer);
  DataEvent(deRecordChange, 0);
end;

procedure TDataSet.CheckRequiredFields;
var
  I: Integer;
begin
  for I := 0 to FFields.Count - 1 do
    with FFields[I] do
      if Required and not ReadOnly and (FieldKind = fkData) and IsNull then
      begin
        FocusControl;
        DatabaseErrorFmt(SFieldRequired, [DisplayName]);
      end;
end;

function TDataSet.Translate(Src, Dest: PChar; ToOem: Boolean): Integer;
begin
  if (Src <> nil) then
  begin
    if (Src <> Dest) then
    StrCopy(Dest, Src);
    Result := StrLen(Dest);
  end else
    Result := 0;
end;

{ Editing Stubs }

procedure TDataSet.InternalInitRecord(Buffer: PChar);
begin
end;

procedure TDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
begin
end;

procedure TDataSet.InternalDelete;
begin
end;

procedure TDataSet.InternalPost;
begin
  CheckRequiredFields;
end;

procedure TDataSet.InternalCancel;
begin
end;

procedure TDataSet.InternalEdit;
begin
end;

procedure TDataSet.InternalInsert;
begin
end;

procedure TDataSet.InternalRefresh;
begin
end;

{ Bookmarks }

function TDataSet.BookmarkAvailable: Boolean;
begin
  if IsUniDirectional then Result := False
  else Result := (State in [dsBrowse, dsEdit, dsInsert]) and not IsEmpty
    and (GetBookmarkFlag(ActiveBuffer) = bfCurrent);
end;

function TDataSet.GetBookmark: TBookmark;
begin
  if BookmarkAvailable then
  begin
    GetMem(Result, FBookmarkSize);
    GetBookmarkData(ActiveBuffer, Result);
  end else
    Result := nil;
end;

procedure TDataSet.FreeBookmark(Bookmark: TBookmark);
begin
  FreeMem(Bookmark);
end;

function TDataSet.GetBookmarkStr: TBookmarkStr;
begin
  if BookmarkAvailable then
  begin
    SetLength(Result, BookmarkSize);
    GetBookmarkData(ActiveBuffer, Pointer(Result));
  end else
    Result := '';
end;

procedure TDataSet.SetBookmarkStr(const Value: TBookmarkStr);
begin
  GotoBookmark(Pointer(Value));
end;

procedure TDataSet.GotoBookmark(Bookmark: TBookmark);
begin
  if Bookmark <> nil then
  begin
    CheckBrowseMode;
    DoBeforeScroll;
    InternalGotoBookmark(Bookmark);
    Resync([rmExact, rmCenter]);
    DoAfterScroll;
  end;
end;

{ Bookmark Stubs }

procedure TDataSet.GetBookmarkData(Buffer: PChar; Data: Pointer);
begin
end;

procedure TDataSet.SetBookmarkData(Buffer: PChar; Data: Pointer);
begin
end;

function TDataSet.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
begin
  result := bfCurrent;
end;

procedure TDataSet.SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag);
begin
end;

procedure TDataSet.InternalGotoBookmark(Bookmark: Pointer);
begin
end;

procedure TDataSet.InternalSetToRecord(Buffer: PChar);
begin
end;

function TDataSet.BookmarkValid(Bookmark: TBookmark): Boolean;
begin
  Result := False;
end;

function TDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
begin
  Result := 0;
end;

{ Filter / Locate / Find }

function TDataSet.FindRecord(Restart, GoForward: Boolean): Boolean;
begin
  Result := False;
end;

function TDataSet.FindFirst: Boolean;
begin
  Result := FindRecord(True, True);
end;

function TDataSet.FindLast: Boolean;
begin
  Result := FindRecord(True, False);
end;

function TDataSet.FindNext: Boolean;
begin
  Result := FindRecord(False, True);
end;

function TDataSet.FindPrior: Boolean;
begin
  Result := FindRecord(False, False);
end;

procedure TDataSet.SetFiltered(Value: Boolean);
begin
  if Value = True then CheckBiDirectional;
  FFiltered := Value;
end;

procedure TDataSet.SetFilterOptions(Value: TFilterOptions);
begin
  CheckBiDirectional;
  FFilterOptions := Value;
end;

procedure TDataSet.SetFilterText(const Value: string);
begin
  CheckBiDirectional;
  FFilterText := Value;
end;

procedure TDataSet.SetOnFilterRecord(const Value: TFilterRecordEvent);
begin
  CheckBiDirectional;
  FOnFilterRecord := Value;
end;

function TDataSet.Locate(const KeyFields: string; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
begin
//  CheckBiDirectional;
  Result := False;
end;

function TDataSet.Lookup(const KeyFields: string; const KeyValues: Variant;
  const ResultFields: string): Variant;
begin
//  CheckBiDirectional;
  Result := False;
end;

{ Aggregates }

function TDataSet.GetAggregateValue(Field: TField): Variant;
begin
  Result := NULL;
end;

function TDataSet.GetAggRecordCount(Grp: TGroupPosInd): Integer;
begin
  Result := 0;
end;

procedure TDataSet.ResetAggField(Field: TField);
begin
end;

{ Informational }

procedure TDataSet.CheckBrowseMode;
begin
  CheckActive;
  DataEvent(deCheckBrowseMode, 0);
  case State of
    dsEdit, dsInsert:
      begin
        UpdateRecord;
        if Modified then Post else Cancel;
      end;
    dsSetKey:
      Post;
  end;
end;

function TDataSet.GetCanModify: Boolean;
begin
  Result := True;
end;

procedure TDataSet.CheckCanModify;
begin
  if not CanModify then DatabaseError(SDataSetReadOnly, Self);
end;

procedure TDataSet.GetFieldList(List: TList; const FieldNames: string);
var
  Pos: Integer;
  Field: TField;
begin
  Pos := 1;
  while Pos <= Length(FieldNames) do
  begin
    Field := FieldByName(ExtractFieldName(FieldNames, Pos));
    if Assigned(List) then List.Add(Field);
  end;
end;

function TDataSet.GetRecordCount: Longint;
begin
  Result := -1;
end;

function TDataSet.GetRecNo: Integer;
begin
  Result := -1;
end;

procedure TDataSet.SetRecNo(Value: Integer);
begin
end;

function TDataSet.GetRecordSize: Word;
begin
  Result := 0;
end;

function TDataSet.IsSequenced: Boolean;
begin
  Result := True;
end;

function TDataSet.UpdateStatus: TUpdateStatus;
begin
  Result := usUnmodified;
end;

{ Event Handler Helpers }

procedure TDataSet.DoAfterCancel;
begin
  if Assigned(FAfterCancel) then FAfterCancel(Self);
end;

procedure TDataSet.DoAfterClose;
begin
  if Assigned(FAfterClose) then FAfterClose(Self);
end;

procedure TDataSet.DoAfterDelete;
begin
  if Assigned(FAfterDelete) then FAfterDelete(Self);
end;

procedure TDataSet.DoAfterEdit;
begin
  if Assigned(FAfterEdit) then FAfterEdit(Self);
end;

procedure TDataSet.DoAfterInsert;
begin
  if Assigned(FAfterInsert) then FAfterInsert(Self);
end;

procedure TDataSet.DoAfterOpen;
begin
  if Assigned(FAfterOpen) then FAfterOpen(Self);
  if not IsEmpty then DoAfterScroll;
end;

procedure TDataSet.DoAfterPost;
begin
  if Assigned(FAfterPost) then FAfterPost(Self);
end;

procedure TDataSet.DoAfterRefresh;
begin
  if Assigned(FAfterRefresh) then FAfterRefresh(Self);
end;

procedure TDataSet.DoAfterScroll;
begin
  if Assigned(FAfterScroll) then FAfterScroll(Self);
end;

procedure TDataSet.DoBeforeCancel;
begin
  if Assigned(FBeforeCancel) then FBeforeCancel(Self);
end;

procedure TDataSet.DoBeforeClose;
begin
  if Assigned(FBeforeClose) then FBeforeClose(Self);
end;

procedure TDataSet.DoBeforeDelete;
begin
  if Assigned(FBeforeDelete) then FBeforeDelete(Self);
end;

procedure TDataSet.DoBeforeEdit;
begin
  if Assigned(FBeforeEdit) then FBeforeEdit(Self);
end;

procedure TDataSet.DoBeforeInsert;
begin
  if Assigned(FBeforeInsert) then FBeforeInsert(Self);
end;

procedure TDataSet.DoBeforeOpen;
begin
  if Assigned(FBeforeOpen) then FBeforeOpen(Self);
end;

procedure TDataSet.DoBeforePost;
begin
  if Assigned(FBeforePost) then FBeforePost(Self);
end;

procedure TDataSet.DoBeforeRefresh;
begin
  if Assigned(FBeforeRefresh) then FBeforeRefresh(Self);
end;

procedure TDataSet.DoBeforeScroll;
begin
  if Assigned(FBeforeScroll) then FBeforeScroll(Self);
end;

procedure TDataSet.DoOnCalcFields;
begin
  if Assigned(FOnCalcFields) then FOnCalcFields(Self);
end;

procedure TDataSet.DoOnNewRecord;
begin
  if Assigned(FOnNewRecord) then FOnNewRecord(Self);
end;

{ IProviderSupport implementation }

procedure TDataSet.PSEndTransaction(Commit: Boolean);
begin
end;

procedure TDataSet.PSExecute;
begin
  DatabaseError(SProviderExecuteNotSupported, Self);
end;

function TDataSet.PSExecuteStatement(const ASQL: string; AParams: TParams;
  ResultSet: Pointer = nil): Integer;
begin
  Result := 0;
  DatabaseError(SProviderSQLNotSupported, Self);
end;

procedure TDataSet.PSGetAttributes(List: TList);
begin
end;

function TDataSet.PSGetDefaultOrder: TIndexDef;
begin
  Result := nil;
end;

function TDataSet.PSGetKeyFields: string;
var
  i: integer;
begin
  for i := 0 to Fields.Count - 1 do
    if pfInKey in Fields[i].ProviderFlags then
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + Fields[i].FieldName;
    end;
end;

function TDataSet.PSGetParams: TParams;
begin
  Result := nil;
end;

function TDataSet.PSGetQuoteChar: string;
begin
  Result := '';
end;

function TDataSet.PSGetTableName: string;
begin
  Result := '';
end;

function TDataSet.GetIndexDefs(IndexDefs: TIndexDefs;
  IndexTypes: TIndexOptions): TIndexDefs;
var
  i: Integer;
begin
  Result := nil;
  try
    IndexDefs.Update;
    if IndexDefs.Count = 0 then Exit;
    Result := TIndexDefs.Create(nil);
    Result.Assign(IndexDefs);
    for i := Result.Count - 1 downto 0 do
      if (IndexTypes <> []) and ((Result[i].Options * IndexTypes) = []) then
        Result[i].Free
      else
      try
        GetFieldList(nil, Result[i].Fields);
      except
        Result[i].Free;
      end;
  except
    if Assigned(Result) then
      Result.Clear;
  end;
  if Result.Count = 0 then
  begin
    Result.Free;
    Result := nil;
  end;
end;

function TDataSet.PSGetIndexDefs(IndexTypes: TIndexOptions): TIndexDefs;
begin
  Result := nil;
end;

function TDataSet.PSGetUpdateException(E: Exception; Prev: EUpdateError): EUpdateError;
var
  PrevErr: Integer;
begin
  if Prev <> nil then
    PrevErr := Prev.ErrorCode else
    PrevErr := 0;
  Result := EUpdateError.Create(E.Message, '', 1, PrevErr, E);
end;

function TDataSet.PSInTransaction: Boolean;
begin
  Result := False;
end;

function TDataSet.PSIsSQLBased: Boolean;
begin
  Result := False;
end;

function TDataSet.PSIsSQLSupported: Boolean;
begin
  Result := False;
end;

procedure TDataSet.PSReset;
begin
end;

procedure TDataSet.PSSetCommandText(const CommandText: string);
begin
end;

procedure TDataSet.PSSetParams(AParams: TParams);
begin
end;

procedure TDataSet.PSStartTransaction;
begin
end;

function TDataSet.PSUpdateRecord(UpdateKind: TUpdateKind; Delta: TDataSet): Boolean;
begin
  Result := False;
end;

type
  TDefaultDBScreenApplication = class(TInterfacedObject, IDBScreen, IDBApplication)
    FCursor: TDBSCreenCursor;
    FTitle: string;
    function GetCursor: TDBScreenCursor;
    procedure SetCursor(Cursor: TDBScreenCursor);
    function GetTitle: string;
    procedure ProcessMessages;
    procedure SetTitle(const Value: string);
  end;

{ TDefaultDBScreen }

function TDefaultDBScreenApplication.GetCursor: TDBScreenCursor;
begin
  Result := FCursor;
end;

function TDefaultDBScreenApplication.GetTitle: string;
begin
  Result := FTitle;
end;

procedure TDefaultDBScreenApplication.ProcessMessages;
begin
  { do nothing }
end;

procedure TDefaultDBScreenApplication.SetCursor(Cursor: TDBScreenCursor);
begin
  FCursor := Cursor;
end;

procedure TDefaultDBScreenApplication.SetTitle(const Value: string);
begin
  FTitle := Value;
end;

initialization
  DBScreen := TDefaultDBScreenApplication.Create as IDBScreen;
  DBApplication := DBScreen as IDBApplication;
end.
