unit MsgDatabaseTempTableSQLMemTable;

interface


{$I MsgDBVer.inc}
{DEFINE DEBUG_DB_ACR}

uses

 Classes,SysUtils,

Db,
MsgDatabase,
SQLMemMain,
SQLMemLocalEngine,

{$IFDEF DEBUG_LOG}
MsgDebug,
{$ENDIF}

MsgCompression,
MsgExcept,
MsgComBase,
MsgConst,
MsgTypes
;


type

////////////////////////////////////////////////////////////////////////////////
//
// TMsgTempTableSQLMemTable
//
////////////////////////////////////////////////////////////////////////////////


 TMsgTempTableSQLMemTable = class (TMsgTempTable)
  private
   FCompressionAlgorithm: TCompressionAlgorithm;
   FCompressionMode:      Byte;
   FBlockSize:            Integer;
  public
   constructor Create(AOwner: TComponent); override;
   procedure SaveDatasetToStream(Dataset: TDataset; Stream: TStream); override;
   procedure LoadDatasetFromStream(var Dataset: TDataset; Stream: TStream); override;
  published
   property CompressionAlgorithm: TCompressionAlgorithm read FCompressionAlgorithm write FCompressionAlgorithm;
   property CompressionMode: Byte read FCompressionMode write FCompressionMode;
   property BlockSize: Integer read FBlockSize write FBlockSize;
 end; // TMsgTempTable



implementation


////////////////////////////////////////////////////////////////////////////////
//
// TMsgTempTableSQLMemTable
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgTempTableSQLMemTable.Create(AOwner: TComponent);
begin
  inherited;
  FCompressionAlgorithm := caNone;
  FCompressionMode := 0;
  FBlockSize := DefaultMemoryBlockSize;
end; // Create;


//------------------------------------------------------------------------------
// SaveDatasetToStream
//------------------------------------------------------------------------------
procedure TMsgTempTableSQLMemTable.SaveDatasetToStream(Dataset: TDataset; Stream: TStream);
var table: TSQLMemTable;
    s:     AnsiString;
begin
  table := TSQLMemTable.Create(nil);
  try
    s := '';
    table.ImportTable(Dataset,s);
    if (s <> '') then
     raise EMsgException.Create(11583,ErrorLErrorImportingDataset,[s]);
    try
      table.SaveTableToStream(Stream,FCompressionAlgorithm,FCompressionMode,FBlockSize);
    finally
      table.DeleteTable(True);
    end;
  finally
    table.Free;
  end;
end; // SaveDatasetToStream


//------------------------------------------------------------------------------
// LoadDatasetFromStream
//------------------------------------------------------------------------------
procedure TMsgTempTableSQLMemTable.LoadDatasetFromStream(var Dataset: TDataset; Stream: TStream);
var table: TSQLMemTable;
begin
  Dataset := nil;
  table := TSQLMemTable.Create(nil);
  Dataset := table;
  table.LoadTableFromStream(Stream);
  table.Open;
end; // LoadDatasetFromStream


end.

