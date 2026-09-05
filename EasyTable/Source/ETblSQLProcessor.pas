{$I ETblVer.inc}

unit ETblSQLProcessor;

interface

uses classes, windows, sysutils, db,
     ETblConst, ETblExcept, ETblLexer, ETblSQLCommand, ETblRelationalAlgebra;

type
 // parsing of SQL script
 TSQLScriptProcessor = class(TObject)
  private
   FLex:                TEasyLexer; // lexer
   FParams:             TParams;
   Queries:             array of TEasySQLCommand; // objects fullfilled by parser
   QueryCount:          integer; // count of queries

   // parse SQL script and fullfill SQL command objects
   procedure Parse;
   // adds SELECT query object
   procedure AddSelectQuery;
   // adds INSERT query object
   procedure AddInsertQuery;
   // adds UPDATE query object
   procedure AddUpdateQuery;
   // adds DELETE query object
   procedure AddDeleteQuery;
   // DDL
   procedure AddCreateTableQuery;
   procedure AddDropTableQuery;
   procedure AddAlterTableQuery;
   procedure AddCreateIndex;
   procedure AddDropIndexQuery;
  public
   constructor Create(SQLScript: AnsiString; Params: TParams);
   destructor Destroy; override;
   // executes queries
   procedure ExecSQL(query: TDataset);
   // gets result dataset
   function GetResultDataset: TDataset;
   // gets result AO
   function GetResultAO: TEasyAO;
 end;

implementation

////////////////////////////////////////////////////////////////////////////////
//
// TSQLScriptProcessor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Creates
//------------------------------------------------------------------------------
constructor TSQLScriptProcessor.Create(SQLScript: AnsiString; Params: TParams);
begin
 QueryCount := 0;
 SetLength(queries, 0);
 FParams := Params;
 FLex := TEasyLexer.Create(SQLScript, FParams);
 Parse;
end;// Create


//------------------------------------------------------------------------------
// Destroys
//------------------------------------------------------------------------------
destructor TSQLScriptProcessor.Destroy;
var
  i: integer;
begin
 if (FLex <> nil) then
  FLex.Free;
  for i := 0 to QueryCount-1 do
   if (Queries[i] <> nil) then
     begin
      Queries[i].Free;
      Queries[i] := nil;
     end;
end;// Destroy


//------------------------------------------------------------------------------
// execute queries
//------------------------------------------------------------------------------
procedure TSQLScriptProcessor.ExecSQL(query: TDataset);
var
  i: integer;
begin
  for i := 0 to QueryCount-1 do
   begin
    Queries[i].ExecSQL(query, True);
    if (i <> QueryCount-1) then
     begin
      Queries[i].Free;
      Queries[i] := nil;
     end;
   end; 
end;// ExecSQL 
	
 
//------------------------------------------------------------------------------
// gets result dataset
//------------------------------------------------------------------------------ 
function TSQLScriptProcessor.GetResultDataset: TDataset;
begin 
  Result := Queries[QueryCount-1].GetResultDataset;
end;// GetResultDataset 
	
 
//------------------------------------------------------------------------------ 
// gets result AO 
//------------------------------------------------------------------------------
function TSQLScriptProcessor.GetResultAO: TEasyAO;
begin
  if (Queries[QueryCount-1] is TEasySQLCursorCommand) then 
   Result := TEasySQLCursorCommand(Queries[QueryCount-1]).GetResultAO 
  else 
   raise ETblException.Create(01068, nil);
end;// GetResultAO 
	
	
//------------------------------------------------------------------------------ 
// Parse SQL script and call to parse SQL command objects
//------------------------------------------------------------------------------ 
procedure TSQLScriptProcessor.Parse;
var 
  Token: TToken; 
begin
 if (FLex.NumCommands = 0) then 
  raise ETblException.Create(01001);
 
 while FLex.GetNextCommand do
  begin
   // look at first token 
   if (not FLex.GetCurrentToken(Token)) then
    raise ETblException.Create(01002);
	
   if (Token.TokenType = tktReservedWord) then
     case Token.ReservedWord of
     rwSELECT:  // SELECT 
                AddSelectQuery;
     rwINSERT:  // INSERT
                AddInsertQuery;
     rwUPDATE:  // UPDATE
                AddUpdateQuery; 
     rwDELETE:  // DELETE
                AddDeleteQuery; 
     rwCREATE:  // CREATE
                begin
                  if FLex.GetNextToken(Token) then
                    case Token.ReservedWord of
                      rwTABLE:  // CREATE TABLE 
                                AddCreateTableQuery;
                      rwINDEX, 
                      rwUNIQUE: // CREATE INDEX or UNIQUE INDEX 
                                AddCreateIndex;
                      else raise ETblException.Create(02002, 
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil); 
                    end
                  else raise ETblException.Create(02001, [Token.LineNum], nil);
                end;
      rwDROP:   // DROP 
                begin
                  if FLex.GetNextToken(Token) then 
                    case Token.ReservedWord of 
                      rwTABLE:  // DROP TABLE
                                AddDropTableQuery; 
                      rwINDEX:  // DROP INDEX
                                AddDropIndexQuery; 
                      else raise ETblException.Create(02035, 
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil); 
                    end 
                  else raise ETblException.Create(02036, [Token.LineNum], nil);
                end;
      rwALTER:   // ALTER 
                begin
                  if FLex.GetNextToken(Token) then 
                    case Token.ReservedWord of
                      rwTable:  // ALTER TABLE 
                                AddAlterTableQuery; 
                      else raise ETblException.Create(02035,
                             [Token.Text, Token.LineNum, Token.ColumnNum], nil);
                    end
                  else raise ETblException.Create(02036, [Token.LineNum], nil); 
                end;
	
     else       // unsupported SQL or unexpected token 
        raise ETblException.Create(01003, 
                         [Token.Text, Token.LineNum, Token.ColumnNum], nil); 
     end
   else
    // '( SELECT ...) ' ?
    if (Token.TokenType = tktLeftParenthesis) then
     AddSelectQuery 
    else
     raise ETblException.Create(01059, 
                         [Token.Text, Token.LineNum, Token.ColumnNum], nil); 
  end; 
end;// Parse
 
 
//------------------------------------------------------------------------------
// adds select query object 
//------------------------------------------------------------------------------
procedure TSQLScriptProcessor.AddSelectQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount); 
 Queries[QueryCount-1] := TEasySQLUnion.Create(FLex); 
 // union | intersect | except? 
 if (FLex.GetCurrentToken(Token)) then 
  // unexpected token
  raise ETblException.Create(01006,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;// AddSelectQuery 
 
procedure TSQLScriptProcessor.AddDeleteQuery; 
var 
  Token: TToken;
begin 
 inc(QueryCount);
 SetLength(Queries, QueryCount); 
 Queries[QueryCount-1] := TEasySQLDelete.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02067,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TSQLScriptProcessor.AddInsertQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasySQLInsert.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02068,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TSQLScriptProcessor.AddUpdateQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasySQLUpdate.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02069,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;


procedure TSQLScriptProcessor.AddCreateTableQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasyDDLCreateTable.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02003,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);

end;// AddCreateTableQuery

procedure TSQLScriptProcessor.AddDropTableQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasyDDLDropTable.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02034,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TSQLScriptProcessor.AddAlterTableQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasyDDLAlterTable.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02043,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TSQLScriptProcessor.AddCreateIndex;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasyDDLCreateIndex.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02049,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

procedure TSQLScriptProcessor.AddDropIndexQuery;
var
  Token: TToken;
begin
 inc(QueryCount);
 SetLength(Queries, QueryCount);
 Queries[QueryCount-1] := TEasyDDLDropIndex.Create(FLex);
 if (FLex.GetNextToken(Token)) then
  // unexpected token
  raise ETblException.Create(02062,
                  [Token.Text, Token.LineNum, Token.ColumnNum], nil);
end;

end.
