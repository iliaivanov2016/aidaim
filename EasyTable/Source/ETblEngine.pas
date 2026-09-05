unit ETblEngine;

{$I ETblVer.inc}

interface

uses ETblFileManage,SysUtils, classes, windows, db
{$IFDEF DEBUG_FLAG}
 ,aaDebug
{$ENDIF}
;

// thread-safe
function  ETblAllocCriticalSection: Pointer;
procedure ETblInitializeCriticalSection(Section: Pointer);
procedure ETblEnterCriticalSection(Section: Pointer);
procedure ETblLeaveCriticalSection(Section: Pointer);
procedure ETblDeleteCriticalSection(Section: Pointer);
procedure ETblFreeCriticalSection(var Section: Pointer);


type
  TBitsArray = class
  public
   bits : array of byte;
   bitCount : integer;

    constructor Create(length:integer);
    destructor Destroy; override;
    procedure SetSize(length:integer);
    function FindFirst(bitValue:boolean):integer;
    function FindNext:integer;
    procedure SetBit(bitNo:integer; bitValue:boolean);
    function GetBit(bitNo:integer):boolean;
    procedure SetBits(bitValue:boolean);
    procedure NotBits;
    procedure AndBits(bits1:TBitsArray);
    procedure OrBits(bits1:TBitsArray);
    procedure AndBit(bitNo:integer; bitValue:boolean);
    procedure OrBit(bitNo:integer; bitValue:boolean);
  private
   FBitNo : integer;
   FBitValue : byte;
  end;

type
 // supported filter operators
 TSearchOperator=(soEQ,soNEQ,soLTE,soGTE,soLT,soGT,soLike,soNotLike,
                  soIsNull,soIsNotNull);
const SearchOperators : array [soEQ..soIsNotNull] of shortstring =
      ('=','<>','<=','>=','<','>','like','not like','is null','is not null');

DefaultRecordPages = 50; // maximum number of pages in large pages mode
DefaultRecordsPerPage = 1000; // default size of page in large pages mode

type
 // Boolean operators
 TBoolOperator=(boNone,boNot,boAnd,boOr,boOpenParenthesis,boCloseParenthesis);
 // Basic search operation / operator
 TSearchOperation=record
   BoolOp : TBoolOperator; // operator
   // operation
   FieldNo : integer;
   FieldName : AnsiString;
   SearchOp : TSearchOperator;
   bPartialCompare : boolean;
   ValueBuffer : PAnsiChar; // in internal record format
 end;
 TSearchOperations = array of TSearchOperation;

 // parse filter AnsiString to generate array of records
 TSearchParser=class
  public
    ds:TDataset;
    ParsedStr : AnsiString;
    bitsArr : array of TBitsArray;
    bitsArrCount : integer;
    bitsArrNo : integer;
    AllocBy : integer;
    recordBuffer: PAnsiChar;

    // check if s1[n-...] = s2, ignoring spaces
    function IsStartStr(s1:AnsiString; var n:integer; s2:AnsiString) : boolean;
    //--- preparsing functions ---
    procedure PreParseBooleanExpression(var n:integer);
    procedure PreParseBooleanSum(var n:integer);
    procedure PreParseBooleanMultiplication(var n:integer);
    procedure PreParseBooleanMultiplier(var n:integer);
    procedure PreParseFieldExpression(var n:integer);
    procedure PreParseFieldName(var n:integer);
    procedure PreParseFieldOperation(var n:integer);
    procedure PreParseFieldOperator(var n:integer);
    procedure PreParseFieldValue(var n:integer);
    procedure PreParseNumber(var n:integer);
    procedure PreParseText(var n:integer);
    procedure PreParseBoolean(var n:integer);

    //--- parsing functions ---
    procedure ParseBooleanExpression(var n:integer);
    procedure ParseBooleanSum(var n:integer);
    procedure ParseBooleanMultiplication(var n:integer);
    procedure ParseBooleanMultiplier(var n:integer);
    procedure ParseFieldExpression(var n:integer);

    //--- checking functions (for one record) ---
    function CheckBooleanExpression(var n:integer): boolean;
    function CheckBooleanSum(var n:integer): boolean;
    function CheckBooleanMultiplication(var n:integer): boolean;
    function CheckBooleanMultiplier(var n:integer): boolean;
    function CheckFieldExpression(var n:integer): boolean;

    // increase No and reallocates memory if neccessary
    procedure IncBitsArrNo();
 public
    opArr : TSearchOperations;
    opCount : integer;
    opNo : integer;
    FilterOptions : TFilterOptions;

    constructor Create(ds1 : TDataset);
    destructor Destroy; override;
    procedure PreParse(Filter:AnsiString);
    procedure Parse;
    function IsRecordMatches(recordBuf: PAnsiChar): boolean;
 end;

type
  // BLOB index header type
   TaaBLOBHeader = packed record
   numParts  	: Integer; 		 	// number of parts for this BLOB
   														// each part consist of some blocks
   position		: Integer;			// position of first part in BLOB index File form beginning
   size				: Integer;			// compressed size in bytes of the value
   trueSize		: Integer;			// true size in bytes of the value (uncompressed);
   crc32			: string[15];	  // crc-32 for blob data
  end;
  // BLOB Index
  TaaBLOBPart = packed record
   blockNumber	: Integer; 		 	// number of the block (0,..)
   blockCount		: Integer;			// block's quantity
  end;
  TaaBlobParts = array of TaaBLOBPart;
  // table operation
  TaaRecordOperation = (roMove, roBLOBWrite);

   TaaIntArray=class
    public
     Items: array of integer;
     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     constructor Create(
      size: integer = 0;
      DefaultAllocBy: integer = 1000;
      MaximumAllocBy: integer = 10000
     );
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure Assign(v: TaaIntArray);
     procedure Append(value: integer);
     procedure Insert(ItemNo: integer; value: integer);
     procedure Delete(ItemNo: integer);
     procedure MoveTo(itemNo, newItemNo : integer);
     procedure CopyTo(var ar : array of Integer;
                    itemNo,iCount : integer);
     function IsValueExists(value: integer): Boolean;
   end;

   TaaSortedIntArray=class
    private
     KeyItems: array of integer;
     ValueItems: array of integer;
     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     function FindPositionForInsert(key: Integer) : Integer;
     function FindPosition(key: Integer): Integer;
     procedure InsertByPosition(ItemNo: integer; key, value: integer);
     procedure DeleteByPosition(ItemNo: integer);

    public
     constructor Create(size: integer=0);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     function Find(key: Integer) : Integer;
     procedure Insert(key, value: integer);
     procedure Delete(key: integer);
   end;

 type
   TaaBLOBPartsArray=class
    public
     Items    : array of TaaBLOBPart;
     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     constructor Create(size: integer=0);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure Insert(ItemNo: integer; value: TaaBLOBPart);
     procedure Append(value: TaaBLOBPart);
     procedure Delete(ItemNo: integer);
     procedure AppendFrom (src: array of TaaBLOBPart; qty: integer);
   end;

   TaaBLOBHeadersArray=class
    public
     Headers  : array of TaaBLOBHeader;
     Parts : array of array of TaaBLOBPart;
     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;
     LastBlockNumber : Integer;

     constructor Create(size: integer=0);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure Delete(itemNo: integer; qty : integer = 1);
     procedure ClearParts(itemNo : integer);
   end;

   TRecordsPage=class
    private
     FMaxRecordCount: integer; // max record count
     pData: PAnsiChar; // pointer to array of records
     DMHandle: Pointer; // DataManager

     // set new page size
     procedure SetMaxRecordCount(value: integer);
     // set access variables
     procedure SetAccessVariables;

    public
     RecordSize: integer; // size of record (in bytes)
     FirstRecordNo: integer; // No of first record in this page
     RecordCount: integer; // current record count
     PageNo: integer; // No of page
     UseCount: integer; // count of uses
     LastUseTime: integer; // time of last access
     LockCount: integer; // counter of page locks

     // constructor
     constructor Create(NewMaxRecordCount: integer; NewDMHandle: Pointer);
     // destructor
     destructor Destroy; override;
     // is record in this page
     function RecordExists(RecordNo: integer): boolean;
     // get record ptr
     function GetRecordPtr(RecordNo: integer): PAnsiChar;
     // append new record
     function AppendRecord(pRecordBuffer: PAnsiChar): PAnsiChar;
     // copy some records into dest buffer
     procedure CopyRecords(StartRecNo: integer; pDestBuffer: PAnsiChar; Count: integer=1);
     // remove last record
     procedure DeleteLastRecord;
     // read page
     procedure Read(NewPageNo: integer);
     // read records
     procedure ReadRecords(StartRecNo: integer; RecCount: integer);
     // delete all records starting from RecNo
     procedure DeleteRecords(StartRecNo: integer);
     // init page
     procedure Init(NewPageNo: integer);

    published
     property MaxRecordCount: integer read FMaxRecordCount write SetMaxRecordCount default 0;
   end;

   TaaRecordsArray=class
    private
     DMHandle : Pointer;
     RecordPage: array of TRecordsPage;  // all pages
     RecordPageNoArr: TaaSortedIntArray; // Numbers of loaded pages
     PageCount: integer; // count of all pages
     PageRecordCount: integer; // size of page (in records)
     EndPageIndex: integer; // Index of end page
     bLargePagesMode: boolean; // Large or small pages
     bAllPagesAllocated: boolean; // all pages is already allocated

     // Check is it needed - Reset Pages
     procedure CheckResetPages;
     // Reset Pages - for new page size
     procedure ResetPages;
     // find page by PageNo
     function GetPageIndex(PageNo: integer): integer;
     // find page to use
     function GetPageToUse(NewPageNo: integer): integer;
     // load end page if necessary
     procedure CheckEndPageLoaded;
     // get page No by record No
     function GetPageNoByRecNo(RecordNo: integer): integer;

    public
     FastOpen: boolean; // open by small pages

     constructor Create(pDataManager : Pointer; FastOpenValue: Boolean);
     destructor Destroy; override;
     function Append(pRecordData: PAnsiChar=nil): PAnsiChar;
     procedure Delete(recordNo: integer);
     function GetRecordDataPtr(RecordNo: integer): PAnsiChar;
     procedure LockRecordPage(recordNo: integer);
     procedure UnlockRecordPage(recordNo: integer);
   end;


  // buffer log record
  TaaBufferLogRecord = record
   	curTime	      : Cardinal;			// record time
    physRecNo     : Integer;      // physical record number
    operation     : TaaRecordOperation; // tableoperation
    dataIndex     : Integer;      // index in BLOBData array (if roBLOBWrite);
                                  //  else index in records array
    blobParts     : TaaBLOBPartsArray; // blob part (if roBLOBWrite), else nil
  end;

   TaaBuffersArray=class
    public
     Items  : array of Pointer;
     Sizes  : array of Integer;
     overallSize : LongInt;

     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     constructor Create(size: integer=0);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure Append(buffer : Pointer; size : Integer;
          copyFlag : Boolean = false);
   end;

   TaaBufferLogArray=class
    public
     Items    : array of TaaBufferLogRecord;
     blobData : TaaBuffersArray;

     MaxItems : Integer; // maxItems
     MaxMemAlloc : LongInt; // max memory size for recData
     MaxTime : Cardinal; // max time

     dataFile : TAbstractFile;
     blobFile : TAbstractFile;
     blobBlockSize : integer;
     dataOffset  : Integer;

     ItemCount: integer;
     AllocBy: integer;
     deAllocBy: integer;
     MaxAllocBy: integer;
     AllocItemCount: integer;

     constructor Create(dFile, bFile : TAbstractFile; blockSize : Integer;
                  offset  : Integer;
                  size: integer=0);
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     // adds new record operation to the end of the items array
     procedure Append(oper : TaaRecordOperation;
                      recPtr : PAnsiChar;
                      recSize : Integer = -1;
                      recPos : Integer = -1;
                      moveFlag  : Boolean = true;
                      blobParts: Pointer = nil;
                      numBlobParts: Integer = 0
                      );
     // processec all operation and flush all buffers
     procedure FlushBuffers;
     // checks for overflow, and flushes buffers if it's neccessary
     function CheckOverflow : Boolean;
     // returns true if record exists in buffer (recordNo - physical)
     function IsRecordInBuffer (recordNo : Integer; var pRecBuf : PAnsiChar): Boolean;
   end;

var
  FCSect: Pointer;

implementation

uses EasyTable;

////////////////////////////////////////////////////////////////////////////////
//
// Thread-safe
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Allocates mem for critical section
//------------------------------------------------------------------------------
function  ETblAllocCriticalSection: Pointer;
begin
  Result:=AllocMem(SizeOf(TRTLCriticalSection));
end;// ETblAllocCriticalSection


//------------------------------------------------------------------------------
// Inits data in critical section
//------------------------------------------------------------------------------
procedure ETblInitializeCriticalSection(Section: Pointer);
begin
  Windows.InitializeCriticalSection(TRTLCriticalSection(Section^));
end;// ETblInitializeCriticalSection


//------------------------------------------------------------------------------
// Enters critical section
//------------------------------------------------------------------------------
procedure ETblEnterCriticalSection(Section: Pointer);
begin
  Windows.EnterCriticalSection(TRTLCriticalSection(Section^));
end;// ETblEnterCriticalSection


//------------------------------------------------------------------------------
// Leaves critical section
//------------------------------------------------------------------------------
procedure ETblLeaveCriticalSection(Section: Pointer);
begin
  Windows.LeaveCriticalSection(TRTLCriticalSection(Section^));
end;// ETblLeaveCriticalSection


//------------------------------------------------------------------------------
// Deletes critical section
//------------------------------------------------------------------------------
procedure ETblDeleteCriticalSection(Section: Pointer);
begin
  Windows.DeleteCriticalSection(TRTLCriticalSection(Section^));
end;// ETblDeleteCriticalSection


//------------------------------------------------------------------------------
// Frees mem of critical section
//------------------------------------------------------------------------------
procedure ETblFreeCriticalSection(var Section: Pointer);
begin
  FreeMem(Section);
  Section := nil;
end;// ETblFreeCriticalSection


//------------------------------------------------------------------------------
// Constructor of bits array
//------------------------------------------------------------------------------
constructor TBitsArray.Create(length:integer);
begin
 bitCount := length;
 FBitNo := 0;
 SetLength(bits,bitCount);

 SetBits(false);
end;//TBitsArray.Create


//------------------------------------------------------------------------------
// Destructor of bits array
//------------------------------------------------------------------------------
destructor TBitsArray.Destroy;
begin
 SetLength(bits,0);
 bits := nil;
end;//TBitsArray.Create


//------------------------------------------------------------------------------
// Realloc
//------------------------------------------------------------------------------
procedure TBitsArray.SetSize(length:integer);
begin
 bitCount := length;
 SetLength(bits,bitCount);
end;//TBitsArray.Create

//------------------------------------------------------------------------------
// Find No of first bit with value=bitValue, return -1 if not found
//------------------------------------------------------------------------------
function TBitsArray.FindFirst(bitValue:boolean):integer;
var bFound : boolean;
    i : integer;
begin
 FBitValue := byte(bitValue);
 bFound := false;
 for i:=0 to bitCount-1 do
  if (bits[i] = FBitValue) then
   begin
    bFound := true;
    FBitNo:=i;
    break;
   end;
 if (bFound) then
  result := FBitNo
 else
  result := -1;
end; //TBitsArray.FindFirst


//------------------------------------------------------------------------------
// Find No of next bit with value=bitValue, return -1 if not found
//------------------------------------------------------------------------------
function TBitsArray.FindNext:integer;
var bFound : boolean;
    i : integer;
begin
 bFound := false;
 for i:=FBitNo+1 to bitCount-1 do
  if (bits[i] = FBitValue) then
   begin
    bFound := true;
    FBitNo:=i;
    break;
   end;
 if (bFound) then
  result := FBitNo
 else
  result := -1;
end; //TBitsArray.FindNext


//------------------------------------------------------------------------------
// Set bits[bitNo]:=bitValue
//------------------------------------------------------------------------------
procedure TBitsArray.SetBit(bitNo:integer; bitValue:boolean);
begin
 bits[bitNo]:=byte(bitValue);
end; //TBitsArray.SetBit


//------------------------------------------------------------------------------
// Get bits[bitNo]
//------------------------------------------------------------------------------
function TBitsArray.GetBit(bitNo:integer):boolean;
begin
 result := Boolean(bits[bitNo]);
end; //TBitsArray.GetBit


//------------------------------------------------------------------------------
//  bits[i] := bitValue
//------------------------------------------------------------------------------
procedure TBitsArray.SetBits(bitValue:boolean);
var i:integer;
begin
 for i:=0 to bitCount-1 do
  bits[i] := byte(bitValue);
end; //TBitsArray.SetBits


//------------------------------------------------------------------------------
//  bits[i] := not bits[i]
//------------------------------------------------------------------------------
procedure TBitsArray.NotBits;
var i:integer;
begin
 for i:=0 to bitCount-1 do
  bits[i] := not bits[i];
end; //TBitsArray.NotBits



//------------------------------------------------------------------------------
//  bits[i] := bits[i] and bits1[i]
//------------------------------------------------------------------------------
procedure TBitsArray.AndBits(bits1:TBitsArray);
var i:integer;
begin
 for i:=0 to bitCount-1 do
 bits[i] := bits[i] and bits1.bits[i];
end; //TBitsArray.AndBits


//------------------------------------------------------------------------------
//  bits[i] := not bits[i]
//------------------------------------------------------------------------------
procedure TBitsArray.OrBits(bits1:TBitsArray);
var i:integer;
begin
 for i:=0 to bitCount-1 do
  bits[i] := bits[i] or bits1.bits[i]
end; //TBitsArray.AndBits


//------------------------------------------------------------------------------
//   bits[bitNo] := bits[bitNo] and bitValue
//------------------------------------------------------------------------------
procedure TBitsArray.AndBit(bitNo:integer; bitValue:boolean);
begin
 bits[bitNo] := byte(boolean(bits[bitNo]) and bitValue);
end; //TBitsArray.AndBit


//------------------------------------------------------------------------------
// bits[bitNo] := bits[bitNo] or bitValue
//------------------------------------------------------------------------------
procedure TBitsArray.OrBit(bitNo:integer; bitValue:boolean);
begin
 bits[bitNo] := byte(boolean(bits[bitNo]) or bitValue);
end; //TBitsArray.OrBit


//------------------------------------------------------------------------------
// check if s1[n-...] = s2, ignoring spaces
//------------------------------------------------------------------------------
function TSearchParser.IsStartStr(s1:AnsiString; var n:integer; s2:AnsiString) : boolean;
var n1, n2 : integer;
    bSame : boolean;
begin
 n1 := n;
 n2 := 1;
 bSame := true;

 repeat
  // skip spaces
  while (n1 <=  Length(s1)) do
   if (s1[n1] = ' ') then
    inc(n1)
   else
    break;
  while (n2 <= Length(s2)) do
   if (s2[n2] = ' ') then
    inc(n2)
   else
    break;
  // end of both strings reached
  if (n1 > Length(s1)) and (n2 > Length(s2)) then
   break;
  // end of only 1st string reached
  if ((n1 > Length(s1)) and not (n2 > Length(s2))) then
   begin
    bSame := false;
    break;
   end;
  // different symbols
  if (AnsiLowerCase(s1[n1]) <> AnsiLowerCase(s2[n2])) then
   begin
    bSame := false;
    break;
   end;
  inc(n1);
  inc(n2);
 until (n2>Length(s2));
 if (bSame) then
  n := n1;
 result := bSame;
end;// TSearchParser.IsStarted


//------------------------------------------------------------------------------
//  PreParse boolean expression = <boolean_sum>
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseBooleanExpression(var n:integer);
begin
 // get value of <boolean_sum>
 PreParseBooleanSum(n);
 // check if END OF LINE reached
 if (n < Length(ParsedStr)) then
  Raise Exception.Create('End of line expected, but "'+
                          Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                          '" found');
end;// TSearchParser.PreParseBooleanExpression


//------------------------------------------------------------------------------
//  Parse boolean sum = <boolean_multiplication> {or <boolean_multiplication>}
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseBooleanSum(var n:integer);
begin
 // get value of <boolean_multiplication>
 PreParseBooleanMultiplication(n);

 // repeat while 'or <boolean_multiplication>' found
 while (IsStartStr(ParsedStr,n,'or')) do
  begin
    opArr[opNo].BoolOp := boOr;
    inc(opNo);
    PreParseBooleanMultiplication(n);
  end;
end;// TSearchParser.PreParseBooleanSum


//------------------------------------------------------------------------------
//  PreParse boolean multiplication = <boolean_multiplier>{and <boolean_multiplier>}
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseBooleanMultiplication(var n:integer);
begin
 // get value of <boolean_multiplier>
 PreParseBooleanMultiplier(n);

 // repeat while 'and <boolean_multiplier>' not found
 while (IsStartStr(ParsedStr,n,'and')) do
  begin
    opArr[opNo].BoolOp := boAnd;
    inc(opNo);
   PreParseBooleanMultiplier(n);
  end;
end;// TSearchParser.PreParseBooleanMultiplication


//------------------------------------------------------------------------------
//  PreParse boolean multiplier = NOT <boolean_multiplier> | (<boolean_sum>) | <FieldExpresiion>
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseBooleanMultiplier(var n:integer);
begin
 // NOT <boolean_multiplier> ?
 if (IsStartStr(ParsedStr,n,'not')) then
  begin
   opArr[opNo].BoolOp := boNot;
   inc(opNo);
   PreParseBooleanMultiplier(n);
  end
 else
 // (<boolean_sum>) ?
 if (IsStartStr(ParsedStr,n,'(')) then
  begin
   opArr[opNo].BoolOp := boOpenParenthesis;
   inc(opNo);
   PreParseBooleanSum(n);
   // get closing bracket
   if (not IsStartStr(ParsedStr,n,')')) then
     Raise Exception.Create('Closing bracket ")" expected, but "'+
                            Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                            '" found');
   // if '(<FieldExpression>)' met -> then remove this brackets
    if (opArr[opNo-2].BoolOp = boOpenParenthesis) then
     begin
      opArr[opNo-2].BoolOp := opArr[opNo-1].BoolOp;
      opArr[opNo-2].FieldNo := opArr[opNo-1].FieldNo;
      opArr[opNo-2].FieldName := opArr[opNo-1].FieldName;
      opArr[opNo-2].SearchOp := opArr[opNo-1].SearchOp;
      opArr[opNo-2].ValueBuffer := opArr[opNo-1].ValueBuffer;
      opArr[opNo-1].ValueBuffer := nil;
      opNo := opNo-1;
     end
    else
     begin
      opArr[opNo].BoolOp := boCloseParenthesis;
      inc(opNo);
     end
  end
 else
  PreParseFieldExpression(n);
end;// TSearchParser.PreParseBooleanMultiplier


//------------------------------------------------------------------------------
//  PreParse field expression = <field_name> <field_operation>
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseFieldExpression(var n:integer);
begin
 PreParseFieldName(n);
 PreParseFieldOperation(n);
 opArr[opNo].BoolOp := boNone;
 inc(opNo);
end;// TSearchParser.PreParseFieldExpression


//------------------------------------------------------------------------------
// PreParse field name = FieldName | [Field Name]
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseFieldName(var n:integer);
var s: AnsiString;
    nEnd : integer;
begin
 // [Field Name] ?
 if (IsStartStr(ParsedStr,n,'[')) then
  begin
   // find ']'
   nEnd := Pos(']',Copy(ParsedStr,n,Length(ParsedStr)-n+1));
   if (nEnd = 0) then
     Raise Exception.Create('Closing square bracket "]" expected, but not found in "'+
                            Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                            '"');
   s := Trim(Copy(ParsedStr,n,nEnd-1));
   if (s = '') then
     Raise Exception.Create('Invalid field name "'+Copy(ParsedStr,n,nEnd-n)+'"');
   n := n+nEnd;
  end
 else
  begin
   // skip spaces
   if (n <= Length(ParsedStr)) then
    while (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = ' ') and (n <= Length(ParsedStr)) do
     inc(n);

   s := '';
   while ((n <= Length(ParsedStr)) and
          (((PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ >= 'a') and (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ <= 'z')) or
           ((PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ >= 'A') and (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ <= 'Z')) or
           ((PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ >= '0') and (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ <= '9')) or
           (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '_')))
   do
    begin
     s := s + PAnsiChar(PAnsiChar(ParsedStr)+n-1)^;
     inc(n);
    end;
  end;

 opArr[opNo].FieldName := s;
 opArr[opNo].FieldNo := TEasyDataset(ds).DMHandle.InternalGetFieldNo(s);
end;// TSearchParser.PreParseFieldName


//------------------------------------------------------------------------------
// PreParse field operation = <field_operator> (<field_value>)
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseFieldOperation(var n:integer);
var s:AnsiString;
begin
  PreParseFieldOperator(n);
  if (opArr[opNo].SearchOp <> soIsNull) and
     (opArr[opNo].SearchOp <> soIsNotNull) then
   PreParseFieldValue(n)
  else
  // alloc value buffer for null value
  TEasyDataset(ds).PrepareValueBuffer(opArr[opNo].FieldNo,opArr[opNo].SearchOp,
                                      s,opArr[opNo].ValueBuffer);
end;// TSearchParser.PreParseFieldOperation


//------------------------------------------------------------------------------
// PreParse field operator = '<=' | '>=' | '<>' | '<' | '>' | '=' | 'like' | 'not like'
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseFieldOperator(var n:integer);
var i:TSearchOperator;
    bFound : boolean;
begin
 bFound := false;
 for i:=soEQ to soIsNotNull do
  if (IsStartStr(ParsedStr,n,searchOperators[i])) then
   begin
    opArr[opNo].SearchOp := i;
    bFound := true;
    break;
   end;
 if (not bFound) then
     Raise Exception.Create('Operator expected, but "'+
                            Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                            '"  found');
end;// TSearchParser.PreParseFieldOperator


//------------------------------------------------------------------------------
// PreParse field value = <number> | <text>
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseFieldValue(var n:integer);
begin
 // skip spaces
 while (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = ' ') and (n <= Length(ParsedStr)) do
    inc(n);

 // "text" ?
 if (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '"') then
  PreParseText(n)
 else
 // 'text' ?
 if (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '''') then
  PreParseText(n)
 else
 // true or false ?
 if ((PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = 't') or (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = 'T') or
     (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = 'f') or (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = 'F')) then
  PreParseBoolean(n)
 else
  // <number>
  PreParseNumber(n);
end;// TSearchParser.PreParseFieldValue


//------------------------------------------------------------------------------
// PreParse number
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseNumber(var n:integer);
var s : AnsiString;
    ds: AnsiChar;
begin
 s := '';
{$IFDEF D17H}
 ds := AnsiChar(FormatSettings.DecimalSeparator);
{$ELSE}
 ds := AnsiChar(DecimalSeparator);
{$ENDIF}
 // skip spaces
 while (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = ' ') and (n <= Length(ParsedStr)) do
    inc(n);
 while (n <= Length(ParsedStr)) do
  begin
   if ((PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ >= '0') and
       (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ <= '9') or
       (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = ds) or
       (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '+') or
       (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '-')) then
     begin
       s := s + PAnsiChar(PAnsiChar(ParsedStr)+n-1)^;
       inc(n);
     end
    else
     break;
  end;

 if (s = '') then
   Raise Exception.Create('Number expected, but "'+
                          Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                          '"  found');
 TEasyDataset(ds).PrepareValueBuffer(opArr[opNo].FieldNo,opArr[opNo].SearchOp,
                                      s,opArr[opNo].ValueBuffer);
end;// TSearchParser.PreParseNumber


//------------------------------------------------------------------------------
// PreParse Text or DateTime
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseText(var n:integer);
var s : AnsiString;
    nEnd : integer;
    quote : AnsiChar;
    bQuotedMode : boolean;
begin

 if (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = '''') then
  quote := ''''
 else
  quote := '"';

 s := '';
 nEnd := n+1;
 bQuotedMode := true;
 while (nEnd <= Length(ParsedStr)) do
  begin
   if (PAnsiChar(PAnsiChar(ParsedStr)+nEnd-1)^ = quote) then
    bQuotedMode := not bQuotedMode;

   if (not bQuotedMode) then
    if (PAnsiChar(PAnsiChar(ParsedStr)+nEnd-1)^ <> quote) then
     begin
      inc(nEnd);
      break;
     end;

   if (bQuotedMode) then
    s := s+PAnsiChar(PAnsiChar(ParsedStr)+nEnd-1)^;
   inc(nEnd);
  end;

 if (bQuotedMode) then
   Raise Exception.Create('Unterminated string '+s+Copy(ParsedStr,n,Length(ParsedStr)-n+1));

 n := nEnd-1;

 // date or AnsiString
 opArr[opNo].bPartialCompare := false;
 if (not (foNoPartialCompare in FilterOptions)) then
   begin
    opArr[opNo].bPartialCompare := true;
    if (Length(s) > 0) then
     begin
      if (s[Length(s)] = '*') then
       s := Copy(s,1,Length(s)-1);
     end
    else
     if (opArr[opNo].SearchOp = soEQ) then
      opArr[opNo].SearchOp := soIsNull
     else
     if (opArr[opNo].SearchOp = soNEQ) then
      opArr[opNo].SearchOp := soIsNotNull;
   end;
 TEasyDataset(ds).PrepareValueBuffer(opArr[opNo].FieldNo,opArr[opNo].SearchOp,
                                      s,opArr[opNo].ValueBuffer);
end; // TSearchParser.PreParseText


//------------------------------------------------------------------------------
// PreParse boolean
//------------------------------------------------------------------------------
procedure TSearchParser.PreParseBoolean(var n:integer);
var s : AnsiString;
    bResult : boolean;
begin
 s := '';
 // skip spaces
 while (PAnsiChar(PAnsiChar(ParsedStr)+n-1)^ = ' ') and (n <= Length(ParsedStr)) do
    inc(n);

 // check for 'true'
 s := LowerCase(Copy(ParsedStr,n,Length('true')));
 if (s = 'true') then
  begin
   inc(n, Length('true'));
   bResult := true;
  end
 else
  begin
   // check for 'false'
   s := LowerCase(Copy(ParsedStr,n,Length('false')));
   if (s = 'false') then
    begin
     inc(n, Length('false'));
     bResult := false;
    end
   else
    Raise Exception.Create('Unexpected meet of "'+
                          Copy(ParsedStr,n,Length(ParsedStr)-n+1)+
                          '"  found');
  end;

 if (bResult) then
  s := 'true'
 else
  s := 'false';
 TEasyDataset(ds).PrepareValueBuffer(opArr[opNo].FieldNo,opArr[opNo].SearchOp,
                                      s,opArr[opNo].ValueBuffer);
end;// TSearchParser.PreParseBoolean


//------------------------------------------------------------------------------
// Parse boolean expression from operations array
//------------------------------------------------------------------------------
procedure TSearchParser.ParseBooleanExpression(var n:integer);
begin
 // get value of <boolean_sum>
 ParseBooleanSum(n);
end;//TSearchParser.ParseBooleanExpression


//------------------------------------------------------------------------------
// Parse boolean sum from operations array
//------------------------------------------------------------------------------
procedure TSearchParser.ParseBooleanSum(var n:integer);
begin
 // get value of <boolean_multiplication>
 ParseBooleanMultiplication(n);

 // repeat while 'or <boolean_multiplication>' found
 while ((opArr[n].BoolOp = boOr) and (n < opCount-1)) do
  begin
    inc(n);
    IncBitsArrNo;
    ParseBooleanMultiplication(n);
    bitsArr[bitsArrNo-1].OrBits(bitsArr[bitsArrNo]);
    dec(bitsArrNo);
  end;
end;//TSearchParser.ParseBooleanSum


//------------------------------------------------------------------------------
// Parse boolean multiplication from operations array
//------------------------------------------------------------------------------
procedure TSearchParser.ParseBooleanMultiplication(var n:integer);
begin
 // get value of <boolean_multiplier>
 ParseBooleanMultiplier(n);

 // repeat while 'and <boolean_multiplier>' not found
 while ((opArr[n].BoolOp = boAnd) and (n < opCount-1)) do
  begin
    inc(n);
    IncBitsArrNo;
    ParseBooleanMultiplier(n);
    bitsArr[bitsArrNo-1].AndBits(bitsArr[bitsArrNo]);
    dec(bitsArrNo);
  end;
end;//TSearchParser.ParseBooleanMultiplication


//------------------------------------------------------------------------------
// Parse boolean multiplier from operations array
//------------------------------------------------------------------------------
procedure TSearchParser.ParseBooleanMultiplier(var n:integer);
begin
 if (n >= opCount) then
  exit;

 // NOT <boolean_multiplier> ?
 if (opArr[n].BoolOp = boNot) then
  begin
   inc(n);
   ParseBooleanMultiplier(n);
   bitsArr[bitsArrNo].NotBits;
  end
 else
 // (<boolean_sum>) ?
 if (opArr[n].BoolOp = boOpenParenthesis) then
  begin
   inc(n);
   ParseBooleanSum(n);
   // get closing bracket
   inc(n);
  end
 else
  ParseFieldExpression(n);
end;//TSearchParser.ParseBooleanMultiplier


//------------------------------------------------------------------------------
// Parse field expression from operations array
//------------------------------------------------------------------------------
procedure TSearchParser.ParseFieldExpression(var n:integer);
begin
 bitsArr[bitsArrNo].SetBits(false);
 TEasyDataset(ds).GetMatchedRecords(opArr[n],FilterOptions,bitsArr[bitsArrNo]);
 inc(n);
end;//TSearchParser.ParseFieldExpression


//------------------------------------------------------------------------------
// Check boolean expression from operations array
//------------------------------------------------------------------------------
function TSearchParser.CheckBooleanExpression(var n:integer): boolean;
begin
 // get value of <boolean_sum>
 result := CheckBooleanSum(n);
end;//TSearchParser.CheckBooleanExpression


//------------------------------------------------------------------------------
// Check boolean sum from operations array
//------------------------------------------------------------------------------
function TSearchParser.CheckBooleanSum(var n:integer): boolean;
begin
 // get value of <boolean_multiplication>
 result := CheckBooleanMultiplication(n);

 // repeat while 'or <boolean_multiplication>' found
 while ((opArr[n].BoolOp = boOr) and (n < opCount-1)) do
  begin
    inc(n);
    result := result or CheckBooleanMultiplication(n);
  end;
end;//TSearchParser.CheckBooleanSum


//------------------------------------------------------------------------------
// Check boolean multiplication from operations array
//------------------------------------------------------------------------------
function TSearchParser.CheckBooleanMultiplication(var n:integer): boolean;
begin
 // get value of <boolean_multiplier>
 result := CheckBooleanMultiplier(n);

 // repeat while 'and <boolean_multiplier>' not found
 while ((opArr[n].BoolOp = boAnd) and (n < opCount-1)) do
  begin
    inc(n);
    result := result and CheckBooleanMultiplier(n);
  end;
end;//TSearchParser.CheckBooleanMultiplication


//------------------------------------------------------------------------------
// Check boolean multiplier from operations array
//------------------------------------------------------------------------------
function TSearchParser.CheckBooleanMultiplier(var n:integer): boolean;
begin
 result := false;
 if (n >= opCount) then
  exit;

 // NOT <boolean_multiplier> ?
 if (opArr[n].BoolOp = boNot) then
  begin
   inc(n);
   result := not CheckBooleanMultiplier(n);
  end
 else
 // (<boolean_sum>) ?
 if (opArr[n].BoolOp = boOpenParenthesis) then
  begin
   inc(n);
   result := CheckBooleanSum(n);
   // get closing bracket
   inc(n);
  end
 else
  result := CheckFieldExpression(n);
end;//TSearchParser.CheckBooleanMultiplier


//------------------------------------------------------------------------------
// Check field expression from operations array
//------------------------------------------------------------------------------
function TSearchParser.CheckFieldExpression(var n:integer): boolean;
begin
 result := TEasyDataset(ds).IsRecordMatches(opArr[n],FilterOptions,recordBuffer);
 inc(n);
end;//TSearchParser.CheckFieldExpression


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TSearchParser.Create(ds1 : TDataset);
var i:integer;
begin
 ds := ds1;
 AllocBy := 5;
 bitsArrCount := AllocBy;
 SetLength(bitsArr,bitsArrCount);
 for i:=0 to bitsArrCount-1 do
  bitsArr[i] := TBitsArray.Create(0);
 opArr := nil;
end; //TSearchParser.Create


//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TSearchParser.Destroy;
var i:integer;
begin
 for i:=0 to Length(opArr)-1 do
  if (opArr[i].ValueBuffer <> nil) then
   FreeMem(opArr[i].ValueBuffer);
 opArr := nil;

 for i:=0 to bitsArrCount-1 do
   bitsArr[i].Free;
end; //TSearchParser.Destroy


//------------------------------------------------------------------------------
// Parsing Filter -> array of TFilterOperations
//------------------------------------------------------------------------------
procedure TSearchParser.PreParse(Filter:AnsiString);
var i,n,oldLength,newLength : integer;
begin
 // allocate memory for operation records
 newLength := Length(Filter) div 2;
 oldLength := Length(opArr);
 if (oldLength < newLength) then
  begin
   SetLength(opArr,newLength);
   for i:=oldLength to newLength-1 do
    opArr[i].ValueBuffer := nil;
  end;

 // free buffers
 for i:=0 to newLength-1 do
  if (opArr[i].ValueBuffer <> nil) then
   begin
    FreeMem(opArr[i].ValueBuffer);
    opArr[i].ValueBuffer := nil;
   end;

 parsedStr := Filter;
 n := 1;
 opNo := 0;
 if (Trim(Filter) <> '') then
  PreParseBooleanExpression(n);
 opCount := opNo;
end; //TSearchParser.PreParse


//------------------------------------------------------------------------------
// Parsing array of TFilterOperations
//------------------------------------------------------------------------------
procedure TSearchParser.Parse;
var i,n:integer;
begin
 if (opCount = 0) then
  raise Exception.Create('TSearchParser.Parse - Expression is blank.');
 for i:=0 to bitsArrCount-1 do
  if (bitsArr[i].bitCount <> TEasyDataset(ds).DMHandle.TableHeader.RecordCount) then
    bitsArr[i].SetSize(TEasyDataset(ds).DMHandle.TableHeader.RecordCount);

 n := 0;
 ParseBooleanExpression(n);
 n := 0;
end; //TSearchParser.Parse


//------------------------------------------------------------------------------
// Check if record matches criteria
//------------------------------------------------------------------------------
function TSearchParser.IsRecordMatches(recordBuf: PAnsiChar): boolean;
var n:integer;
begin
 n := 0;
 recordBuffer := recordBuf;
 result := CheckBooleanExpression(n);
 n := 0;
end;


//------------------------------------------------------------------------------
// increase No and reallocates memory if neccessary
//------------------------------------------------------------------------------
procedure TSearchParser.IncBitsArrNo();
var i : integer;
begin
 inc(bitsArrNo);
 if (bitsArrNo >= bitsArrCount) then
  begin
   SetLength(bitsArr,BitsArrCount+AllocBy);
   for i:=bitsArrCount to bitsArrCount+AllocBy-1 do
    bitsArr[i] := TBitsArray.Create(TEasyDataset(ds).DMHandle.TableHeader.RecordCount);
   bitsArrCount := bitsArrCount+AllocBy;
  end;
end;

//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaIntArray.Create(
  size: integer = 0;
  DefaultAllocBy: integer = 1000;
  MaximumAllocBy: integer = 10000
  );
begin
 AllocBy := DefaultAllocBy; // default alloc
 deAllocBy := DefaultAllocBy; // default dealloc
 MaxAllocBy := MaximumAllocBy; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TaaIntArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaIntArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TaaIntArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaIntArray.Assign(v: TaaIntArray);
var
  i: integer;
begin
  SetSize(v.ItemCount);
  for i := 0 to ItemCount-1 do
    items[i] := v.items[i];
end;// Assign


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaIntArray.SetSize(newSize: integer);
begin
{
 ItemCount := newSize;
 if (ItemCount > 0) then
  SetLength(Items,ItemCount)
 else
  Items := nil;
Exit;
}
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TaaIntArray.SetSize


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TaaIntArray.Append(value: integer);
begin
 SetSize(itemCount + 1);
 Items[itemCount-1] := value;
end;//TaaIntArray.Append


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TaaIntArray.Insert(itemNo: integer; value: integer);
begin
 inc(ItemCount);
 SetSize(ItemCount);

//aaStartTime;
 if (itemCount <= 1) then
  items[0] := value
 else
 if (itemNo >= itemCount-1)
  then
   items[itemCount-1] := value
  else
   begin
    Move(items[itemNo],items[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    items[itemNo] := value;
   end;
//aaStopTime;
end;//TaaIntArray.Insert


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TaaIntArray.Delete(itemNo: integer);
begin
 if (itemNo < itemCount-1) then
  Move(items[itemNo+1],items[itemNo],
      (itemCount - itemNo-1) * sizeOf(integer));
 dec(ItemCount);
 SetSize(ItemCount);
end;//TaaIntArray.Delete


//------------------------------------------------------------------------------
// moves element to new position
//------------------------------------------------------------------------------
procedure TaaIntArray.MoveTo(itemNo, newItemNo : integer);
var value : Integer;
begin
 if (itemNo = newItemNo) then
  Exit;
 if (itemNo - newItemNo = 1) or (newItemNo-itemNo = 1) then
  begin
   value := items[itemNo];
   items[itemNo] := items[newItemNo];
   items[newItemNo] := value;
   Exit;
  end;
 if (itemNo > newItemNo) then
  begin
   value := items[itemNo];
   Move(items[newItemNo],items[newItemNo+1],
        (itemNo-newItemNo) * sizeof(Integer));
   items[newItemNo] := value;
  end
 else
  begin
     value := items[ItemNo];
     Move(items[ItemNo+1],items[ItemNo],
        (newItemNo-ItemNo-1) * sizeof(Integer));
     items[newItemNo-1] := value;
  end;

end; //MoveTo(itemNo, newItemNo : integer);


//------------------------------------------------------------------------------
// copies itemCount elements to ar from ItmeNo
//------------------------------------------------------------------------------
procedure TaaIntArray.CopyTo(var ar : array of Integer;
                      itemNo,iCount : integer);
begin
 if (itemCount > 0) then
  Move (items[itemNo],ar[0],sizeOf(Integer)*iCount);
end; //CopyTo(ar : array of Integer; itemNo,itemCount : integer);


//------------------------------------------------------------------------------
// returns true if value exists in Items array
//------------------------------------------------------------------------------
function TaaIntArray.IsValueExists(value: integer): Boolean;
var i: integer;
begin
 result := false;
 for i := 0 to ItemCount-1 do
  if Items[i] = value then
   begin
    result := true;
    break;
   end;
end; // IsValueExists


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaSortedIntArray.Create(size: integer=0);
begin
 AllocBy := 1000; // default alloc
 deAllocBy := 1000; // default dealloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TaaSortedIntArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaSortedIntArray.Destroy;
begin
 KeyItems := nil;
 ValueItems := nil;
 inherited Destroy;
end;//TaaSortedIntArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaSortedIntArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   KeyItems := nil;
   ValueItems := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(KeyItems,allocItemCount);
     SetLength(ValueItems,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(KeyItems,newSize);
     SetLength(ValueItems,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TaaSortedIntArray.SetSize


//------------------------------------------------------------------------------
// Finds position for insert element
//------------------------------------------------------------------------------
function TaaSortedIntArray.FindPositionForInsert(key: Integer) : Integer;
var i,dx,f,
    oldRes,res : Integer;
begin
 i := itemCount shr 1;
 dx := i;
 result := itemCount;
 if (itemCount > 0) then
 begin
  f := 0;
  res := 2;
  while (true) do
   begin
    dx := dx shr 1;
    if (dx < 1) then dx := 1;
     oldRes := res;
     // compare, ascending
     if (KeyItems[i] = key) then
      res := 0
     else
      if (KeyItems[i] < key) then
       res := 1
      else
       res := -1;
    if (res < 0) then
     begin
      //  element, specified by value should be higher then current element (+->0)
      i := i - dx;
     end
    else
    if (res > 0) then
     begin
      //  element, specified by value should be lower then current element (+->0)
      i := i + dx;
     end
    else // values are equal
     begin
      Result := i;
      break;
     end;
    if  (i < 0) and (dx = 1) then
     begin
      Result := 0;
      break;
     end;
    if  (i > itemCount-1) and (dx = 1) then
     begin
      Result := itemCount;
      break;
     end;

    if  (i > itemCount-1) then
     i := itemCount-1;
    if  i < 0 then
     i := 0;

    if (dx = 1) and (f > 1) then
     begin
      // dx minimum
      // compare, ascending
      if (KeyItems[i] = key) then
       res := 0
      else
       if (KeyItems[i] < key) then
        res := 1
       else
        res := -1;

      if (res < 0) and (oldRes > 0) then
       Result := i;
      if (res > 0) and (oldRes < 0) then
       Result := i+1;
      if (res = oldRes) then
       continue;
      break;
     end;// last step
    if (res <> oldRes) and (dx = 1) and (oldRes <> 2) then
     inc(f);
  end;//while dx
 end; // if itemCount > 0
end; //FindPositionForInsert


//------------------------------------------------------------------------------
// Finds position for insert element
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TaaSortedIntArray.FindPosition(key: Integer): Integer;
begin
 Result := FindPositionForInsert(key);
 if (Result >= itemCount) or (Result < 0) then
  Result := -1
 else
  if (KeyItems[Result] <> key) then
   Result := -1;
end;// TaaSortedIntArray.FindPosition


//------------------------------------------------------------------------------
// Finds value for specified key
// returns -1 if element was not found
//------------------------------------------------------------------------------
function TaaSortedIntArray.Find(key: Integer): Integer;
begin
 Result := FindPositionForInsert(key);
 if (Result >= itemCount) or (Result < 0) then
  Result := -1
 else
  if (KeyItems[Result] <> key) then
   Result := -1
 else
  Result := ValueItems[Result];
end; //Find(value : Integer) : Integer;


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TaaSortedIntArray.InsertByPosition(itemNo: integer; key,value: integer);
begin
 inc(ItemCount);
 SetSize(ItemCount);

 if (itemCount <= 1) then
  begin
   KeyItems[0] := key;
   ValueItems[0] := value;
  end
 else
 if (itemNo >= itemCount-1)
  then
   begin
    KeyItems[itemCount-1] := key;
    ValueItems[itemCount-1] := value;
   end
  else
   begin
    Move(KeyItems[itemNo],KeyItems[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    Move(ValueItems[itemNo],ValueItems[itemNo+1],
        (itemCount - itemNo-1) * sizeOf(integer));
    KeyItems[itemNo] := key;
    ValueItems[itemNo] := value;
   end;
end;//TaaSortedIntArray.InsertByPosition


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TaaSortedIntArray.Insert(key,value: integer);
var pos : Integer;
begin
 if (itemCount <= 0) then
  InsertByPosition(0,key,value)
 else
  if (itemCount = 1) then
   begin
    if (KeyItems[0] <= key) then
     InsertByPosition(1,key,value)
    else
     InsertByPosition(0,key,value);
   end
  else
   begin
    pos := FindPositionForInsert(key);
    InsertByPosition(pos,key,value);
   end;
end;


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TaaSortedIntArray.DeleteByPosition(itemNo: integer);
begin
 if (itemNo < itemCount-1) then
  begin
   Move(KeyItems[itemNo+1],KeyItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(integer));
   Move(ValueItems[itemNo+1],ValueItems[itemNo],
       (itemCount - itemNo-1) * sizeOf(integer));
  end;
 dec(ItemCount);
 SetSize(ItemCount);
end;//TaaSortedIntArray.DeleteByPosition


//------------------------------------------------------------------------------
// Delete an element by specified key
//------------------------------------------------------------------------------
procedure TaaSortedIntArray.Delete(key: integer);
var pos : Integer;
begin
 if (itemCount <= 0) then
  raise Exception.Create('TaaSortedIntArray.Delete - no elements in array!');
 if (itemCount = 1) then
  DeleteByPosition(0)
 else
  begin
   pos := FindPosition(key);
   if (pos < 0) then
     raise Exception.Create('TaaSortedIntArray.Delete - element not found, key = '+
      InttoStr(key)+', itemCount = '+InttoStr(itemCount)+'!');
   DeleteByPosition(pos);
  end;
end;//TaaSortedIntArray.Delete


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaBLOBHeadersArray.Create(size: integer=0);
begin
 AllocBy := 1000; // default alloc
 deAllocBy := 1000; // default dealloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 SetSize(size);
end;//TaaBLOBHeadersArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaBLOBHeadersArray.Destroy;
var i : integer;
begin
 for i := 0 to ItemCount -1 do
  Parts[i] := nil;
 Parts := nil;
 Headers := nil;
 inherited Destroy;
end;//TaaBLOBHeadersArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaBLOBHeadersArray.SetSize(newSize: integer);
var i : integer;
begin
 if (newSize = 0) then
  begin
   for i := 0 to allocItemCount - 1 do
    Parts[i] := nil;
   Parts := nil;
   ItemCount := 0;
   allocItemCount := 0;
   AllocBy := 1000; // default alloc
   deAllocBy := 1000; // default dealloc
   Headers := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Headers,allocItemCount);
     SetLength(Parts,allocItemCount);
// aaStartTime;
     for i := itemCount to allocItemCount -1 do
      begin
       Parts[i] := nil;
//       Parts[i] := TaaBLOBPartsArray.Create(1);
//       Parts[i] := TaaBLOBPartsArray.Create;
       Headers[i].size := 0;
       Headers[i].numParts := 0;
      end;
// aaStopTime;
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Headers,newSize);

     for i := newSize to allocItemCount -1 do
      begin
       Parts[i] := nil;
//       if (Parts[i] = nil) then
//        raise Exception.Create('TaaBLOBHeadersArray.SetSize - dealloc, newSize = '+
//         Inttostr(newSize));
//        Parts[i].Free;
      end;

     SetLength(Parts,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
{
 if (newSize = itemCount) then Exit;
 if (newSize > 0) then
  begin
aaStartTime;
   SetLength(Headers,newSize);
aaStopTime;
   if (newSize > itemCount) then
    begin
     SetLength(Parts,newSize);
     for i := itemCount to newSize -1 do
      begin
       Parts[i] := TaaBLOBPartsArray.Create;
       Headers[i].size := 0;
      end;
    end
   else
    begin
     for i := newSize to itemCount -1 do
      Parts[i].Free;
     SetLength(Parts,newSize);
    end;
   ItemCount := newSize;
  end
 else
  begin
   Headers := nil;
   for i := 0 to itemCount -1 do
    Parts[i].Free;
   Parts := nil;
   ItemCount := 0;
  end;
  }
end;//TaaBLOBHeadersArray.SetSize


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TaaBLOBHeadersArray.Delete(itemNo: integer; qty : integer = 1);
var i : integer;
begin
//aaStartTime;
 if (itemNo < itemCount-qty) then
  begin
   for i := itemNo to itemNo+qty-1 do
    Parts[i] := nil;
   Move(Headers[itemNo+qty],Headers[itemNo],
      (itemCount - itemNo-qty) * sizeOf(TaaBLOBHeader));
   Move(Parts[itemNo+qty],Parts[itemNo],
      (itemCount - itemNo-qty) * sizeOf(TaaBLOBPartsArray));
  end;
//aaStopTime;
 SetSize(ItemCount-qty);
end;//TaaBLOBHeadersArray.Delete

//------------------------------------------------------------------------------
// Clears all parts for this header and resets header
//------------------------------------------------------------------------------
procedure TaaBLOBHeadersArray.ClearParts(itemNo : integer);
begin
 headers[itemNo].numParts := 0;
 headers[itemNo].size := 0;
 headers[itemNo].trueSize := 0;
 parts[itemNo] := nil;
end; //ClearParts(itemNo : integer);


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaBLOBPartsArray.Create(size: integer=0);
begin
 AllocBy := 1; // default alloc
 deAllocBy := 1; // default dealloc
 MaxAllocBy := 1; // max alloc
 AllocItemCount := 0;
//aaStartTime;
 SetSize(size);
//aaStopTime;
end;//TaaBLOBPartsArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaBLOBPartsArray.Destroy;
begin
 Items := nil;
 inherited Destroy;
end;//TaaBLOBItemsArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaBLOBPartsArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   AllocBy := 1; // default alloc
   deAllocBy := 1; // default dealloc
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TaaBLOBItemsArray.SetSize


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TaaBLOBPartsArray.Insert(itemNo: integer; value : TaaBLOBPart);
begin
 SetSize(itemCount + 1);

 if (itemCount <= 1) then
  begin
   Items[0] := value;
  end
 else
 if (itemNo >= itemCount-1)
  then
   begin
    Items[itemCount-1] := value;
   end
  else
   begin
    Move(Items[itemNo],Items[itemNo+1],
      (itemCount - itemNo-1) * sizeOf(TaaBLOBPart));
    Items[itemNo] := value;
   end;
end;//TaaBLOBItemsArray.Insert


//------------------------------------------------------------------------------
// inserts an element to the end of items array
//------------------------------------------------------------------------------
procedure TaaBLOBPartsArray.Append(value : TaaBLOBPart);
begin
 SetSize(itemCount + 1);
 Items[itemCount-1] := value;
end;//TaaBLOBItemsArray.Append


//------------------------------------------------------------------------------
// Delete an element at specified position
//------------------------------------------------------------------------------
procedure TaaBLOBPartsArray.Delete(itemNo: integer);
begin
 if (itemNo < itemCount-1) then
  begin
   Move(Items[itemNo+1],Items[itemNo],
      (itemCount - itemNo-1) * sizeOf(TaaBLOBPart));
  end;
 SetSize(itemCount-1);
end;//TaaBLOBItemsArray.Delete


//------------------------------------------------------------------------------
// appends all items from src to the end of the items array
//------------------------------------------------------------------------------
procedure TaaBLOBPartsArray.AppendFrom (src: array of TaaBLOBPart; qty: integer);
begin
 if (qty <= 0) then
  Exit;
 SetSize(itemCount+qty);
 Move (src[0],items[itemCount-qty],
      qty * sizeOf(TaaBLOBPart));
end;


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TRecordsPage.Create(NewMaxRecordCount: integer; NewDMHandle: Pointer);
begin
 DMHandle := NewDMHandle;
 RecordSize := TEasyDataManager(DMHandle).recInfoBufferSize;
 pData := nil;
 MaxRecordCount := NewMaxRecordCount;
 RecordCount := 0;
 PageNo := -1;
 UseCount := 0;
 LastUseTime := GetTickCount;
 LockCount := 0;
end;// TRecordsPage.Create;


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TRecordsPage.Destroy;
begin
 MaxRecordCount := 0;
end;// TRecordsPage.Destroy;


//------------------------------------------------------------------------------
// set new page size
//------------------------------------------------------------------------------
procedure TRecordsPage.SetMaxRecordCount(value: integer);
begin
 FMaxRecordCount := value;
 try
  ReallocMem(pData, FMaxRecordCount*RecordSize);
 except
  raise Exception.Create('TRecordsPage.SetMaxRecordCount - Unable to realloc memory.');
 end;
end;// TRecordsPage.SetMaxRecordCount


//------------------------------------------------------------------------------
// set access variables
//------------------------------------------------------------------------------
procedure TRecordsPage.SetAccessVariables;
begin
 inc(UseCount);
 LastUseTime := GetTickCount;
end;// TRecordsPage.SetAccessVariables;


//------------------------------------------------------------------------------
// is record in this page
//------------------------------------------------------------------------------
function TRecordsPage.RecordExists(RecordNo: integer): boolean;
begin
 if (RecordNo < FirstRecordNo) or (RecordNo >= FirstRecordNo+RecordCount) then
  result := false
 else
  result := true;
end;// TRecordsPage.RecordExists


//------------------------------------------------------------------------------
// get record ptr
//------------------------------------------------------------------------------
function TRecordsPage.GetRecordPtr(RecordNo: integer): PAnsiChar;
begin
  SetAccessVariables;
  if (RecordExists(RecordNo)) then
   result := pData+(RecordNo-FirstRecordNo)*RecordSize
  else
   raise Exception.Create('TRecordsPage.GetRecordPtr - Cannot find record');
end;// TRecordsPage.GetRecordPtr


//------------------------------------------------------------------------------
// append new record
//------------------------------------------------------------------------------
function TRecordsPage.AppendRecord(pRecordBuffer: PAnsiChar): PAnsiChar;
var
    pDestBuffer: PAnsiChar;
//    RecNo: integer;
begin
 // if overflow then error
 if (RecordCount >= MaxRecordCount) then
  raise Exception.Create('TRecordsPage.AppendRecord - Page overflow.');
 inc(RecordCount);
 pDestBuffer := GetRecordPtr(FirstRecordNo+RecordCount-1);
 if (pRecordBuffer <> nil) then
  Move(pRecordBuffer^, pDestBuffer^, RecordSize);
 SetAccessVariables;
 result := pDestBuffer;
end;// TRecordsPage.AppendRecord


//------------------------------------------------------------------------------
// copy some records into dest buffer
//------------------------------------------------------------------------------
procedure TRecordsPage.CopyRecords(StartRecNo: integer; pDestBuffer: PAnsiChar; Count: integer);
var
    pBuf: PAnsiChar;
begin
 if (not RecordExists(StartRecNo)) then
  raise Exception.Create('TRecordsPage.CopyRecords - StartRecNo is not in this page.');
 if (Count > RecordCount) then
  raise Exception.Create('TRecordsPage.CopyRecords - Copy more records than available.');
 pBuf := GetRecordPtr(StartRecNo);
 Move(pBuf^, pDestBuffer^, RecordSize*Count);
end;// TRecordsPage.CopyRecords


//------------------------------------------------------------------------------
// remove last record
//------------------------------------------------------------------------------
procedure TRecordsPage.DeleteLastRecord;
begin
 Dec(RecordCount);
 SetAccessVariables;
 // if empty - then reload
 if (RecordCount < 0) then
  raise Exception.Create('TRecordsPage.DeleteLastRecord - Page is already empty.');
end;// TRecordsPage.DeleteLastRecord


//------------------------------------------------------------------------------
// read page
//------------------------------------------------------------------------------
procedure TRecordsPage.Read(NewPageNo: integer);
var
    DMHnd: TEasyDataManager;
    StartRecNo: integer;
    RecCount: integer;
begin
 PageNo := NewPageNo;
 UseCount := 0;
 DMHnd := TEasyDataManager(DMHandle);
 StartRecNo := NewPageNo*FMaxRecordCount;
 if (StartRecNo + FMaxRecordCount >= DMHnd.tableHeader.recordCount) then
  RecCount := DMHnd.tableHeader.recordCount - StartRecNo
 else
  RecCount := FMaxRecordCount;
 ReadRecords(StartRecNo, RecCount);
end;// TRecordsPage.Read


//------------------------------------------------------------------------------
// read records
//------------------------------------------------------------------------------
procedure TRecordsPage.ReadRecords(StartRecNo: integer; RecCount: integer);
var
    DMHnd: TEasyDataManager;
    pBuf, pBuf2: PAnsiChar;
    pos,i,offset: integer;
    bNeedOpenFiles: boolean;
begin
 DMHnd := TEasyDataManager(DMHandle);
 bNeedOpenFiles := (DMHnd.tableFile = nil);
 if (bNeedOpenFiles) then
  DMHnd.OpenFilesForDesigning;
//DMHnd.FlushBuffers;
 FirstRecordNo := StartRecNo;
 RecordCount := RecCount;
 if (RecordCount > MaxRecordCount) then
  raise Exception.Create('TRecordsPage.ReadRecords - Cannot read so many records.');
 DMHnd.tableFile.Seek(DMHnd.tableHeaderSize+FirstRecordNo*RecordSize,soFromBeginning);
 pBuf := GetRecordPtr(FirstRecordNo);
// DMHnd.tableFile.Read(pBuf^, RecordCount*RecordSize);
 offset := 0;
 for i := StartRecNo to StartRecNo + RecordCount-1 do
  begin
   if (DMHnd.bufferLog.IsRecordInBuffer(i,pBuf2)) then
    begin
     Move(pAnsiChar(pBuf2)^,pAnsiChar(pBuf+offset)^,RecordSize);
    end
   else
    begin
     pos := DMHnd.tableHeaderSize + i * RecordSize;
     if (DMHnd.tableFile.Position <> pos) then
      DMHnd.tableFile.Seek(pos,soFromBeginning);
     DMHnd.tableFile.Read(pAnsiChar(pBuf+offset)^, RecordSize);
    end;
   // decrypt if necessary
   if (DMHnd.FEncrypted) then
     DMHnd.ChangeBufferEncryption(pAnsiChar(pBuf+offset), 0);
   inc(offset,RecordSize);
  end;
 if (bNeedOpenFiles) then
  DMHnd.CloseFilesForDesigning;
end;// TRecordsPage.ReadRecords


//------------------------------------------------------------------------------
// delete all records starting from RecNo
//------------------------------------------------------------------------------
procedure TRecordsPage.DeleteRecords(StartRecNo: integer);
begin
 SetAccessVariables;
 if RecordExists(StartRecNo) then
  RecordCount := StartRecNo-FirstRecordNo
 else
  raise Exception.Create('TRecordsPage.DeleteRecords - Cannot find record');
end;// TRecordsPage.DeleteRecords


//------------------------------------------------------------------------------
// init page
//------------------------------------------------------------------------------
procedure TRecordsPage.Init(NewPageNo: integer);
begin
 PageNo := NewPageNo;
 UseCount := 0;
 LastUseTime := GetTickCount;
 FirstRecordNo := PageNo*FMaxRecordCount;
 RecordCount := 0;
end;// TRecordsPage.Init



//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaRecordsArray.Create(pDataManager: Pointer; FastOpenValue: Boolean);
begin
   DMHandle := pDataManager;
   RecordPageNoArr := TaaSortedIntArray.Create;
   bLargePagesMode := true;
   FastOpen := FastOpenValue;
   ResetPages;
end;//TaaRecordsArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaRecordsArray.Destroy;
var
    i: integer;
begin
 RecordPageNoArr.Free;
 for i:=0 to PageCount-1 do
  if (RecordPage[i] <> nil) then
    RecordPage[i].Free;
 SetLength(RecordPage, 0);
 inherited Destroy;
end;// TaaRecordsArray.Destroy;


//------------------------------------------------------------------------------
// Check is it needed - Reset Pages
//------------------------------------------------------------------------------
procedure TaaRecordsArray.CheckResetPages;
var
    i: integer;
    bLocked: boolean;
begin
 // switch large pages to small?
 if ((bAllPagesAllocated) and (bLargePagesMode)) then
  begin
   bLocked := false;
   for i:=0 to PageCount-1 do
    if (RecordPage[i] <> nil) then
     if (RecordPage[i].LockCount > 0) then
      begin
       bLocked := true;
       break;
      end;
   if (not bLocked) then
    begin
     bLargePagesMode := false;
     ResetPages;
    end;
  end;
end;// TaaRecordsArray.CheckResetPages


//------------------------------------------------------------------------------
// Reset Pages - for new page size
//------------------------------------------------------------------------------
procedure TaaRecordsArray.ResetPages;
var
    memStatus : MEMORYSTATUS;
    MaxRecordCount: integer;
    MaxMemAlloc: Cardinal;
    i: integer;
begin
   GlobalMemoryStatus(memStatus);
   MaxMemAlloc := memstatus.dwAvailPhys div 3; // 33% available memory
   MaxRecordCount := MaxMemAlloc div Cardinal(TEasyDataManager(DMHandle).recInfoBufferSize);
   // if table cannot fit in memory - set small pages mode
   if (MaxRecordCount < TEasyDataManager(DMHandle).tableHeader.RecordCount) then
     bLargePagesMode := false;
   // if fast open or In-Memory mode - set small pages mode
   if (FastOpen){ or
      (TEasyDataManager(DMHandle).FFileStoreMode = fsmInMemory)} then
     bLargePagesMode := false;

   // set large or small page mode
   if (bLargePagesMode) then
    begin
      if (TEasyDataManager(DMHandle).PageRecordCount <> -1) then
       PageRecordCount := (TEasyDataManager(DMHandle).PageRecordCount div 3) + 1
      else
       PageRecordCount := DefaultRecordsPerPage;
//      PageRecordCount := 1;
      PageCount := DefaultRecordPages;
    end;

   // fit in memory?
   if (PageCount * PageRecordCount <
       TEasyDataManager(DMHandle).tableHeader.RecordCount) then
      bLargePagesMode := false;

   if (not bLargePagesMode) then
    begin
      // clear pagesNo array
      RecordPageNoArr.Free;
      RecordPageNoArr := TaaSortedIntArray.Create;
      // clear previously allocated pages
      for i:=0 to Length(RecordPage)-1 do
       if (RecordPage[i] <> nil) then
        RecordPage[i].Free;
      PageRecordCount := 1;
      PageCount := 25;
    end;

   // alloc array of pages
   SetLength(RecordPage, PageCount);
   for i:=0 to PageCount-1 do
    RecordPage[i] := nil;
   // no end page yet
   EndPageIndex := -1;
   // no pages allocated
   bAllPagesAllocated := false;
end;// TaaRecordsArray.ResetPages;


//------------------------------------------------------------------------------
// Find page by PageNo
//------------------------------------------------------------------------------
function TaaRecordsArray.GetPageIndex(PageNo: integer): integer;
begin
  result := RecordPageNoArr.Find(PageNo);
end;// TaaRecordsArray.GetPageIndex


//------------------------------------------------------------------------------
// find page to use
//------------------------------------------------------------------------------
function TaaRecordsArray.GetPageToUse(NewPageNo: integer): integer;
var
    i: integer;
    FreePageIndex: integer;
    OldestPageIndex: integer;
    UselessPageIndex: integer;
    minUseCount: integer;
    minUseTime: integer;
    curTime: integer;
    bFirst: boolean;
begin
 FreePageIndex := -1;
 OldestPageIndex := -1;
 UselessPageIndex := -1;
 curTime := GetTickCount;
 minUseCount := 10000;
 minUseTime := curTime;
 bFirst := true;
 for i:=0 to PageCount-1 do
 // don't use end page
 if (i <> EndPageIndex) then
  begin
   // Free Page?
   if (RecordPage[i] = nil) then
    begin
      RecordPage[i] := TRecordsPage.Create(PageRecordCount, DMHandle);
      FreePageIndex := i;
      break;
    end
   else
   if (RecordPage[i].LockCount = 0) then
    begin
     // Free Page?
     if (RecordPage[i].PageNo = -1) then
      begin
        FreePageIndex := i;
        break;
      end;
     // Useless page
     if (bFirst) or (RecordPage[i].UseCount < minUseCount) then
      begin
       minUseCount := RecordPage[i].UseCount;
       UselessPageIndex := i;
      end;
     // Oldest page
     if (bFirst) or (Integer(curTime-RecordPage[i].LastUseTime) > 100) then
      begin
       if (bFirst) then
        begin
         minUseTime := RecordPage[i].LastUseTime;
         OldestPageIndex := i;
         bFirst := false;
        end
       else
        if (RecordPage[i].LastUseTime < minUseTime) then
         begin
          minUseTime := RecordPage[i].LastUseTime;
          OldestPageIndex := i;
         end;
      end;
    end;
   end;
 // result = FreePageIndex?
 if (FreePageIndex >= 0) then
  result := FreePageIndex
 else
 if (OldestPageIndex >= 0)  then
  result := OldestPageIndex
 else
 if (UselessPageIndex >= 0)  then
  result := UselessPageIndex
 else
  raise Exception.Create('TaaRecordsArray.GetPageToUse - There are no free pages.');

 // if page was used
 if (RecordPage[result].UseCount > 0) then
  begin
   RecordPageNoArr.Delete(RecordPage[result].PageNo);
   bAllPagesAllocated := true;
  end;
 RecordPageNoArr.Insert(NewPageNo, result);
 RecordPage[result].Init(NewPageNo);
end;// TaaRecordsArray.GetPageToUse


//------------------------------------------------------------------------------
// load end page if necessary
//------------------------------------------------------------------------------
procedure TaaRecordsArray.CheckEndPageLoaded;
var
    PageNo: integer;
    RecordNo: integer;
begin
 // if no records was loaded yet
 if (EndPageIndex = -1) then
  begin
    // if loaded table is large enough then - switch to small pages mode
    if (TEasyDataManager(DMHandle).tableHeader.RecordCount > PageCount*PageRecordCount) then
     begin
      bAllPagesAllocated := true;
      CheckResetPages;
     end;
    if (TEasyDataManager(DMHandle).tableHeader.recordCount = 0) then
    PageNo := 0
   else
    begin
     RecordNo := TEasyDataManager(DMHandle).tableHeader.recordCount-1;
     PageNo := GetPageNoByRecNo(RecordNo);
    end;
   EndPageIndex := GetPageToUse(PageNo);
   if (TEasyDataManager(DMHandle).tableHeader.recordCount > 0) then
    RecordPage[EndPageIndex].Read(PageNo);
  end;
end;// TaaRecordsArray.CheckEndPageLoaded;


//------------------------------------------------------------------------------
// get page No by record No
//------------------------------------------------------------------------------
function TaaRecordsArray.GetPageNoByRecNo(RecordNo: integer): integer;
begin
 result := RecordNo div PageRecordCount;
end;// TaaRecordsArray.GetPageNoByRecNo


//------------------------------------------------------------------------------
// Append an element to the end of array
// if pRecordData <> nil - also copies data to appended record
// return pointer to new record's data
//------------------------------------------------------------------------------
function TaaRecordsArray.Append(pRecordData: PAnsiChar=nil): PAnsiChar;
begin
 CheckResetPages;
 // guarantee than end page is loaded
 CheckEndPageLoaded;
 // is end page overflow?
 if (RecordPage[EndPageIndex].RecordCount >= RecordPage[EndPageIndex].MaxRecordCount) then
   // find new page and make it end page
   EndPageIndex := GetPageToUse(RecordPage[EndPageIndex].PageNo+1);
 result := RecordPage[EndPageIndex].AppendRecord(pRecordData);
end;//TaaRecordsArray.Append


//------------------------------------------------------------------------------
// Delete record at specified position and
// move last record's data into position of deleted record
//------------------------------------------------------------------------------
procedure TaaRecordsArray.Delete(RecordNo: integer);
var
    PageNo: integer;
    PageIndex: integer;
begin
 // guarantee than end page is loaded
 CheckEndPageLoaded;

 // move record
 if (RecordNo <> TEasyDataManager(DMHandle).tableHeader.RecordCount) then
  begin
   // get No of page to access
   PageNo := GetPageNoByRecNo(RecordNo);
   // get index of page if loaded
   PageIndex := GetPageIndex(PageNo);
   // if page loaded - copy there
   if (PageIndex <> -1) then
    RecordPage[EndPageIndex].CopyRecords(TEasyDataManager(DMHandle).tableHeader.RecordCount, RecordPage[PageIndex].GetRecordPtr(RecordNo));
  end;
 RecordPage[EndPageIndex].DeleteLastRecord;
 // if empty - then reload
 if (RecordPage[EndPageIndex].RecordCount <= 0) then
  begin
   // previous page No
   PageNo := RecordPage[EndPageIndex].PageNo-1;
   // if it is not the only page
   if (PageNo >= 0) then
    begin
     // delete No
     RecordPageNoArr.Delete(RecordPage[EndPageIndex].PageNo);
     // reset PageNo
     RecordPage[EndPageIndex].Init(-1);
     // get index of previous page if loaded
     PageIndex := GetPageIndex(PageNo);
     if (PageIndex >= 0) then
      EndPageIndex := PageIndex
     else
      begin
       // need to reload
       EndPageIndex := GetPageToUse(PageNo);
       // read page
       RecordPage[EndPageIndex].Read(PageNo);
      end;
    end;
  end;
end;//TaaRecordsArray.Delete


//------------------------------------------------------------------------------
// Return pointer to data of specified record
//------------------------------------------------------------------------------
function TaaRecordsArray.GetRecordDataPtr(RecordNo: integer): PAnsiChar;
var
    PageNo: integer;
    PageIndex: integer;
begin
 // guarantee than end page is loaded
if (EndPageIndex = -1) then
  CheckEndPageLoaded;

 // get No of page to access
 PageNo := RecordNo div PageRecordCount;
 // get index of page if loaded
 if (RecordPageNoArr.ItemCount = 1) and
    (RecordPageNoArr.KeyItems[0] = PageNo) then
   PageIndex := RecordPageNoArr.ValueItems[0]
 else
   PageIndex := GetPageIndex(PageNo);
 // if page not loaded - load it
 if (PageIndex = -1) then
  begin
   PageIndex := GetPageToUse(PageNo);
   // read page
   RecordPage[PageIndex].Read(PageNo);
  end;
 result := RecordPage[PageIndex].GetRecordPtr(RecordNo);
end;//TaaRecordsArray.GetRecordDataPtr


//------------------------------------------------------------------------------
// Lock page with specified record
//------------------------------------------------------------------------------
procedure TaaRecordsArray.LockRecordPage(recordNo: integer);
var
    PageNo: integer;
    PageIndex: integer;
begin
 // to provide that this record loaded
 GetRecordDataPtr(recordNo);
 // get No of page to access
 PageNo := GetPageNoByRecNo(RecordNo);
 // get index of page if loaded
 PageIndex := GetPageIndex(PageNo);
 // if page not loaded - error
 if (PageIndex = -1) then
  raise Exception.Create('TaaRecordsArray.LockRecordPage - Page is already unloaded.');
 inc(RecordPage[PageIndex].LockCount);
end;// TaaRecordsArray.LockRecordPage


//------------------------------------------------------------------------------
// Unlock page with specified record
//------------------------------------------------------------------------------
procedure TaaRecordsArray.UnlockRecordPage(recordNo: integer);
var
    PageNo: integer;
    PageIndex: integer;
begin
 // get No of page to access
 PageNo := GetPageNoByRecNo(RecordNo);
 // get index of page if loaded
 PageIndex := GetPageIndex(PageNo);
 // if page not loaded - error
 if (PageIndex = -1) then
  raise Exception.Create('TaaRecordsArray.UnlockRecordPage - Page is already unloaded.');
 dec(RecordPage[PageIndex].LockCount);
end;// TaaRecordsArray.UnlockRecordPage


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaBuffersArray.Create(size: integer=0);
begin
 AllocBy := 1000; // default alloc
 deAllocBy := 100; // default dealloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 overallSize := 0;
 SetSize(size);
end;//TaaBuffersArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaBuffersArray.Destroy;
var i : integer;
begin
   for i := 0 to ItemCount-1 do
//     FreeMem(items[i],sizes[i]);
    FreeMem(items[i]);
 overallSize := 0;
 Items := nil;
 Sizes := nil;
 inherited Destroy;
end;//TaaBuffersArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaBuffersArray.SetSize(newSize: integer);
var i : integer;
begin
 if (newSize = 0) then
  begin
   for i := 0 to ItemCount-1 do
    FreeMem(items[i]);
   ItemCount := 0;
   allocItemCount := 0;
   AllocBy := 10;
   deAllocBy := 10;
   overallSize := 0;
   Items := nil;
   Sizes := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
     SetLength(Sizes,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     SetLength(Sizes,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TaaBuffersArray.SetSize


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TaaBuffersArray.Append(buffer : pointer; size : Integer;
          copyFlag : Boolean = false);
begin
 SetSize(ItemCount+1);
 if (copyFlag) then
  begin
   items[itemCount-1] := AllocMem(size);
   Move(buffer^,pAnsiChar(items[itemCount-1])^,size);
  end
 else
   items[itemCount-1] := buffer;
 sizes[itemCount-1] := size;
 inc(overallSize,size);
end;//TaaBuffersArray.Append


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TaaBufferLogArray.Create(dFile, bFile : TAbstractFile;
                  blockSize   : Integer;
                  offset  : Integer;
                  size: integer=0);
var memStatus : MEMORYSTATUS;
begin
 dataFile := dFile;
 blobFile := bFile;
 blobBlockSize := blockSize;
 dataOffset := offset;
 AllocBy := 1000; // default alloc
 deAllocBy := 1000; // default dealloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 blobData := TaaBuffersArray.Create;
 MaxItems := 10000;
 GlobalMemoryStatus(memStatus);
//default 1000, 10
// MaxMemAlloc := memstatus.dwAvailPhys div 5; // 10% availbale memory
// MaxTime := 60000;
 MaxMemAlloc := (memstatus.dwAvailPhys div 20) + 1; // 5% availbale memory
 MaxTime := 1000;

// MaxTime := 1000000;
 SetSize(size);
end;//TaaBufferLogArray.Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TaaBufferLogArray.Destroy;
begin
 Items := nil;
 blobData.Free;
 inherited Destroy;
end;//TaaBufferLogArray.Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TaaBufferLogArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   allocBy := 100;
   deAllocBy := 100;
   blobData.SetSize(0);
   Items := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     allocItemCount := newSize;
    end;

 ItemCount := newSize;
end;//TaaBufferLogArray.SetSize


//------------------------------------------------------------------------------
// Insert an element at the endo of the array
//------------------------------------------------------------------------------
procedure TaaBufferLogArray.Append(
                      oper      : TaaRecordOperation;
                      recPtr    : PAnsiChar;
                      recSize   : Integer = -1;
                      recPos    : Integer = -1;
                      moveFlag  : Boolean = true;
                      blobParts: Pointer = nil;
                      numBlobParts: Integer = 0
                      );
begin
//aaStartTime;
 SetSize(ItemCount+1);
 items[itemCount-1].curTime := GetTickCount;
 items[itemCount-1].physRecNo := recPos;
 items[itemCount-1].operation := oper;
 if (oper = roBLOBWrite) then
  begin
   blobData.Append(recPtr,recSize);
   items[itemCount-1].dataIndex := blobData.ItemCount-1;
   items[itemCount-1].blobParts := TaaBLOBPartsArray.Create;
   items[itemCount-1].blobParts.AppendFrom(TaaBlobParts(blobParts),numBlobParts);
  end
 else
  begin
   blobData.Append(recPtr,recSize,true);
   items[itemCount-1].dataIndex := blobData.ItemCount-1;
   items[itemCount-1].blobParts := nil;
  end;
//aaStopTime;
end;//TaaBufferLogArray.Append


//------------------------------------------------------------------------------
// checks for overflow
//------------------------------------------------------------------------------
function TaaBufferLogArray.CheckOverflow : Boolean;
var ticks : Cardinal;
begin
// check for overflowing
ticks := GetTickCount;

 result := false;
 if (itemCount <= 0) then Exit;
//aaStartTime;
 if (blobData.overallSize >= MaxMemAlloc)
    or
    (itemCount >= MaxItems)
   or
   (ticks - items[0].curTime > MaxTime)
     then
      begin
       result := true;
       FlushBuffers;
      end;
//aaStopTime;

end;

//------------------------------------------------------------------------------
// returns true if record exists in buffer (recordNo - physical)
//------------------------------------------------------------------------------
function TaaBufferLogArray.IsRecordInBuffer (recordNo : Integer; var pRecBuf: PAnsiChar): Boolean;
var i : Integer;
begin
 Result := false;
 pRecBuf := nil;
 if (ItemCount <= 0) then
  Exit;
 for i:= ItemCount-1 downto 0 do
  if (items[i].operation = roMove) and (items[i].physRecNo = recordNo) then
   begin
    pRecBuf := pAnsiChar(blobData.items[items[i].dataIndex]);
    result := true;
    break;
   end;
end; //IsRecordInBuffer


//------------------------------------------------------------------------------
// checks for overflow
//------------------------------------------------------------------------------
procedure TaaBufferLogArray.FlushBuffers;
var i,n,j,bn,bc,offset,xx : integer;
    buf : PAnsiChar;
begin
// save all data
 if (itemCount <= 0) then Exit;

//aaStartTime;
 for i := 0 to itemCount-1 do
  begin
   if (items[i].operation = roBLOBWrite) then
    begin
     buf := pAnsiChar(blobData.items[items[i].dataIndex]);
     n := items[i].blobParts.itemCount;
     offset := 0;
     for j := 0 to n-1 do
      begin
       bn := items[i].blobParts.items[j].blockNumber * blobBlockSize;
       bc := items[i].blobParts.items[j].blockCount * blobBlockSize;
       blobFile.Seek(bn, soFromBeginning);
       xx := blobFile.Write((buf+offset)^,bc);
       if (xx <> bc) then
         raise Exception.Create('TaaBufferLogArray.FlushBuffers - error writing data to blob file'+
         ', xx = '+IntToStr(xx)+
         ', bc = '+IntToStr(bc)
         );
       inc(offset,bc);
      end;
     items[i].blobParts.Free;
    end //blob
   else
    begin
     buf := pAnsiChar(blobData.items[items[i].dataIndex]);
     n := blobData.sizes[items[i].dataIndex];
     offset := dataOffset + items[i].physRecNo * n;
     if (dataFile.Position <> offset) then
      dataFile.Seek(offset,soFromBeginning);
     dataFile.Write(buf^,n);
    end; // not blob
  end;
// aaStartTime;
 SetSize(0);
//aaStopTime;
end; //FlushBuffers




end.
