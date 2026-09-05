
{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{                                                       }
{       Copyright (c) 1995,98 Inprise Corporation       }
{                                                       }
{*******************************************************}

unit DsgnIntf;

interface

{$N+,S-,R-}

uses Windows, SysUtils, Classes, Graphics, Controls, Forms, TypInfo;

type

  IEventInfos = interface
    ['{11667FF0-7590-11D1-9FBC-0020AF3D82DA}']
    function GetCount: Integer;
    function GetEventValue(Index: Integer): string;
    function GetEventName(Index: Integer): string;
    procedure ClearEvent(Index: Integer);
    property Count: Integer read GetCount;
  end;

  IPersistent = interface
    ['{82330133-65D1-11D1-9FBB-0020AF3D82DA}'] {Java}
    procedure DestroyObject;
    function Equals(const Other: IPersistent): Boolean;
    function GetClassname: string;
    function GetEventInfos: IEventInfos;
    function GetNamePath: string;
    function GetOwner: IPersistent;
    function InheritsFrom(const Classname: string): Boolean;
    function IsComponent: Boolean;  // object is stream createable
    function IsControl: Boolean;
    function IsWinControl: Boolean;
    property Classname: string read GetClassname;
    property Owner: IPersistent read GetOwner;
    property NamePath: string read GetNamePath;
//    property PersistentProps[Index: Integer]: IPersistent
//    property PersistentPropCount: Integer;
    property EventInfos: IEventInfos read GetEventInfos;
  end;

  IComponent = interface(IPersistent)
    ['{B2F6D681-5098-11D1-9FB5-0020AF3D82DA}'] {Java}
    function FindComponent(const Name: string): IComponent;
    function GetComponentCount: Integer;
    function GetComponents(Index: Integer): IComponent;
    function GetComponentState: TComponentState;
    function GetComponentStyle: TComponentStyle;
    function GetDesignInfo: TSmallPoint;
    function GetDesignOffset: TPoint;
    function GetDesignSize: TPoint;
    function GetName: string;
    function GetOwner: IComponent;
    function GetParent: IComponent;
    procedure SetDesignInfo(const Point: TSmallPoint);
    procedure SetDesignOffset(const Point: TPoint);
    procedure SetDesignSize(const Point: TPoint);
    procedure SetName(const Value: string);
    property ComponentCount: Integer read GetComponentCount;
    property Components[Index: Integer]: IComponent read GetComponents;
    property ComponentState: TComponentState read GetComponentState;
    property ComponentStyle: TComponentStyle read GetComponentStyle;
    property DesignInfo: TSmallPoint read GetDesignInfo write SetDesignInfo;
    property DesignOffset: TPoint read GetDesignOffset write SetDesignOffset;
    property DesignSize: TPoint read GetDesignSize write SetDesignSize;
    property Name: string read GetName write SetName;
    property Owner: IComponent read GetOwner;
    property Parent: IComponent read GetParent;
  end;

  IImplementation = interface
    ['{F9D448F2-50BC-11D1-9FB5-0020AF3D82DA}']
    function GetInstance: TObject;
  end;

  function MakeIPersistent(Instance: TPersistent): IPersistent;
  function ExtractPersistent(const Intf: IPersistent): TPersistent;
  function TryExtractPersistent(const Intf: IPersistent): TPersistent;

  function MakeIComponent(Instance: TComponent): IComponent;
  function ExtractComponent(const Intf: IComponent): TComponent;
  function TryExtractComponent(const Intf: IComponent): TComponent;

var
  MakeIPersistentProc: function (Instance: TPersistent): IPersistent = nil;
  MakeIComponentProc: function (Instance: TComponent): IComponent = nil;

type

{ IDesignerSelections  }
{   Used to transport the selected objects list in and out of the form designer.
    Replaces TComponentList in form designer interface.  }

  IDesignerSelections = interface
    ['{82330134-65D1-11D1-9FBB-0020AF3D82DA}'] {Java}
    function Add(const Item: IPersistent): Integer;
    function Equals(const List: IDesignerSelections): Boolean;
    function Get(Index: Integer): IPersistent;
    function GetCount: Integer;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: IPersistent read Get; default;
  end;

function CreateSelectionList: IDesignerSelections;

type

  TComponentList = class;

  IComponentList = interface
    ['{8ED8AD16-A241-11D1-AA94-00C04FB17A72}']
    function GetComponentList: TComponentList;
  end;

{ TComponentList }
{   Used to transport VCL component selections between property editors }

  TComponentList = class(TInterfacedObject, IDesignerSelections,
    IComponentList)
  private
    FList: TList;
    { IDesignSelections }
    function IDesignerSelections.Add = Intf_Add;
    function Intf_Add(const Item: IPersistent): Integer;
    function IDesignerSelections.Equals = Intf_Equals;
    function Intf_Equals(const List: IDesignerSelections): Boolean;
    function IDesignerSelections.Get = Intf_Get;
    function Intf_Get(Index: Integer): IPersistent;
    function Get(Index: Integer): TPersistent;
    function GetCount: Integer;
    { IComponentList }
    function GetComponentList: TComponentList;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(Item: TPersistent): Integer;
    function Equals(List: TComponentList): Boolean;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TPersistent read Get; default;
  end;

{ IFormDesigner }
type

  IFormDesigner = interface(IDesigner)
    ['{ABBE7255-5495-11D1-9FB5-0020AF3D82DA}']
    function CreateMethod(const Name: string; TypeData: PTypeData): TMethod;
    function GetMethodName(const Method: TMethod): string;
    procedure GetMethods(TypeData: PTypeData; Proc: TGetStrProc);
    function GetPrivateDirectory: string;
    procedure GetSelections(const List: IDesignerSelections);
    function MethodExists(const Name: string): Boolean;
    procedure RenameMethod(const CurName, NewName: string);
    procedure SelectComponent(Instance: TPersistent);
    procedure SetSelections(const List: IDesignerSelections);
    procedure ShowMethod(const Name: string);
    function UniqueName(const BaseName: string): string;
    procedure GetComponentNames(TypeData: PTypeData; Proc: TGetStrProc);
    function GetComponent(const Name: string): TComponent;
    function GetComponentName(Component: TComponent): string;
    function GetObject(const Name: string): TPersistent;
    function GetObjectName(Instance: TPersistent): string;
    procedure GetObjectNames(TypeData: PTypeData; Proc: TGetStrProc);
    function MethodFromAncestor(const Method: TMethod): Boolean;
    function CreateComponent(ComponentClass: TComponentClass; Parent: TComponent;
      Left, Top, Width, Height: Integer): TComponent;
    function IsComponentLinkable(Component: TComponent): Boolean;
    procedure MakeComponentLinkable(Component: TComponent);
    function GetRoot: TComponent;
    procedure Revert(Instance: TPersistent; PropInfo: PPropInfo);
    function GetIsDormant: Boolean;
    function HasInterface: Boolean;
    function HasInterfaceMember(const Name: string): Boolean;
    procedure AddToInterface(InvKind: Integer; const Name: string; VT: Word;
      const TypeInfo: string);
    procedure GetProjectModules(Proc: TGetModuleProc);
    function GetAncestorDesigner: IFormDesigner;
    function IsSourceReadOnly: Boolean;
    property IsDormant: Boolean read GetIsDormant;
    property AncestorDesigner: IFormDesigner read GetAncestorDesigner;
  end;

{ TPropertyEditor
  Edits a property of a component, or list of components, selected into the
  Object Inspector.  The property editor is created based on the type of the
  property being edited as determined by the types registered by
  RegisterPropertyEditor.  The Object Inspector uses the a TPropertyEditor
  for all modification to a property. GetName and GetValue are called to display
  the name and value of the property.  SetValue is called whenever the user
  requests to change the value.  Edit is called when the user double-clicks the
  property in the Object Inspector. GetValues is called when the drop-down
  list of a property is displayed.  GetProperties is called when the property
  is expanded to show sub-properties.  AllEqual is called to decide whether or
  not to display the value of the property when more than one component is
  selected.

  The following are methods that can be overriden to change the behavior of
  the property editor:

    Activate
      Called whenever the property becomes selected in the object inspector.
      This is potientially useful to allow certian property attributes to
      to only be determined whenever the property is selected in the object
      inspector. Only paSubProperties and paMultiSelect, returned from
      GetAttributes, need to be accurate before this method is called.
    AllEqual
      Called whenever there are more than one components selected.  If this
      method returns true, GetValue is called, otherwise blank is displayed
      in the Object Inspector.  This is called only when GetAttributes
      returns paMultiSelect.
    AutoFill
      Called to determine whether the values returned by GetValues can be
      selected incrementally in the Object Inspector.  This is called only when
      GetAttributes returns paValueList.
    Edit
      Called when the '...' button is pressed or the property is double-clicked.
      This can, for example, bring up a dialog to allow the editing the
      component in some more meaningful fashion than by text (e.g. the Font
      property).
    GetAttributes
      Returns the information for use in the Object Inspector to be able to
      show the approprate tools.  GetAttributes return a set of type
      TPropertyAttributes:
        paValueList:     The property editor can return an enumerated list of
                         values for the property.  If GetValues calls Proc
                         with values then this attribute should be set.  This
                         will cause the drop-down button to appear to the right
                         of the property in the Object Inspector.
        paSortList:      Object Inspector to sort the list returned by
                         GetValues.
        paSubProperties: The property editor has sub-properties that will be
                         displayed indented and below the current property in
                         standard outline format. If GetProperties will
                         generate property objects then this attribute should
                         be set.
        paDialog:        Indicates that the Edit method will bring up a
                         dialog.  This will cause the '...' button to be
                         displayed to the right of the property in the Object
                         Inspector.
        paMultiSelect:   Allows the property to be displayed when more than
                         one component is selected.  Some properties are not
                         approprate for multi-selection (e.g. the Name
                         property).
        paAutoUpdate:    Causes the SetValue method to be called on each
                         change made to the editor instead of after the change
                         has been approved (e.g. the Caption property).
        paReadOnly:      Value is not allowed to change.
        paRevertable:    Allows the property to be reverted to the original
                         value.  Things that shouldn't be reverted are nested
                         properties (e.g. Fonts) and elements of a composite
                         property such as set element values.
    GetComponent
      Returns the Index'th component being edited by this property editor.  This
      is used to retieve the components.  A property editor can only refer to
      multiple components when paMultiSelect is returned from GetAttributes.
    GetEditLimit
      Returns the number of character the user is allowed to enter for the
      value.  The inplace editor of the object inspector will be have its
      text limited set to the return value.  By default this limit is 255.
    GetName
      Returns a the name of the property.  By default the value is retrieved
      from the type information with all underbars replaced by spaces.  This
      should only be overriden if the name of the property is not the name
      that should appear in the Object Inspector.
    GetProperties
      Should be overriden to call PropertyProc for every sub-property (or nested
      property) of the property begin edited and passing a new TPropertyEdtior
      for each sub-property.  By default, PropertyProc is not called and no
      sub-properties are assumed.  TClassProperty will pass a new property
      editor for each published property in a class.  TSetProperty passes a
      new editor for each element in the set.
    GetPropType
      Returns the type information pointer for the propertie(s) being edited.
    GetValue
      Returns the string value of the property. By default this returns
      '(unknown)'.  This should be overriden to return the appropriate value.
    GetValues
      Called when paValueList is returned in GetAttributes.  Should call Proc
      for every value that is acceptable for this property.  TEnumProperty
      will pass every element in the enumeration.
    Initialize
      Called after the property editor has been created but before it is used.
      Many times property editors are created and because they are not a common
      property across the entire selection they are thrown away.  Initialize is
      called after it is determined the property editor is going to be used by
      the object inspector and not just thrown away.
    SetValue(Value)
      Called to set the value of the property.  The property editor should be
      able to translate the string and call one of the SetXxxValue methods. If
      the string is not in the correct format or not an allowed value, the
      property editor should generate an exception describing the problem. Set
      value can ignore all changes and allow all editing of the property be
      accomplished through the Edit method (e.g. the Picture property).

  Properties and methods useful in creating a new TPropertyEditor classes:

    Name property
      Returns the name of the property returned by GetName
    PrivateDirectory property
      It is either the .EXE or the "working directory" as specified in
      the registry under the key:
        "HKEY_CURRENT_USER\Software\Borland\Delphi\3.0\Globals\PrivateDir"
      If the property editor needs auxilury or state files (templates, examples,
      etc) they should be stored in this directory.
    Value property
      The current value, as a string, of the property as returned by GetValue.
    Modified
      Called to indicate the value of the property has been modified.  Called
      automatically by the SetXxxValue methods.  If you call a TProperty
      SetXxxValue method directly, you *must* call Modified as well.
    GetXxxValue
      Gets the value of the first property in the Properties property.  Calls
      the appropriate TProperty GetXxxValue method to retrieve the value.
    SetXxxValue
      Sets the value of all the properties in the Properties property.  Calls
      the approprate TProperty SetXxxxValue methods to set the value. }

  TPropertyAttribute = (paValueList, paSubProperties, paDialog,
    paMultiSelect, paAutoUpdate, paSortList, paReadOnly, paRevertable);
  TPropertyAttributes = set of TPropertyAttribute;

  TPropertyEditor = class;

  TInstProp = record
    Instance: TPersistent;
    PropInfo: PPropInfo;
  end;

  PInstPropList = ^TInstPropList;
  TInstPropList = array[0..1023] of TInstProp;

  TGetPropEditProc = procedure(Prop: TPropertyEditor) of object;

  TPropertyEditor = class
  private
    FDesigner: IFormDesigner;
    FPropList: PInstPropList;
    FPropCount: Integer;
    function GetPrivateDirectory: string;
    procedure SetPropEntry(Index: Integer; AInstance: TPersistent;
      APropInfo: PPropInfo);
  protected
    constructor Create(const ADesigner: IFormDesigner; APropCount: Integer);
    function GetPropInfo: PPropInfo;
    function GetFloatValue: Extended;
    function GetFloatValueAt(Index: Integer): Extended;
    function GetMethodValue: TMethod;
    function GetMethodValueAt(Index: Integer): TMethod;
    function GetOrdValue: Longint;
    function GetOrdValueAt(Index: Integer): Longint;
    function GetStrValue: string;
    function GetStrValueAt(Index: Integer): string;
    function GetVarValue: Variant;
    function GetVarValueAt(Index: Integer): Variant;
    procedure Modified;
    procedure SetFloatValue(Value: Extended);
    procedure SetMethodValue(const Value: TMethod);
    procedure SetOrdValue(Value: Longint);
    procedure SetStrValue(const Value: string);
    procedure SetVarValue(const Value: Variant);
  public
    destructor Destroy; override;
    procedure Activate; virtual;
    function AllEqual: Boolean; virtual;
    function AutoFill: Boolean; virtual;
    procedure Edit; virtual;
    function GetAttributes: TPropertyAttributes; virtual;
    function GetComponent(Index: Integer): TPersistent;
    function GetEditLimit: Integer; virtual;
    function GetName: string; virtual;
    procedure GetProperties(Proc: TGetPropEditProc); virtual;
    function GetPropType: PTypeInfo;
    function GetValue: string; virtual;
    procedure GetValues(Proc: TGetStrProc); virtual;
    procedure Initialize; virtual;
    procedure Revert;
    procedure SetValue(const Value: string); virtual;
    function ValueAvailable: Boolean;
    property Designer: IFormDesigner read FDesigner;
    property PrivateDirectory: string read GetPrivateDirectory;
    property PropCount: Integer read FPropCount;
    property Value: string read GetValue write SetValue;
  end;

  TPropertyEditorClass = class of TPropertyEditor;

{ TOrdinalProperty
  The base class of all ordinal property editors.  It established that ordinal
  properties are all equal if the GetOrdValue all return the same value. }

  TOrdinalProperty = class(TPropertyEditor)
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
  end;

{ TIntegerProperty
  Default editor for all Longint properties and all subtypes of the Longint
  type (i.e. Integer, Word, 1..10, etc.).  Retricts the value entrered into
  the property to the range of the sub-type. }

  TIntegerProperty = class(TOrdinalProperty)
  public
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TCharProperty
  Default editor for all Char properties and sub-types of Char (i.e. Char,
  'A'..'Z', etc.). }

  TCharProperty = class(TOrdinalProperty)
  public
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TEnumProperty
  The default property editor for all enumerated properties (e.g. TShape =
  (sCircle, sTriangle, sSquare), etc.). }

  TEnumProperty = class(TOrdinalProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  TBoolProperty = class(TEnumProperty)
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TFloatProperty
  The default property editor for all floating point types (e.g. Float,
  Single, Double, etc.) }

  TFloatProperty = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TStringProperty
  The default property editor for all strings and sub types (e.g. string,
  string[20], etc.). }

  TStringProperty = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TNestedProperty
  A property editor that uses the parents Designer, PropList and PropCount.
  The constructor and destructor do not call inherited, but all derived classes
  should.  This is useful for properties like the TSetElementProperty. }

  TNestedProperty = class(TPropertyEditor)
  public
    constructor Create(Parent: TPropertyEditor); virtual;
    destructor Destroy; override;
  end;

{ TSetElementProperty
  A property editor that edits an individual set element.  GetName is
  changed to display the set element name instead of the property name and
  Get/SetValue is changed to reflect the individual element state.  This
  editor is created by the TSetProperty editor. }

  TSetElementProperty = class(TNestedProperty)
  private
    FElement: Integer;
  protected
    constructor Create(Parent: TPropertyEditor; AElement: Integer); reintroduce;
  public
    function AllEqual: Boolean; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetName: string; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
   end;

{ TSetProperty
  Default property editor for all set properties. This editor does not edit
  the set directly but will display sub-properties for each element of the
  set. GetValue displays the value of the set in standard set syntax. }

  TSetProperty = class(TOrdinalProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetProperties(Proc: TGetPropEditProc); override;
    function GetValue: string; override;
  end;

{ TClassProperty
  Default property editor for all objects.  Does not allow modifing the
  property but does display the class name of the object and will allow the
  editing of the object's properties as sub-properties of the property. }

  TClassProperty = class(TPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetProperties(Proc: TGetPropEditProc); override;
    function GetValue: string; override;
  end;

{ TMethodProperty
  Property editor for all method properties. }

  TMethodProperty = class(TPropertyEditor)
  public
    function AllEqual: Boolean; override;
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const AValue: string); override;
    function GetFormMethodName: string; virtual;
    function GetTrimmedEventName: string;
  end;

{ TComponentProperty
  The default editor for TComponents.  It does not allow editing of the
  properties of the component.  It allow the user to set the value of this
  property to point to a component in the same form that is type compatible
  with the property being edited (e.g. the ActiveControl property). }

  TComponentProperty = class(TPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetEditLimit: Integer; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TComponentNameProperty
  Property editor for the Name property.  It restricts the name property
  from being displayed when more than one component is selected. }

  TComponentNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetEditLimit: Integer; override;
  end;

{ TFontNameProperty
  Editor for the TFont.FontName property.  Displays a drop-down list of all
  the fonts known by Windows.}

  TFontNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

{ TFontCharsetProperty
  Editor for the TFont.Charset property.  Displays a drop-down list of the
  character-set by Windows.}

  TFontCharsetProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TImeNameProperty
  Editor for the TImeName property.  Displays a drop-down list of all
  the IME names known by Windows.}

  TImeNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

{ TColorProperty
  Property editor for the TColor type.  Displays the color as a clXXX value
  if one exists, otherwise displays the value as hex.  Also allows the
  clXXX value to be picked from a list. }

  TColorProperty = class(TIntegerProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TCursorProperty
  Property editor for the TCursor type.  Displays the color as a crXXX value
  if one exists, otherwise displays the value as hex.  Also allows the
  clXXX value to be picked from a list. }

  TCursorProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TFontProperty
  Property editor the Font property.  Brings up the font dialog as well as
  allowing the properties of the object to be edited. }

  TFontProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

{ TModalResultProperty }

  TModalResultProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TShortCutProperty
  Property editor the the ShortCut property.  Allows both typing in a short
  cut value or picking a short-cut value from a list. }

  TShortCutProperty = class(TOrdinalProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

{ TMPFilenameProperty
  Property editor for the TMediaPlayer.  Displays an File Open Dialog
  for the name of the media file.}

  TMPFilenameProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

{ TTabOrderProperty
  Property editor for the TabOrder property.  Prevents the property from being
  displayed when more than one component is selected. }

  TTabOrderProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
  end;

{ TCaptionProperty
  Property editor for the Caption and Text properties.  Updates the value of
  the property for each change instead on when the property is approved. }

  TCaptionProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
  end;

{ TDateProperty
  Property editor for date portion of TDateTime type. }

  TDateProperty = class(TPropertyEditor)
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TTimeProperty
  Property editor for time portion of TDateTime type. }

  TTimeProperty = class(TPropertyEditor)
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

{ TDateTimeProperty
  Edits both date and time data... simultaneously!  }

  TDateTimeProperty = class(TPropertyEditor)
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

  EPropertyError = class(Exception);

{ TComponentEditor
  A component editor is created for each component that is selected in the
  form designer based on the component's type (see GetComponentEditor and
  RegisterComponentEditor).  When the component is double-clicked the Edit
  method is called.  When the context menu for the component is invoked the
  GetVerbCount and GetVerb methods are called to build the menu.  If one
  of the verbs are selected ExecuteVerb is called.  Paste is called whenever
  the component is pasted to the clipboard.  You only need to create a
  component editor if you wish to add verbs to the context menu, change
  the default double-click behavior, or paste an additional clipboard format.
  The default component editor (TDefaultEditor) implements Edit to searchs the
  properties of the component and generates (or navigates to) the OnCreate,
  OnChanged, or OnClick event (whichever it finds first).  Whenever the
  component modifies the component is *must* call Designer.Modified to inform
  the designer that the form has been modified.

    Create(AComponent, ADesigner)
      Called to create the component editor.  AComponent is the component to
      be edited by the editor.  ADesigner is an interface to the designer to
      find controls and create methods (this is not use often).
    Edit
      Called when the user double-clicks the component. The component editor can
      bring up a dialog in responce to this method, for example, or some kind
      of design expert.  If GetVerbCount is greater than zero, edit will execute
      the first verb in the list (ExecuteVerb(0)).
    ExecuteVerb(Index)
      The Index'ed verb was selected by the use off the context menu.  The
      meaning of this is determined by component editor.
    GetVerb
      The component editor should return a string that will be displayed in the
      context menu.  It is the responsibility of the component editor to place
      the & character and the '...' characters as appropriate.
    GetVerbCount
      The number of valid indexs to GetVerb and Execute verb.  The index assumed
      to be zero based (i.e. 0..GetVerbCount - 1).
    Copy
      Called when the component is being copyied to the clipboard.  The
      component's filed image is already on the clipboard.  This gives the
      component editor a chance to paste a different type of format which is
      ignored by the designer but might be recoginized by another application. }

  IComponentEditor = interface
    ['{ABBE7252-5495-11D1-9FB5-0020AF3D82DA}']
    procedure Edit;
    procedure ExecuteVerb(Index: Integer);
    function GetIComponent: IComponent;
    function GetDesigner: IFormDesigner;
    function GetVerb(Index: Integer): string;
    function GetVerbCount: Integer;
    procedure Copy;
  end;

  TComponentEditor = class(TInterfacedObject, IComponentEditor)
  private
    FComponent: TComponent;
    FDesigner: IFormDesigner;
  public
    constructor Create(AComponent: TComponent; ADesigner: IFormDesigner); virtual;
    procedure Edit; virtual;
    procedure ExecuteVerb(Index: Integer); virtual;
    function GetIComponent: IComponent;
    function GetDesigner: IFormDesigner;
    function GetVerb(Index: Integer): string; virtual;
    function GetVerbCount: Integer; virtual;
    procedure Copy; virtual;
    property Component: TComponent read FComponent;
    property Designer: IFormDesigner read GetDesigner;
  end;

  TComponentEditorClass = class of TComponentEditor;

  IDefaultEditor = interface(IComponentEditor)
    ['{5484FAE1-5C60-11D1-9FB6-0020AF3D82DA}']
  end;

  TDefaultEditor = class(TComponentEditor, IDefaultEditor)
  private
    FFirst: TPropertyEditor;
    FBest: TPropertyEditor;
    FContinue: Boolean;
    procedure CheckEdit(PropertyEditor: TPropertyEditor);
  protected
    procedure EditProperty(PropertyEditor: TPropertyEditor;
      var Continue, FreeEditor: Boolean); virtual;
  public
    procedure Edit; override;
  end;

{ Global variables initialized internally by the form designer }

type
  TFreeCustomModulesProc = procedure (Group: Integer);

var
  FreeCustomModulesProc: TFreeCustomModulesProc;

{ RegisterPropertyEditor
  Registers a new property editor for the given type.  When a component is
  selected the Object Inspector will create a property editor for each
  of the component's properties.  The property editor is created based on
  the type of the property.  If, for example, the property type is an
  Integer, the property editor for Integer will be created (by default
  that would be TIntegerProperty). Most properties do not need specialized
  property editors.  For example, if the property is an ordinal type the
  default property editor will restrict the range to the ordinal subtype
  range (e.g. a property of type TMyRange = 1..10 will only allow values
  between 1 and 10 to be entered into the property).  Enumerated types will
  display a drop-down list of all the enumerated values (e.g. TShapes =
  (sCircle, sSquare, sTriangle) will be edited by a drop-down list containing
  only sCircle, sSquare and sTriangle).  A property editor need only be
  created if default property editor or none of the existing property editors
  are sufficient to edit the property.  This is typically because the
  property is an object.  The properties are looked up newest to oldest.
  This allows and existing property editor replaced by a custom property
  editor.

    PropertyType
      The type information pointer returned by the TypeInfo built-in function
      (e.g. TypeInfo(TMyRange) or TypeInfo(TShapes)).

    ComponentClass
      Type type of the component to which to restrict this type editor.  This
      parameter can be left nil which will mean this type editor applies to all
      properties of PropertyType.

    PropertyName
      The name of the property to which to restrict this type editor.  This
      parameter is ignored if ComponentClass is nil.  This paramter can be
      an empty string ('') which will mean that this editor applies to all
      properties of PropertyType in ComponentClass.

    EditorClass
      The class of the editor to be created whenever a property of the type
      passed in PropertyTypeInfo is displayed in the Object Inspector.  The
      class will be created by calling EditorClass.Create. }

procedure RegisterPropertyEditor(PropertyType: PTypeInfo; ComponentClass: TClass;
  const PropertyName: string; EditorClass: TPropertyEditorClass);

type
  TPropertyMapperFunc = function(Obj: TPersistent;
    PropInfo: PPropInfo): TPropertyEditorClass;

procedure RegisterPropertyMapper(Mapper: TPropertyMapperFunc);

procedure GetComponentProperties(Components: TComponentList;
  Filter: TTypeKinds; Designer: IFormDesigner; Proc: TGetPropEditProc);

procedure RegisterComponentEditor(ComponentClass: TComponentClass;
  ComponentEditor: TComponentEditorClass);

function GetComponentEditor(Component: TComponent;
  Designer: IFormDesigner): TComponentEditor;

{ Custom modules }
{ A custom module allows containers that descend from classes other than TForm
  to be created and edited by the form designer. This is useful for other form
  like containers (e.g. a report designer) or for specialized forms (e.g. an
  ActiveForm) or for generic component containers (e.g. a TDataModule). It is
  assumed that the base class registered will call InitInheritedComponent in its
  constructor which will initialize the component from the associated DFM file
  stored in the programs resources. See the constructors of TDataModule and
  TForm for examples of how to write such a constructor.

  The following designer assumptions are made, depending on the base components
  ancestor,

    If ComponentBaseClass descends from TForm,

       it is designed by creating an instance of the component as the form.
       Allows designing TForm descendents and modifying their properties as
       well as the form properties

    If ComponentBaseClass descends from TWinControl (but not TForm),

       it is designed by creating an instance of the control, placing it into a
       design-time form.  The form's client size is in the default size of the
       control.

    If ComponentBaseClass descends from TDataModule,

       it is designed by creating and instance of the class and creating a
       special non-visual container designer to edit the components and display
       the icons of the contained components.

  The module will appear in the project file with a colon and the base class
  name appended after the component name (e.g. MyDataModle: TDataModule).

  Note it is not legal to register anything that does not desend from one of
  the above.

  TCustomModule class
    This an instance of this class is created for each custom module that is
    loaded. This class is also destroyed whenever the module is unloaded.
    The Saving method is called prior to the file being saved. When the context
    menu for the module is invoked the GetVerbCount and GetVerb methods are
    called to build the menu.  If one of the verbs are selected ExecuteVerb is
    called.

    ExecuteVerb(Index)
      The Index'ed verb was selected by the use off the context menu.  The
      meaning of this is determined by custom module.
    GetAttributes
      Only used for TWinControl object to determine if the control is "client
      aligned" in the designer or if the object should sized independently
      from the designer.  This is a set for future expansion.
    GetVerb(Index)
      The custom module should return a string that will be displayed in the
      context menu.  It is the responsibility of the custom module to place
      the & character and the '...' characters as appropriate.
    GetVerbCount
      The number of valid indexs to GetVerb and Execute verb.  The index assumed
      to be zero based (i.e. 0..GetVerbCount - 1).
    Saving
      Called prior to the module being saved.
    ValidateComponent(Component)
      ValidateCompoennt is called whenever a component is created by the
      user for the designer to contain.  The intent is for this procedure to
      raise an exception with a descriptive message if the component is not
      applicable for the container. For example, a TComponent module should
      throw an exception if the component descends from TControl.
    Root
      This is the instance being designed.}

type
  TCustomModuleAttribute = (cmaVirtualSize);
  TCustomModuleAttributes = set of TCustomModuleAttribute;

  TCustomModule = class
  private
    FRoot: IComponent;
  public
    constructor Create(ARoot: IComponent); virtual;
    procedure ExecuteVerb(Index: Integer); virtual;
    function GetAttributes: TCustomModuleAttributes; virtual;
    function GetVerb(Index: Integer): string; virtual;
    function GetVerbCount: Integer; virtual;
    procedure Saving; virtual;
    procedure ValidateComponent(Component: IComponent); virtual;
    property Root: IComponent read FRoot;
  end;

  TCustomModuleClass = class of TCustomModule;

  TRegisterCustomModuleProc = procedure (Group: Integer;
    ComponentBaseClass: TComponentClass;
    CustomModuleClass: TCustomModuleClass);

procedure RegisterCustomModule(ComponentBaseClass: TComponentClass;
  CustomModuleClass: TCustomModuleClass);

var
  RegisterCustomModuleProc: TRegisterCustomModuleProc;

{ Routines used by the form designer for package management }

function NewEditorGroup: Integer;
procedure FreeEditorGroup(Group: Integer);

var  // number of significant characters in identifiers
  MaxIdentLength: Byte = 63;

implementation

uses Menus, Dialogs, Consts, Registry;

type
  TIntegerSet = set of 0..SizeOf(Integer) * 8 - 1;

type
  PPropertyClassRec = ^TPropertyClassRec;
  TPropertyClassRec = record
    Group: Integer;
    PropertyType: PTypeInfo;
    PropertyName: string;
    ComponentClass: TClass;
    EditorClass: TPropertyEditorClass;
  end;

type
  PPropertyMapperRec = ^TPropertyMapperRec;
  TPropertyMapperRec = record
    Group: Integer;
    Mapper: TPropertyMapperFunc;
  end;

const
  PropClassMap: array[TTypeKind] of TPropertyEditorClass = (
    nil, TIntegerProperty, TCharProperty, TEnumProperty,
    TFloatProperty, TStringProperty, TSetProperty, TClassProperty,
    TMethodProperty, TPropertyEditor, TStringProperty, TStringProperty,
    TPropertyEditor, nil, nil, nil, nil, nil); (* tkArray, tkRecord, kInterface, tkInt64, tkDynArray *)

var
  PropertyClassList: TList = nil;
  EditorGroupList: TBits = nil;
  PropertyMapperList: TList = nil;

const

  { context ids for the Font editor and the Color Editor, etc. }
  hcDFontEditor       = 25000;
  hcDColorEditor      = 25010;
  hcDMediaPlayerOpen  = 25020;

{ TComponentList }

constructor TComponentList.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TComponentList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TComponentList.Get(Index: Integer): TPersistent;
begin
  Result := FList[Index];
end;

function TComponentList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TComponentList.Add(Item: TPersistent): Integer;
begin
  Result := FList.Add(Item);
end;

function TComponentList.Equals(List: TComponentList): Boolean;
var
  I: Integer;
begin
  Result := False;
  if List.Count <> FList.Count then Exit;
  for I := 0 to List.Count - 1 do if List[I] <> FList[I] then Exit;
  Result := True;
end;

function TComponentList.Intf_Add(const Item: IPersistent): Integer;
begin
  Result := Add(ExtractPersistent(Item));
end;

function TComponentList.Intf_Equals(const List: IDesignerSelections): Boolean;
var
  I: Integer;
  CompList: IComponentList;
  P1, P2: IPersistent;
begin
  if List.QueryInterface(IComponentList, CompList) = 0 then
    Result := CompList.GetComponentList.Equals(Self)
  else
  begin
    Result := False;
    if List.Count <> FList.Count then Exit;
    for I := 0 to List.Count - 1 do
    begin
      P1 := Intf_Get(I);
      P2 := List[I];
      if ((P1 = nil) and (P2 <> nil)) or
        (P2 = nil) or not P1.Equals(P2) then Exit;
    end;
    Result := True;
  end;
end;

function TComponentList.Intf_Get(Index: Integer): IPersistent;
begin
  Result := MakeIPersistent(TPersistent(FList[Index]));
end;

function TComponentList.GetComponentList: TComponentList;
begin
  Result := Self;
end;

{ TPropertyEditor }

constructor TPropertyEditor.Create(const ADesigner: IFormDesigner;
  APropCount: Integer);
begin
  FDesigner := ADesigner;
  GetMem(FPropList, APropCount * SizeOf(TInstProp));
  FPropCount := APropCount;
end;

destructor TPropertyEditor.Destroy;
begin
  if FPropList <> nil then
    FreeMem(FPropList, FPropCount * SizeOf(TInstProp));
end;

procedure TPropertyEditor.Activate;
begin
end;

function TPropertyEditor.AllEqual: Boolean;
begin
  Result := FPropCount = 1;
end;

procedure TPropertyEditor.Edit;
type
  TGetStrFunc = function(const Value: string): Integer of object;
var
  I: Integer;
  Values: TStringList;
  AddValue: TGetStrFunc;
begin
  Values := TStringList.Create;
  Values.Sorted := paSortList in GetAttributes;
  try
    AddValue := Values.Add;
    GetValues(TGetStrProc(AddValue));
    if Values.Count > 0 then
    begin
      I := Values.IndexOf(Value) + 1;
      if I = Values.Count then I := 0;
      Value := Values[I];
    end;
  finally
    Values.Free;
  end;
end;

function TPropertyEditor.AutoFill: Boolean;
begin
  Result := True;
end;

function TPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paRevertable];
end;

function TPropertyEditor.GetComponent(Index: Integer): TPersistent;
begin
  Result := FPropList^[Index].Instance;
end;

function TPropertyEditor.GetFloatValue: Extended;
begin
  Result := GetFloatValueAt(0);
end;

function TPropertyEditor.GetFloatValueAt(Index: Integer): Extended;
begin
  with FPropList^[Index] do Result := GetFloatProp(Instance, PropInfo);
end;

function TPropertyEditor.GetMethodValue: TMethod;
begin
  Result := GetMethodValueAt(0);
end;

function TPropertyEditor.GetMethodValueAt(Index: Integer): TMethod;
begin
  with FPropList^[Index] do Result := GetMethodProp(Instance, PropInfo);
end;

function TPropertyEditor.GetEditLimit: Integer;
begin
  Result := 255;
end;

function TPropertyEditor.GetName: string;
begin
  Result := FPropList^[0].PropInfo^.Name;
end;

function TPropertyEditor.GetOrdValue: Longint;
begin
  Result := GetOrdValueAt(0);
end;

function TPropertyEditor.GetOrdValueAt(Index: Integer): Longint;
begin
  with FPropList^[Index] do Result := GetOrdProp(Instance, PropInfo);
end;

function TPropertyEditor.GetPrivateDirectory: string;
begin
  Result := Designer.GetPrivateDirectory;
end;

procedure TPropertyEditor.GetProperties(Proc: TGetPropEditProc);
begin
end;

function TPropertyEditor.GetPropInfo: PPropInfo;
begin
  Result := FPropList^[0].PropInfo;
end;

function TPropertyEditor.GetPropType: PTypeInfo;
begin
  Result := FPropList^[0].PropInfo^.PropType^;
end;

function TPropertyEditor.GetStrValue: string;
begin
  Result := GetStrValueAt(0);
end;

function TPropertyEditor.GetStrValueAt(Index: Integer): string;
begin
  with FPropList^[Index] do Result := GetStrProp(Instance, PropInfo);
end;

function TPropertyEditor.GetVarValue: Variant;
begin
  Result := GetVarValueAt(0);
end;

function TPropertyEditor.GetVarValueAt(Index: Integer): Variant;
begin
  with FPropList^[Index] do Result := GetVariantProp(Instance, PropInfo);
end;

function TPropertyEditor.GetValue: string;
begin
  Result := srUnknown;
end;

procedure TPropertyEditor.GetValues(Proc: TGetStrProc);
begin
end;

procedure TPropertyEditor.Initialize;
begin
end;

procedure TPropertyEditor.Modified;
begin
  Designer.Modified;
end;

procedure TPropertyEditor.SetFloatValue(Value: Extended);
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do SetFloatProp(Instance, PropInfo, Value);
  Modified;
end;

procedure TPropertyEditor.SetMethodValue(const Value: TMethod);
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do SetMethodProp(Instance, PropInfo, Value);
  Modified;
end;

procedure TPropertyEditor.SetOrdValue(Value: Longint);
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do SetOrdProp(Instance, PropInfo, Value);
  Modified;
end;

procedure TPropertyEditor.SetPropEntry(Index: Integer;
  AInstance: TPersistent; APropInfo: PPropInfo);
begin
  with FPropList^[Index] do
  begin
    Instance := AInstance;
    PropInfo := APropInfo;
  end;
end;

procedure TPropertyEditor.SetStrValue(const Value: string);
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do SetStrProp(Instance, PropInfo, Value);
  Modified;
end;

procedure TPropertyEditor.SetVarValue(const Value: Variant);
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do SetVariantProp(Instance, PropInfo, Value);
  Modified;
end;

procedure TPropertyEditor.Revert;
var
  I: Integer;
begin
  for I := 0 to FPropCount - 1 do
    with FPropList^[I] do Designer.Revert(Instance, PropInfo);
end;

procedure TPropertyEditor.SetValue(const Value: string);
begin
end;

function TPropertyEditor.ValueAvailable: Boolean;
var
  I: Integer;
  S: string;
begin
  Result := True;
  for I := 0 to FPropCount - 1 do
  begin
    if (FPropList^[I].Instance is TComponent) and
      (csCheckPropAvail in TComponent(FPropList^[I].Instance).ComponentStyle) then
    begin
      try
        S := GetValue;
        AllEqual;
      except
        Result := False;
      end;
      Exit;
    end;
  end;
end;

{ TOrdinalProperty }

function TOrdinalProperty.AllEqual: Boolean;
var
  I: Integer;
  V: Longint;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetOrdValue;
    for I := 1 to PropCount - 1 do
      if GetOrdValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TOrdinalProperty.GetEditLimit: Integer;
begin
  Result := 63;
end;

{ TIntegerProperty }

function TIntegerProperty.GetValue: string;
begin
  with GetTypeData(GetPropType)^ do
    if (MinValue > MaxValue) then // unsigned
    Result := IntToStr(Cardinal(GetOrdValue))
  else
    Result := IntToStr(GetOrdValue);
end;

procedure TIntegerProperty.SetValue(const Value: String);

  procedure Error(const Args: array of const);
  begin
    raise EPropertyError.CreateFmt(SOutOfRange, Args);
  end;

var
  L: Int64;
begin
  L := StrToInt64(Value);
  with GetTypeData(GetPropType)^ do
    if (MinValue > MaxValue) then
    begin   // unsigned compare and reporting needed
      if (L < Cardinal(MinValue)) or (L > Cardinal(MaxValue)) then
        // bump up to Int64 to get past the %d in the format string
        Error([Int64(Cardinal(MinValue)), Int64(Cardinal(MaxValue))]);
    end
    else if (L < MinValue) or (L > MaxValue) then
      Error([MinValue, MaxValue]);
  SetOrdValue(L);
end;

{ TCharProperty }

function TCharProperty.GetValue: string;
var
  Ch: Char;
begin
  Ch := Chr(GetOrdValue);
  if Ch in [#33..#127] then
    Result := Ch else
    FmtStr(Result, '#%d', [Ord(Ch)]);
end;

procedure TCharProperty.SetValue(const Value: string);
var
  L: Longint;
begin
  if Length(Value) = 0 then L := 0 else
    if Length(Value) = 1 then L := Ord(Value[1]) else
      if Value[1] = '#' then L := StrToInt(Copy(Value, 2, Maxint)) else
        raise EPropertyError.Create(SInvalidPropertyValue);
  with GetTypeData(GetPropType)^ do
    if (L < MinValue) or (L > MaxValue) then
      raise EPropertyError.CreateFmt(SOutOfRange, [MinValue, MaxValue]);
  SetOrdValue(L);
end;

{ TEnumProperty }

function TEnumProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TEnumProperty.GetValue: string;
var
  L: Longint;
begin
  L := GetOrdValue;
  with GetTypeData(GetPropType)^ do
    if (L < MinValue) or (L > MaxValue) then L := MaxValue;
  Result := GetEnumName(GetPropType, L);
end;

procedure TEnumProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  EnumType: PTypeInfo;
begin
  EnumType := GetPropType;
  with GetTypeData(EnumType)^ do
    for I := MinValue to MaxValue do Proc(GetEnumName(EnumType, I));
end;

procedure TEnumProperty.SetValue(const Value: string);
var
  I: Integer;
begin
  I := GetEnumValue(GetPropType, Value);
  if I < 0 then raise EPropertyError.Create(SInvalidPropertyValue);
  SetOrdValue(I);
end;

{ TBoolProperty  }

function TBoolProperty.GetValue: string;
begin
  if GetOrdValue = 0 then
    Result := 'False'
  else
    Result := 'True';
end;

procedure TBoolProperty.GetValues(Proc: TGetStrProc);
begin
  Proc('False');
  Proc('True');
end;

procedure TBoolProperty.SetValue(const Value: string);
var
  I: Integer;
begin
  if CompareText(Value, 'False') = 0 then
    I := 0
  else if CompareText(Value, 'True') = 0 then
    I := -1
  else
    I := StrToInt(Value);
  SetOrdValue(I);
end;

{ TFloatProperty }

function TFloatProperty.AllEqual: Boolean;
var
  I: Integer;
  V: Extended;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetFloatValue;
    for I := 1 to PropCount - 1 do
      if GetFloatValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TFloatProperty.GetValue: string;
const
  Precisions: array[TFloatType] of Integer = (7, 15, 18, 18, 18);
begin
  Result := FloatToStrF(GetFloatValue, ffGeneral,
    Precisions[GetTypeData(GetPropType)^.FloatType], 0);
end;

procedure TFloatProperty.SetValue(const Value: string);
begin
  SetFloatValue(StrToFloat(Value));
end;

{ TStringProperty }

function TStringProperty.AllEqual: Boolean;
var
  I: Integer;
  V: string;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetStrValue;
    for I := 1 to PropCount - 1 do
      if GetStrValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TStringProperty.GetEditLimit: Integer;
begin
  if GetPropType^.Kind = tkString then
    Result := GetTypeData(GetPropType)^.MaxLength else
    Result := 255;
end;

function TStringProperty.GetValue: string;
begin
  Result := GetStrValue;
end;

procedure TStringProperty.SetValue(const Value: string);
begin
  SetStrValue(Value);
end;

{ TComponentNameProperty }

function TComponentNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [];
end;

function TComponentNameProperty.GetEditLimit: Integer;
begin
  Result := MaxIdentLength;
end;

{ TNestedProperty }

constructor TNestedProperty.Create(Parent: TPropertyEditor);
begin
  FDesigner := Parent.Designer;
  FPropList := Parent.FPropList;
  FPropCount := Parent.PropCount;
end;

destructor TNestedProperty.Destroy;
begin
end;

{ TSetElementProperty }

constructor TSetElementProperty.Create(Parent: TPropertyEditor; AElement: Integer);
begin
  inherited Create(Parent);
  FElement := AElement;
end;

function TSetElementProperty.AllEqual: Boolean;
var
  I: Integer;
  S: TIntegerSet;
  V: Boolean;
begin
  Result := False;
  if PropCount > 1 then
  begin
    Integer(S) := GetOrdValue;
    V := FElement in S;
    for I := 1 to PropCount - 1 do
    begin
      Integer(S) := GetOrdValueAt(I);
      if (FElement in S) <> V then Exit;
    end;
  end;
  Result := True;
end;

function TSetElementProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList];
end;

function TSetElementProperty.GetName: string;
begin
  Result := GetEnumName(GetTypeData(GetPropType)^.CompType^, FElement);
end;

function TSetElementProperty.GetValue: string;
var
  S: TIntegerSet;
begin
  Integer(S) := GetOrdValue;
  Result := BooleanIdents[FElement in S];
end;

procedure TSetElementProperty.GetValues(Proc: TGetStrProc);
begin
  Proc(BooleanIdents[False]);
  Proc(BooleanIdents[True]);
end;

procedure TSetElementProperty.SetValue(const Value: string);
var
  S: TIntegerSet;         
begin
  Integer(S) := GetOrdValue;
  if CompareText(Value, 'True') = 0 then
    Include(S, FElement) else
    Exclude(S, FElement);
  SetOrdValue(Integer(S));
end;

{ TSetProperty }

function TSetProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSubProperties, paReadOnly, paRevertable];
end;

procedure TSetProperty.GetProperties(Proc: TGetPropEditProc);
var
  I: Integer;
begin
  with GetTypeData(GetTypeData(GetPropType)^.CompType^)^ do
    for I := MinValue to MaxValue do
      Proc(TSetElementProperty.Create(Self, I));
end;

function TSetProperty.GetValue: string;
var
  S: TIntegerSet;
  TypeInfo: PTypeInfo;
  I: Integer;
begin
  Integer(S) := GetOrdValue;
  TypeInfo := GetTypeData(GetPropType)^.CompType^;
  Result := '[';
  for I := 0 to SizeOf(Integer) * 8 - 1 do
    if I in S then
    begin
      if Length(Result) <> 1 then Result := Result + ',';
      Result := Result + GetEnumName(TypeInfo, I);
    end;
  Result := Result + ']';
end;

{ TClassProperty }

function TClassProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSubProperties, paReadOnly];
end;

procedure TClassProperty.GetProperties(Proc: TGetPropEditProc);
var
  I: Integer;
  Components: TComponentList;
begin
  Components := TComponentList.Create;
  try
    for I := 0 to PropCount - 1 do
      Components.Add(TComponent(GetOrdValueAt(I)));
    GetComponentProperties(Components, tkProperties, Designer, Proc);
  finally
    Components.Free;
  end;
end;

function TClassProperty.GetValue: string;
begin
  FmtStr(Result, '(%s)', [GetPropType^.Name]);
end;

{ TComponentProperty }

function TComponentProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TComponentProperty.GetEditLimit: Integer;
begin
  Result := 127;
end;

function TComponentProperty.GetValue: string;
begin
  Result := Designer.GetComponentName(TComponent(GetOrdValue));
end;

procedure TComponentProperty.GetValues(Proc: TGetStrProc);
begin
  Designer.GetComponentNames(GetTypeData(GetPropType), Proc);
end;

procedure TComponentProperty.SetValue(const Value: string);
var
  Component: TComponent;
begin
  if Value = '' then Component := nil else
  begin
    Component := Designer.GetComponent(Value);
    if not (Component is GetTypeData(GetPropType)^.ClassType) then
      raise EPropertyError.Create(SInvalidPropertyValue);
  end;
  SetOrdValue(Longint(Component));
end;

{ TMethodProperty }

function TMethodProperty.AllEqual: Boolean;
var
  I: Integer;
  V, T: TMethod;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetMethodValue;
    for I := 1 to PropCount - 1 do
    begin
      T := GetMethodValueAt(I);
      if (T.Code <> V.Code) or (T.Data <> V.Data) then Exit;
    end;
  end;
  Result := True;
end;

procedure TMethodProperty.Edit;
var
  FormMethodName: string;
begin
  FormMethodName := GetValue;
  if (FormMethodName = '') or
    Designer.MethodFromAncestor(GetMethodValue) then
  begin
    if FormMethodName = '' then
      FormMethodName := GetFormMethodName;
    if FormMethodName = '' then
      raise EPropertyError.Create(SCannotCreateName);
    SetMethodValue(Designer.CreateMethod(FormMethodName,
      GetTypeData(GetPropType)));
  end;
  Designer.ShowMethod(FormMethodName);
end;

function TMethodProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TMethodProperty.GetEditLimit: Integer;
begin
  Result := MaxIdentLength;
end;

function TMethodProperty.GetFormMethodName: string;
var
  I: Integer;
begin
  if GetComponent(0) = Designer.Form then
    Result := 'Form'
  else
  begin
    Result := Designer.GetObjectName(GetComponent(0));
    for I := Length(Result) downto 1 do
      if Result[I] in ['.','[',']'] then
        Delete(Result, I, 1);
  end;
  if Result = '' then
    raise EPropertyError.Create(SCannotCreateName);
  Result := Result + GetTrimmedEventName;
end;

function TMethodProperty.GetTrimmedEventName: string;
begin
  Result := GetName;
  if (Length(Result) >= 2) and
    (Result[1] in ['O','o']) and (Result[2] in ['N','n']) then
    Delete(Result,1,2);
end;

function TMethodProperty.GetValue: string;
begin
  Result := Designer.GetMethodName(GetMethodValue);
end;

procedure TMethodProperty.GetValues(Proc: TGetStrProc);
begin
  Designer.GetMethods(GetTypeData(GetPropType), Proc);
end;

procedure TMethodProperty.SetValue(const AValue: string);
var
  NewMethod: Boolean;
  CurValue: string;
begin
  CurValue:= GetValue;
  if (CurValue <> '') and (AValue <> '') and
    ((CompareText(CurValue, AValue) = 0) or
    not Designer.MethodExists(AValue)) then
    Designer.RenameMethod(CurValue, AValue)
  else
  begin
    NewMethod := (AValue <> '') and not Designer.MethodExists(AValue);
    SetMethodValue(Designer.CreateMethod(AValue, GetTypeData(GetPropType)));
    if NewMethod then Designer.ShowMethod(AValue);
  end;
end;

{ TFontNameProperty }

function TFontNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

procedure TFontNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := 0 to Screen.Fonts.Count - 1 do Proc(Screen.Fonts[I]);
end;

{ TFontCharsetProperty }

function TFontCharsetProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSortList, paValueList];
end;

function TFontCharsetProperty.GetValue: string;
begin
  if not CharsetToIdent(TFontCharset(GetOrdValue), Result) then
    FmtStr(Result, '%d', [GetOrdValue]);
end;

procedure TFontCharsetProperty.GetValues(Proc: TGetStrProc);
begin
  GetCharsetValues(Proc);
end;

procedure TFontCharsetProperty.SetValue(const Value: string);
var
  NewValue: Longint;
begin
  if IdentToCharset(Value, NewValue) then
    SetOrdValue(NewValue)
  else inherited SetValue(Value);
end;

{ TImeNameProperty }

function TImeNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paMultiSelect];
end;

procedure TImeNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := 0 to Screen.Imes.Count - 1 do Proc(Screen.Imes[I]);
end;

{ TMPFilenameProperty }

procedure TMPFilenameProperty.Edit;
var
  MPFileOpen: TOpenDialog;
begin
  MPFileOpen := TOpenDialog.Create(Application);
  MPFileOpen.Filename := GetValue;
  MPFileOpen.Filter := SMPOpenFilter;
  MPFileOpen.HelpContext := hcDMediaPlayerOpen;
  MPFileOpen.Options := MPFileOpen.Options + [ofShowHelp, ofPathMustExist,
    ofFileMustExist];
  try
    if MPFileOpen.Execute then SetValue(MPFileOpen.Filename);
  finally
    MPFileOpen.Free;
  end;
end;

function TMPFilenameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

{ TColorProperty }

procedure TColorProperty.Edit;
var
  ColorDialog: TColorDialog;
  IniFile: TRegIniFile;

  procedure GetCustomColors;
  begin
    IniFile := TRegIniFile.Create('\Software\Borland\Delphi\3.0');
    try
      IniFile.ReadSectionValues(SCustomColors,
        ColorDialog.CustomColors);
    except
      { Ignore errors reading values }
    end;
  end;

  procedure SaveCustomColors;
  var
    I, P: Integer;
    S: string;
  begin
    if IniFile <> nil then
      with ColorDialog do
        for I := 0 to CustomColors.Count - 1 do
        begin
          S := CustomColors.Strings[I];
          P := Pos('=', S);
          if P <> 0 then
          begin
            S := Copy(S, 1, P - 1);
            IniFile.WriteString(SCustomColors, S,
              CustomColors.Values[S]);
          end;
        end;
  end;

begin
  IniFile := nil;
  ColorDialog := TColorDialog.Create(Application);
  try
    GetCustomColors;
    ColorDialog.Color := GetOrdValue;
    ColorDialog.HelpContext := hcDColorEditor;
    ColorDialog.Options := [cdShowHelp];
    if ColorDialog.Execute then SetOrdValue(ColorDialog.Color);
    SaveCustomColors;
  finally
    if IniFile <> nil then IniFile.Free;
    ColorDialog.Free;
  end;
end;

function TColorProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paDialog, paValueList, paRevertable];
end;

function TColorProperty.GetValue: string;
begin
  Result := ColorToString(TColor(GetOrdValue));
end;

procedure TColorProperty.GetValues(Proc: TGetStrProc);
begin
  GetColorValues(Proc);
end;

procedure TColorProperty.SetValue(const Value: string);
var
  NewValue: Longint;
begin
  if IdentToColor(Value, NewValue) then
    SetOrdValue(NewValue)
  else inherited SetValue(Value);
end;

{ TCursorProperty }

function TCursorProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
end;

function TCursorProperty.GetValue: string;
begin
  Result := CursorToString(TCursor(GetOrdValue));
end;

procedure TCursorProperty.GetValues(Proc: TGetStrProc);
begin
  GetCursorValues(Proc);
end;

procedure TCursorProperty.SetValue(const Value: string);
var
  NewValue: Longint;
begin
  if IdentToCursor(Value, NewValue) then
    SetOrdValue(NewValue)
  else inherited SetValue(Value);
end;

{ TFontProperty }

procedure TFontProperty.Edit;
var
  FontDialog: TFontDialog;
begin
  FontDialog := TFontDialog.Create(Application);
  try
    FontDialog.Font := TFont(GetOrdValue);
    FontDialog.HelpContext := hcDFontEditor;
    FontDialog.Options := FontDialog.Options + [fdShowHelp, fdForceFontExist];
    if FontDialog.Execute then SetOrdValue(Longint(FontDialog.Font));
  finally
    FontDialog.Free;
  end;
end;

function TFontProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paSubProperties, paDialog, paReadOnly];
end;

{ TModalResultProperty }

const
  ModalResults: array[mrNone..mrYesToAll] of string = (
    'mrNone',
    'mrOk',
    'mrCancel',
    'mrAbort',
    'mrRetry',
    'mrIgnore',
    'mrYes',
    'mrNo',
    'mrAll',
    'mrNoToAll',
    'mrYesToAll');

function TModalResultProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paRevertable];
end;

function TModalResultProperty.GetValue: string;
var
  CurValue: Longint;
begin
  CurValue := GetOrdValue;
  case CurValue of
    Low(ModalResults)..High(ModalResults):
      Result := ModalResults[CurValue];
  else
    Result := IntToStr(CurValue);
  end;
end;

procedure TModalResultProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  for I := Low(ModalResults) to High(ModalResults) do Proc(ModalResults[I]);
end;

procedure TModalResultProperty.SetValue(const Value: string);
var
  I: Integer;
begin
  if Value = '' then
  begin
    SetOrdValue(0);
    Exit;
  end;
  for I := Low(ModalResults) to High(ModalResults) do
    if CompareText(ModalResults[I], Value) = 0 then
    begin
      SetOrdValue(I);
      Exit;
    end;
  inherited SetValue(Value);
end;

{ TShortCutProperty }

const
  ShortCuts: array[0..108] of TShortCut = (
    scNone,
    Byte('A') or scCtrl,
    Byte('B') or scCtrl,
    Byte('C') or scCtrl,
    Byte('D') or scCtrl,
    Byte('E') or scCtrl,
    Byte('F') or scCtrl,
    Byte('G') or scCtrl,
    Byte('H') or scCtrl,
    Byte('I') or scCtrl,
    Byte('J') or scCtrl,
    Byte('K') or scCtrl,
    Byte('L') or scCtrl,
    Byte('M') or scCtrl,
    Byte('N') or scCtrl,
    Byte('O') or scCtrl,
    Byte('P') or scCtrl,
    Byte('Q') or scCtrl,
    Byte('R') or scCtrl,
    Byte('S') or scCtrl,
    Byte('T') or scCtrl,
    Byte('U') or scCtrl,
    Byte('V') or scCtrl,
    Byte('W') or scCtrl,
    Byte('X') or scCtrl,
    Byte('Y') or scCtrl,
    Byte('Z') or scCtrl,
    Byte('A') or scCtrl or scAlt,
    Byte('B') or scCtrl or scAlt,
    Byte('C') or scCtrl or scAlt,
    Byte('D') or scCtrl or scAlt,
    Byte('E') or scCtrl or scAlt,
    Byte('F') or scCtrl or scAlt,
    Byte('G') or scCtrl or scAlt,
    Byte('H') or scCtrl or scAlt,
    Byte('I') or scCtrl or scAlt,
    Byte('J') or scCtrl or scAlt,
    Byte('K') or scCtrl or scAlt,
    Byte('L') or scCtrl or scAlt,
    Byte('M') or scCtrl or scAlt,
    Byte('N') or scCtrl or scAlt,
    Byte('O') or scCtrl or scAlt,
    Byte('P') or scCtrl or scAlt,
    Byte('Q') or scCtrl or scAlt,
    Byte('R') or scCtrl or scAlt,
    Byte('S') or scCtrl or scAlt,
    Byte('T') or scCtrl or scAlt,
    Byte('U') or scCtrl or scAlt,
    Byte('V') or scCtrl or scAlt,
    Byte('W') or scCtrl or scAlt,
    Byte('X') or scCtrl or scAlt,
    Byte('Y') or scCtrl or scAlt,
    Byte('Z') or scCtrl or scAlt,
    VK_F1,
    VK_F2,
    VK_F3,
    VK_F4,
    VK_F5,
    VK_F6,
    VK_F7,
    VK_F8,
    VK_F9,
    VK_F10,
    VK_F11,
    VK_F12,
    VK_F1 or scCtrl,
    VK_F2 or scCtrl,
    VK_F3 or scCtrl,
    VK_F4 or scCtrl,
    VK_F5 or scCtrl,
    VK_F6 or scCtrl,
    VK_F7 or scCtrl,
    VK_F8 or scCtrl,
    VK_F9 or scCtrl,
    VK_F10 or scCtrl,
    VK_F11 or scCtrl,
    VK_F12 or scCtrl,
    VK_F1 or scShift,
    VK_F2 or scShift,
    VK_F3 or scShift,
    VK_F4 or scShift,
    VK_F5 or scShift,
    VK_F6 or scShift,
    VK_F7 or scShift,
    VK_F8 or scShift,
    VK_F9 or scShift,
    VK_F10 or scShift,
    VK_F11 or scShift,
    VK_F12 or scShift,
    VK_F1 or scShift or scCtrl,
    VK_F2 or scShift or scCtrl,
    VK_F3 or scShift or scCtrl,
    VK_F4 or scShift or scCtrl,
    VK_F5 or scShift or scCtrl,
    VK_F6 or scShift or scCtrl,
    VK_F7 or scShift or scCtrl,
    VK_F8 or scShift or scCtrl,
    VK_F9 or scShift or scCtrl,
    VK_F10 or scShift or scCtrl,
    VK_F11 or scShift or scCtrl,
    VK_F12 or scShift or scCtrl,
    VK_INSERT,
    VK_INSERT or scShift,
    VK_INSERT or scCtrl,
    VK_DELETE,
    VK_DELETE or scShift,
    VK_DELETE or scCtrl,
    VK_BACK or scAlt,
    VK_BACK or scShift or scAlt);

function TShortCutProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paValueList, paRevertable];
end;

function TShortCutProperty.GetValue: string;
var
  CurValue: TShortCut;
begin
  CurValue := GetOrdValue;
  if CurValue = scNone then
    Result := srNone else
    Result := ShortCutToText(CurValue);
end;

procedure TShortCutProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  Proc(srNone);
  for I := 1 to High(ShortCuts) do Proc(ShortCutToText(ShortCuts[I]));
end;

procedure TShortCutProperty.SetValue(const Value: string);
var
  NewValue: TShortCut;
begin
  NewValue := 0;
  if (Value <> '') and (AnsiCompareText(Value, srNone) <> 0) then
  begin
    NewValue := TextToShortCut(Value);
    if NewValue = 0 then
      raise EPropertyError.Create(SInvalidPropertyValue);
  end;
  SetOrdValue(NewValue);
end;

{ TTabOrderProperty }

function TTabOrderProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [];
end;

{ TCaptionProperty }

function TCaptionProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paAutoUpdate, paRevertable];
end;

{ TDateProperty }

function TDateProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paRevertable];
end;

function TDateProperty.GetValue: string;
var
  DT: TDateTime;
begin
  DT := GetFloatValue;
  if DT = 0.0 then Result := '' else
  Result := DateToStr(DT);
end;

procedure TDateProperty.SetValue(const Value: string);
var
  DT: TDateTime;
begin
  if Value = '' then DT := 0.0
  else DT := StrToDate(Value);
  SetFloatValue(DT);
end;

{ TTimeProperty }

function TTimeProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paRevertable];
end;

function TTimeProperty.GetValue: string;
var
  DT: TDateTime;
begin
  DT := GetFloatValue;
  if DT = 0.0 then Result := '' else
  Result := TimeToStr(DT);
end;

procedure TTimeProperty.SetValue(const Value: string);
var
  DT: TDateTime;
begin
  if Value = '' then DT := 0.0
  else DT := StrToTime(Value);
  SetFloatValue(DT);
end;

function TDateTimeProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paMultiSelect, paRevertable];
end;

function TDateTimeProperty.GetValue: string;
var
  DT: TDateTime;
begin
  DT := GetFloatValue;
  if DT = 0.0 then Result := '' else
  Result := DateTimeToStr(DT);
end;

procedure TDateTimeProperty.SetValue(const Value: string);
var
  DT: TDateTime;
begin
  if Value = '' then DT := 0.0
  else DT := StrToDateTime(Value);
  SetFloatValue(DT);
end;

{ TPropInfoList }

type
  TPropInfoList = class
  private
    FList: PPropList;
    FCount: Integer;
    FSize: Integer;
    function Get(Index: Integer): PPropInfo;
  public
    constructor Create(Instance: TPersistent; Filter: TTypeKinds);
    destructor Destroy; override;
    function Contains(P: PPropInfo): Boolean;
    procedure Delete(Index: Integer);
    procedure Intersect(List: TPropInfoList);
    property Count: Integer read FCount;
    property Items[Index: Integer]: PPropInfo read Get; default;
  end;

constructor TPropInfoList.Create(Instance: TPersistent; Filter: TTypeKinds);
begin
  FCount := GetPropList(Instance.ClassInfo, Filter, nil);
  FSize := FCount * SizeOf(Pointer);
  GetMem(FList, FSize);
  GetPropList(Instance.ClassInfo, Filter, FList);
end;

destructor TPropInfoList.Destroy;
begin
  if FList <> nil then FreeMem(FList, FSize);
end;

function TPropInfoList.Contains(P: PPropInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    with FList^[I]^ do
      if (PropType^ = P^.PropType^) and (CompareText(Name, P^.Name) = 0) then
      begin
        Result := True;
        Exit;
      end;
  Result := False;
end;

procedure TPropInfoList.Delete(Index: Integer);
begin
  Dec(FCount);
  if Index < FCount then
    Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Pointer));
end;

function TPropInfoList.Get(Index: Integer): PPropInfo;
begin
  Result := FList^[Index];
end;

procedure TPropInfoList.Intersect(List: TPropInfoList);
var
  I: Integer;
begin
  for I := FCount - 1 downto 0 do
    if not List.Contains(FList^[I]) then Delete(I);
end;

{ GetComponentProperties }

procedure RegisterPropertyEditor(PropertyType: PTypeInfo; ComponentClass: TClass;
  const PropertyName: string; EditorClass: TPropertyEditorClass);
var
  P: PPropertyClassRec;
begin
  if PropertyClassList = nil then
    PropertyClassList := TList.Create;
  New(P);
  P.Group := CurrentGroup;
  P.PropertyType := PropertyType;
  P.ComponentClass := ComponentClass;
  P.PropertyName := '';
  if Assigned(ComponentClass) then P^.PropertyName := PropertyName;
  P.EditorClass := EditorClass;
  PropertyClassList.Insert(0, P);
end;

procedure RegisterPropertyMapper(Mapper: TPropertyMapperFunc);
var
  P: PPropertyMapperRec;
begin
  if PropertyMapperList = nil then
    PropertyMapperList := TList.Create;
  New(P);
  P^.Group := CurrentGroup;
  P^.Mapper := Mapper;
  PropertyMapperList.Insert(0, P);
end;

function GetEditorClass(PropInfo: PPropInfo;
  Obj: TPersistent): TPropertyEditorClass;
var
  PropType: PTypeInfo;
  P, C: PPropertyClassRec;
  I: Integer;
begin
  if PropertyMapperList <> nil then
  begin
    for I := 0 to PropertyMapperList.Count -1 do
      with PPropertyMapperRec(PropertyMapperList[I])^ do
      begin
        Result := Mapper(Obj, PropInfo);
        if Result <> nil then Exit;
      end;
  end;
  PropType := PropInfo^.PropType^;
  I := 0;
  C := nil;
  while I < PropertyClassList.Count do
  begin
    P := PropertyClassList[I];

    if ((P^.PropertyType = PropType) or
         ((P^.PropertyType^.Kind = PropType.Kind) and
          (P^.PropertyType^.Name = PropType.Name)
         )
       ) or
       ( (PropType^.Kind = tkClass) and
         (P^.PropertyType^.Kind = tkClass) and
         GetTypeData(PropType)^.ClassType.InheritsFrom(GetTypeData(P^.PropertyType)^.ClassType)
       ) then
      if ((P^.ComponentClass = nil) or (Obj.InheritsFrom(P^.ComponentClass))) and
         ((P^.PropertyName = '') or (CompareText(PropInfo^.Name, P^.PropertyName) = 0)) then
        if (C = nil) or   // see if P is better match than C
           ((C^.ComponentClass = nil) and (P^.ComponentClass <> nil)) or
           ((C^.PropertyName = '') and (P^.PropertyName <> ''))
           or  // P's proptype match is exact, but C's isn't
           ((C^.PropertyType <> PropType) and (P^.PropertyType = PropType))
           or  // P's proptype is more specific than C's proptype
           ((P^.PropertyType <> C^.PropertyType) and
            (P^.PropertyType^.Kind = tkClass) and
            (C^.PropertyType^.Kind = tkClass) and
            GetTypeData(P^.PropertyType)^.ClassType.InheritsFrom(
              GetTypeData(C^.PropertyType)^.ClassType))
           or // P's component class is more specific than C's component class
           ((P^.ComponentClass <> nil) and (C^.ComponentClass <> nil) and
            (P^.ComponentClass <> C^.ComponentClass) and
            (P^.ComponentClass.InheritsFrom(C^.ComponentClass))) then
          C := P;
    Inc(I);
  end;
  if C <> nil then
    Result := C^.EditorClass else
    Result := PropClassMap[PropType^.Kind];
end;

procedure GetComponentProperties(Components: TComponentList;
  Filter: TTypeKinds; Designer: IFormDesigner; Proc: TGetPropEditProc);
var
  I, J, CompCount: Integer;
  CompType: TClass;
  Candidates: TPropInfoList;
  PropLists: TList;
  Editor: TPropertyEditor;
  EdClass: TPropertyEditorClass;
  PropInfo: PPropInfo;
  AddEditor: Boolean;
  Obj: TPersistent;
begin
  if (Components = nil) or (Components.Count = 0) then Exit;
  CompCount := Components.Count;
  Obj := Components[0];
  CompType := Components[0].ClassType;
  Candidates := TPropInfoList.Create(Components[0], Filter);
  try
    for I := Candidates.Count - 1 downto 0 do
    begin
      PropInfo := Candidates[I];
      EdClass := GetEditorClass(PropInfo, Obj);
      if EdClass = nil then
        Candidates.Delete(I)
      else
      begin
        Editor := EdClass.Create(Designer, 1);
        try
          Editor.SetPropEntry(0, Components[0], PropInfo);
          Editor.Initialize;
          with PropInfo^ do
            if (GetProc = nil) or ((PropType^.Kind <> tkClass) and
              (SetProc = nil)) or ((CompCount > 1) and
              not (paMultiSelect in Editor.GetAttributes)) or
              not Editor.ValueAvailable then
              Candidates.Delete(I);
        finally
          Editor.Free;
        end;
      end;
    end;
    PropLists := TList.Create;
    try
      PropLists.Capacity := CompCount;
      for I := 0 to CompCount - 1 do
        PropLists.Add(TPropInfoList.Create(Components[I], Filter));
      for I := 0 to CompCount - 1 do
        Candidates.Intersect(TPropInfoList(PropLists[I]));
      for I := 0 to CompCount - 1 do
        TPropInfoList(PropLists[I]).Intersect(Candidates);
      for I := 0 to Candidates.Count - 1 do
      begin
        EdClass := GetEditorClass(Candidates[I], Obj);
        if EdClass = nil then Continue;
        Editor := EdClass.Create(Designer, CompCount);
        try
          AddEditor := True;
          for J := 0 to CompCount - 1 do
          begin
            if (Components[J].ClassType <> CompType) and
              (GetEditorClass(TPropInfoList(PropLists[J])[I],
                Components[J]) <> Editor.ClassType) then
            begin
              AddEditor := False;
              Break;
            end;
            Editor.SetPropEntry(J, Components[J],
              TPropInfoList(PropLists[J])[I]);
          end;
        except
          Editor.Free;
          raise;
        end;
        if AddEditor then
        begin
          Editor.Initialize;
          if Editor.ValueAvailable then
            Proc(Editor) else
            Editor.Free;
        end
        else Editor.Free;
      end;
    finally
      for I := 0 to PropLists.Count - 1 do TPropInfoList(PropLists[I]).Free;
      PropLists.Free;
    end;
  finally
    Candidates.Free;
  end;
end;

{ RegisterComponentEditor }

type
  PComponentClassRec = ^TComponentClassRec;
  TComponentClassRec = record
    Group: Integer;
    ComponentClass: TComponentClass;
    EditorClass: TComponentEditorClass;
  end;

var
  ComponentClassList: TList = nil;

procedure RegisterComponentEditor(ComponentClass: TComponentClass;
  ComponentEditor: TComponentEditorClass);
var
  P: PComponentClassRec;
begin
  if ComponentClassList = nil then
    ComponentClassList := TList.Create;
  New(P);
  P.Group := CurrentGroup;
  P.ComponentClass := ComponentClass;
  P.EditorClass := ComponentEditor;
  ComponentClassList.Insert(0, P);
end;

{ GetComponentEditor }

function GetComponentEditor(Component: TComponent;
  Designer: IFormDesigner): TComponentEditor;
var
  P: PComponentClassRec;
  I: Integer;
  ComponentClass: TComponentClass;
  EditorClass: TComponentEditorClass;
begin
  ComponentClass := TComponentClass(TPersistent);
  EditorClass := TDefaultEditor;
  for I := 0 to ComponentClassList.Count-1 do
  begin
    P := ComponentClassList[I];
    if (Component is P^.ComponentClass) and
      (P^.ComponentClass <> ComponentClass) and
      (P^.ComponentClass.InheritsFrom(ComponentClass)) then
    begin
      EditorClass := P^.EditorClass;
      ComponentClass := P^.ComponentClass;
    end;
  end;
  Result := EditorClass.Create(Component, Designer);
end;

function NewEditorGroup: Integer;
begin
  if EditorGroupList = nil then
    EditorGroupList := TBits.Create;
  CurrentGroup := EditorGroupList.OpenBit;
  EditorGroupList[CurrentGroup] := True;
  Result := CurrentGroup;
end;

procedure FreeEditorGroup(Group: Integer);
var
  I: Integer;
  P: PPropertyClassRec;
  C: PComponentClassRec;
  M: PPropertyMapperRec;
begin
  I := PropertyClassList.Count - 1;
  while I > -1 do
  begin
    P := PropertyClassList[I];
    if P.Group = Group then
    begin
      PropertyClassList.Delete(I);
      Dispose(P);
    end;
    Dec(I);
  end;
  I := ComponentClassList.Count - 1;
  while I > -1 do
  begin
    C := ComponentClassList[I];
    if C.Group = Group then
    begin
      ComponentClassList.Delete(I);
      Dispose(C);
    end;
    Dec(I);
  end;
  if PropertyMapperList <> nil then
    for I := PropertyMapperList.Count-1 downto 0 do
    begin
      M := PropertyMapperList[I];
      if M.Group = Group then
      begin
        PropertyMapperList.Delete(I);
        Dispose(M);
      end;
    end;
  if Assigned(FreeCustomModulesProc) then FreeCustomModulesProc(Group);
  if (Group >= 0) and (Group < EditorGroupList.Size) then
    EditorGroupList[Group] := False;
end;

{ TComponentEditor }

constructor TComponentEditor.Create(AComponent: TComponent; ADesigner: IFormDesigner);
begin
  inherited Create;
  FComponent := AComponent;
  FDesigner := ADesigner;
end;

procedure TComponentEditor.Edit;
begin
  if GetVerbCount > 0 then ExecuteVerb(0);
end;

function TComponentEditor.GetIComponent: IComponent;
begin
  Result := MakeIComponent(FComponent);
end;

function TComponentEditor.GetDesigner: IFormDesigner;
begin
  Result := FDesigner;
end;

function TComponentEditor.GetVerbCount: Integer;
begin
  Result := 0;
end;

function TComponentEditor.GetVerb(Index: Integer): string;
begin
end;

procedure TComponentEditor.ExecuteVerb(Index: Integer);
begin
end;

procedure TComponentEditor.Copy;
begin
end;

{ TDefaultEditor }

procedure TDefaultEditor.CheckEdit(PropertyEditor: TPropertyEditor);
var
  FreeEditor: Boolean;
begin
  FreeEditor := True;
  try
    if FContinue then EditProperty(PropertyEditor, FContinue, FreeEditor);
  finally
    if FreeEditor then PropertyEditor.Free;
  end;
end;

procedure TDefaultEditor.EditProperty(PropertyEditor: TPropertyEditor;
  var Continue, FreeEditor: Boolean);
var
  PropName: string;
  BestName: string;

  procedure ReplaceBest;
  begin
    FBest.Free;
    FBest := PropertyEditor;
    if FFirst = FBest then FFirst := nil;
    FreeEditor := False;
  end;

begin
  if not Assigned(FFirst) and (PropertyEditor is TMethodProperty) then
  begin
    FreeEditor := False;
    FFirst := PropertyEditor;
  end;
  PropName := PropertyEditor.GetName;
  BestName := '';
  if Assigned(FBest) then BestName := FBest.GetName;
  if CompareText(PropName, 'ONCREATE') = 0 then
    ReplaceBest
  else if CompareText(BestName, 'ONCREATE') <> 0 then
    if CompareText(PropName, 'ONCHANGE') = 0 then
      ReplaceBest
    else if CompareText(BestName, 'ONCHANGE') <> 0 then
      if CompareText(PropName, 'ONCLICK') = 0 then
        ReplaceBest;
end;

procedure TDefaultEditor.Edit;
var
  Components: TComponentList;
begin
  Components := TComponentList.Create;
  try
    FContinue := True;
    Components.Add(Component);
    FFirst := nil;
    FBest := nil;
    try
      GetComponentProperties(Components, tkAny, Designer, CheckEdit);
      if FContinue then
        if Assigned(FBest) then
          FBest.Edit
        else if Assigned(FFirst) then
          FFirst.Edit;
    finally
      FFirst.Free;
      FBest.Free;
    end;
  finally
    Components.Free;
  end;
end;

{ TCustomModule }

constructor TCustomModule.Create(ARoot: IComponent);
begin
  inherited Create;
  FRoot := ARoot;
end;

procedure TCustomModule.ExecuteVerb(Index: Integer);
begin
end;

function TCustomModule.GetAttributes: TCustomModuleAttributes;
begin
  Result := [];
end;

function TCustomModule.GetVerb(Index: Integer): string;
begin
  Result := '';
end;

function TCustomModule.GetVerbCount: Integer;
begin
  Result := 0;
end;

procedure TCustomModule.Saving;
begin
end;

procedure TCustomModule.ValidateComponent(Component: IComponent);
begin
end;

procedure RegisterCustomModule(ComponentBaseClass: TComponentClass;
  CustomModuleClass: TCustomModuleClass);
begin
  if Assigned(RegisterCustomModuleProc) then
    RegisterCustomModuleProc(CurrentGroup, ComponentBaseClass, CustomModuleClass);
end;

function MakeIPersistent(Instance: TPersistent): IPersistent;
begin
  if Assigned(MakeIPersistentProc) then
    Result := MakeIPersistentProc(Instance);
end;

function ExtractPersistent(const Intf: IPersistent): TPersistent;
begin
  if Intf = nil then
    Result := nil
  else
    Result := (Intf as IImplementation).GetInstance as TPersistent;
end;

function TryExtractPersistent(const Intf: IPersistent): TPersistent;
var
  Temp: IImplementation;
begin
  Result := nil;
  if (Intf <> nil) and (Intf.QueryInterface(IImplementation, Temp) = 0) and
    (Temp.GetInstance <> nil) and (Temp.GetInstance is TPersistent) then
    Result := TPersistent(Temp.GetInstance);
end;

function MakeIComponent(Instance: TComponent): IComponent;
begin
  if Assigned(MakeIComponentProc) then
    Result := MakeIComponentProc(Instance);
end;

function ExtractComponent(const Intf: IComponent): TComponent;
begin
  if Intf = nil then
    Result := nil
  else
    Result := (Intf as IImplementation).GetInstance as TComponent;
end;

function TryExtractComponent(const Intf: IComponent): TComponent;
var
  Temp: TPersistent;
begin
  Temp := TryExtractPersistent(Intf);
  if (Temp <> nil) and (Temp is TComponent) then
    Result := TComponent(Temp)
  else
    Result := nil;
end;

type

  { TSelectionList  -  implements IDesignerSelections }

  TSelectionList = class(TInterfacedObject, IDesignerSelections)
  private
    FList: IInterfaceList;
  public
    constructor Create;
    function Add(const Item: IPersistent): Integer;
    function Equals(const List: IDesignerSelections): Boolean;
    function Get(Index: Integer): IPersistent;
    function GetCount: Integer;
  end;

constructor TSelectionList.Create;
begin
  inherited Create;
  FList := TInterfaceList.Create;
end;

function TSelectionList.Add(const Item: IPersistent): Integer;
begin
  Result := FList.Add(Item);
end;

function TSelectionList.Equals(const List: IDesignerSelections): Boolean;
var
  I: Integer;
begin
  Result := False;
  if List.Count <> FList.Count then Exit;
  for I := 0 to List.Count - 1 do if not List[I].Equals(IPersistent(FList[I])) then Exit;
  Result := True;
end;

function TSelectionList.Get(Index: Integer): IPersistent;
begin
  Result := IPersistent(FList[Index]);
end;

function TSelectionList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function CreateSelectionList: IDesignerSelections;
begin
  Result := TSelectionList.Create;
end;

initialization

finalization
  EditorGroupList.Free;
  PropertyClassList.Free;
  ComponentClassList.Free;
  PropertyMapperList.Free;

end.
