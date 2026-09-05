unit SQLMemLexer;

{$I SQLMemVer.inc}

interface

uses Classes, SysUtils, DB,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF DEBUG_LOG}
     SQLMemDebug,
{$ENDIF}
{$IFNDEF D6H}
     SQLMemD4Routines,
{$ENDIF}
     SQLMemVariant,
     SQLMemCompression,
     SQLMemConverts,
     SQLMemExcept,
     SQLMemTypes,
     SQLMemConst;

const
ESQLMemTokenType: array [0..13] of WideString =
(
 'tktNone', 'tktString', 'tktQuotedString', 'tktBracketedString',
 'tktInt', 'tktFloat', 'tktReservedWord',
 'tktParameter', 'tktLeftParenthesis', 'tktRightParenthesis',
 'tktComma', 'tktDot', 'tktBackQuotedString', 'tktAssign'
);

type
 TTokenType = (tktNone, tktString, tktQuotedString, tktBracketedString,
 tktInt, tktFloat, tktReservedWord,
 tktParameter, tktLeftParenthesis, tktRightParenthesis,
 tktComma, tktDot, tktBackQuotedString, tktAssign);

 TTokenTypes = set of TTokenType;

 TToken = packed record
  TokenType:      TTokenType;
  Parameter:      Byte;
  ReservedWord:   TReservedWord;
//  Text:           AnsiString;
  Text:           WideString;
  ParamValue:     TSQLMemVariant;
  LineNum:        Integer; // number of line in script where token begins
  ColumnNum:      Integer; // number of column in script where token begins
 end;

 PToken = ^TToken;

 TSQLCommand = record
  Tokens:           array of TToken;
  NumTokens:        Integer;
  CurrentTokenNo:   Integer;
 end;


 TSQLMemLexer = class (TObject)
  private
   FSQL:              WideString;
   FSQLParams:        TSQLMemSQLParams;
   FSQLScriptLength:  Integer;
   FCurrentPos:       Integer;
   FCurrentCommandNo: Integer;
   FCurrentCommand:   TSQLCommand;
   FSaveScript:       Boolean;
   FSaveScriptStart:  Integer; // numer of first symbol in last saved script
   line,token,column: Integer;
  private
   procedure FreeCurrentCommand;
   function Parse: Boolean;
  public
   constructor Create(SQLScript: WideString; SQLParams: TSQLMemSQLParams = nil);
   destructor Destroy; override;
   // makes next command current
   function GetNextCommand: Boolean;
   // gets next token in current command
   function GetNextToken(var Token: TToken): Boolean;
   // gets current token in current command
   function GetCurrentToken(var Token: TToken): Boolean;
   // looks at next token
   function LookNextToken(var Token: TToken): Boolean;
   // gets current token No
   function GetCurrentTokenNo: integer;
   // sets current token No
   function SetCurrentTokenNo(TokenNo: integer; var Token: TToken): Boolean;
   // sets new number of tokens in current command, CurrentTokenNo := 0
   // for compatibility with Delphi 2010
   procedure SetNumTokensInCurrentCommand(NewNumTokens: Integer);
   // starts save SQL script: all GetNextToken,GetNextToken will add all token's texts to SavedScript
   procedure StartSaveScript;
   // stops save SQL script and return the saved script
   function StopSaveScript(GetResult: Boolean): WideString;
   function SQLMemIsBoooleanOperator: Boolean;
  public
   property CurrentCommand: TSQLCommand read FCurrentCommand write FCurrentCommand;
   property SaveScript: Boolean read FSaveScript;
 end;

 // checks whether token is reserved word
 function IsReservedWord(Token: TToken; ReservedWord: TReservedWord=rwNone): Boolean;
 function StrToHexValue(const Text: WideString): Int64;
 function GetFixedParamsInQuery(const SQLText: WideString): WideString;
 function IsEmptyString(Token: TToken): Boolean;
 function IsStringToken(const token: TToken): Boolean;
 function IsQuotedStringToken(const token: TToken): Boolean;
 function SQLMemIsDelimiter(c: WideChar): Boolean;
 // Token -> SQL script
 function SQLMemGetTokenText(const Token: TToken): WideString;
 // return true if the token is the operator token
 function SQLMemIsOperatorSign(const token: TToken; const operatorName: WideString): Boolean;


implementation




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemLexer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// free current command
//------------------------------------------------------------------------------
procedure TSQLMemLexer.FreeCurrentCommand;
var j: Integer;
begin
  for j := 0 to FCurrentCommand.NumTokens-1 do
   begin
     if (FCurrentCommand.Tokens[j].ParamValue <> nil) then
       FCurrentCommand.Tokens[j].ParamValue.Free;
     SQLMemClearString(FCurrentCommand.Tokens[j].Text);
   end;
end; // FreeCurrentCommand


//------------------------------------------------------------------------------
// Parse SQL script
//------------------------------------------------------------------------------
function TSQLMemLexer.Parse: Boolean;
var i,l:                    Integer;
    c,priorSymbol,
    commentSymbol:          WideChar;
    numParenthesis,
    LeftParenthesisLine,
    LeftParenthesisColumn,
    RightParenthesisLine,
    RightParenthesisColumn,
    quoteLine,quoteColumn:  Integer;
    bIsDelimiter:           Boolean;
    bTokenStarted:          Boolean;
    bCommandStarted:        Boolean;
    bNewTokenStarted:       Boolean;
    bTokenFinished:         Boolean;
    bQuoteNotClosed:        Boolean;
    bHexConstStarted:       Boolean;
    FNewCommandStarted:     Boolean;

  function GetNextSymbol: WideChar;
  begin
   result := ' ';
    if (i < l-1) then
     result := pWideChar(pWideChar(FSQL)+i+1)^;
  end;


 function IsNewTokenStarted: Boolean;
 begin
  result := false;
  if (bTokenStarted) then
   begin
      if (c = '>') or (c = '<') or (c = '=') or (c = '(') or (c = ')') or
         (c = ',') or (c = '/') or (c = '*') or (c = Colon) or (c = '|') or
         ((c=Dot) and (FCurrentCommand.Tokens[token].TokenType<>tktInt)) then
           result := true
      else
      if (FCurrentCommand.Tokens[token].TokenType = tktDot) then
       begin
         if not ((c >= '0') and (c <= '9')) then
          result := true;
       end
      else
      if (FCurrentCommand.Tokens[token].TokenType = tktString) then
       begin
        if (c = '+') or (c = '-') then
         result := true;
       end
      else
      if (FCurrentCommand.Tokens[token].TokenType = tktInt) then
       begin
        if (c = '+') and (WideUpperCase(priorSymbol) <> 'E') then
         result := true
        else
        if (c = '-') and (WideUpperCase(priorSymbol) <> 'E') then
         result := true;
       end; // Int or Float token
   end // some token already started
  else
   begin
    if (not bIsDelimiter) then
     result := true;
   end; // no token started
 end; // IsNewTokenStarted

 function IsTokenFinished: Boolean;
 begin
  result := false;
  if (bTokenStarted) then
   begin
    if (bIsDelimiter) then
     begin
       result := true;
     end;
   end;
 end; // IsTokenFinished

 function FindReservedWord: Integer;
 var i,crc: Cardinal;
 begin
  Result := -1;
  crc := GetTableNameCRC(FCurrentCommand.Tokens[token].Text,True);
  for i := 0 to SQLMemMaxSQLReservedWords do
   if (crc = SQLMemSQLReservedWordsCRC[i]) then
     begin
      Result := i;
      break;
     end;
 end; // FindReservedWord

 procedure CreateCommand;
 begin
  FNewCommandStarted := True;
  FCurrentCommand.NumTokens := 0;
  FCurrentCommand.Tokens := nil;
  token := 0;
  bCommandStarted := true;
  numParenthesis := 0;
 end; // CreateCommand;

 procedure CloseToken;
 var i:         Integer;
     Param:     TSQLMemSQLParam;
     ParamName: WideString;
//     oldSeparator: AnsiChar;
 begin
  if (not bTokenStarted) then
   Exit;
  // check int or float
  if (FCurrentCommand.Tokens[token].TokenType = tktInt) then
   begin
    // check int or float
    if (Pos('.',FCurrentCommand.Tokens[token].Text) > 0) then
     FCurrentCommand.Tokens[token].TokenType := tktFloat
    else
    if (Pos('E',WideUpperCase(FCurrentCommand.Tokens[token].Text)) > 0) then
     FCurrentCommand.Tokens[token].TokenType := tktFloat;
    if (bHexConstStarted) then
     FCurrentCommand.Tokens[token].Text :=
      IntToStr(StrToHexValue(FCurrentCommand.Tokens[token].Text));
   end;
  // parameter
  if (FCurrentCommand.Tokens[token].Parameter > 0) then
   if ((FCurrentCommand.Tokens[token].TokenType = tktString) or
      (FCurrentCommand.Tokens[token].TokenType = tktQuotedString) or
      (FCurrentCommand.Tokens[token].TokenType = tktBackQuotedString)
//     or (FCurrentCommand.Tokens[token].TokenType = tktBracketedString)
       ) then
     begin
        // param name without ':'
        ParamName := Copy(FCurrentCommand.Tokens[token].Text, 2,
                         Length(FCurrentCommand.Tokens[token].Text)-1);
        FCurrentCommand.Tokens[token].Text := ParamName;
        FCurrentCommand.Tokens[token].TokenType := tktParameter;

        // try to set param value
        if (FSQLParams <> nil) then
         begin
          Param := FSQLParams.GetParamByName(ParamName);
          if (Param <> nil) then
            begin
              FCurrentCommand.Tokens[token].ParamValue := TSQLMemVariant.Create;
              FCurrentCommand.Tokens[token].ParamValue.Assign(Param);
            end
          else
// commneted in v.5.10 as stored procedures can have :DataType tokens, not parameter
//            raise ESQLMemException.Create(30358, ErrorGParameterValueNotFound, [ParamName]);
            begin
              // create null parameter
              FCurrentCommand.Tokens[token].ParamValue := TSQLMemVariant.Create;
            end;
         end;
     end; // parameter

  if (FCurrentCommand.Tokens[token].TokenType = tktString) then
   begin
      // check for reserved word
      i := FindReservedWord;
      if (i > 0) then
       begin
        FCurrentCommand.Tokens[token].ReservedWord := TReservedWord(i);
        FCurrentCommand.Tokens[token].TokenType := tktReservedWord;
       end;
   end;// if WideString
  bTokenStarted := false;
 end; // CloseToken;

 procedure CreateToken;
 var NextSymbol: WideChar;
     quoteSymbol: WideChar;
     bColon: Boolean;
 begin
  if (not bCommandStarted) then
   CreateCommand;
// commented in 4.95 - bug in line numbering
//  line := FCurrentLine;
  bTokenStarted := true;
  bHexConstStarted := false;
  inc(FCurrentCommand.NumTokens);
  SetLength(FCurrentCommand.Tokens,FCurrentCommand.NumTokens);
  FCurrentCommand.Tokens[FCurrentCommand.NumTokens-1].ParamValue := nil;

  token := FCurrentCommand.NumTokens - 1;
  FCurrentCommand.Tokens[token].Text := c;
  FCurrentCommand.Tokens[token].ColumnNum := column;
  FCurrentCommand.Tokens[token].LineNum := line;
  FCurrentCommand.Tokens[token].ReservedWord := rwNone;
  FCurrentCommand.Tokens[token].ParamValue := nil;
  FCurrentCommand.Tokens[token].TokenType := tktNone;
  bColon := (c = Colon);
  if (bColon) then
   begin
    // skip delimiters after :
    while (i < (l-1)) do
     begin
      Inc(i);
      c := pWideChar(pWideChar(FSQL)+i)^;
      bIsDelimiter := SQLMemIsDelimiter(c);
      if (not bIsDelimiter) then
       begin
        FCurrentCommand.Tokens[token].Text := WideString(Colon)+c;
        break;
       end;
     end;
    // added in v.5.10 - tktAssign :=
    if (c = '=') then
     begin
      FCurrentCommand.Tokens[token].TokenType := tktAssign;
      FCurrentCommand.Tokens[token].Parameter := 0;
     end
    else
    if (not bIsDelimiter) then
     begin
       FCurrentCommand.Tokens[token].TokenType := tktString;
       FCurrentCommand.Tokens[token].Parameter := 1;
     end;
   end
  else
   FCurrentCommand.Tokens[token].Parameter := 0;
  // here will be quoted / bracketed WideString to its end
  if (c = SingleQuote) or (c = BackQuote) or (c = DoubleQuote) or (c = LeftBracket) then
   begin
    if (not bColon) then
     FCurrentCommand.Tokens[token].Text := ''
    else
     FCurrentCommand.Tokens[token].Text := ':';

    if (c = BackQuote) then
     FCurrentCommand.Tokens[token].TokenType := tktBackQuotedString
    else
    if (c = SingleQuote) or (c = DoubleQuote) then
     FCurrentCommand.Tokens[token].TokenType := tktQuotedString
    else
    if (c = LeftBracket) then
     FCurrentCommand.Tokens[token].TokenType := tktBracketedString;
    if (c <> LeftBracket) then
     quoteSymbol := c
    else
     quoteSymbol := RightBracket;
    quoteLine := line;
    quoteColumn := column;
    bQuoteNotClosed := true;
    inc(i);
    while (i < l) do
     begin
      c := pWideChar(pWideChar(FSQL)+i)^;
      NextSymbol := GetNextSymbol;
      if (c = quoteSymbol) then
       begin
        if (NextSymbol = c) then
         begin
          FCurrentCommand.Tokens[token].Text :=
            FCurrentCommand.Tokens[token].Text + c;
          inc(i,2);
          inc(column,2);
          continue;
         end // ''
        else
         begin
          // end of QuotedStr
          bQuoteNotClosed := false;
          break;
         end; // '
       end; // quote symbol

      FCurrentCommand.Tokens[token].Text :=
         FCurrentCommand.Tokens[token].Text + c;
      if (c = lf) then
       begin
        inc(line);
        column := 1;
       end
      else
       if (c <> cr) then
        inc(column);
      inc(i);
     end; // while
    CloseToken;
   end   // here will be scanning quoted /bracketed WideString to its end
  else
  if (c = '$') then
   begin
    // hex constant , like $ff
    FCurrentCommand.Tokens[token].TokenType := tktInt;
    bHexConstStarted := true;
    FCurrentCommand.Tokens[token].Text := '';
   end
  else
  if (c = '!') then
   begin
    FCurrentCommand.Tokens[token].TokenType := tktString;
    if (GetNextSymbol = '=') then
     begin
      // !=
      FCurrentCommand.Tokens[token].Text := '!=';
     end
    else
     begin
      // !
      FCurrentCommand.Tokens[token].Text := '!';
     end;
    CloseToken;
   end
  else
  if (c = '~') then
   begin
    FCurrentCommand.Tokens[token].TokenType := tktString;
    FCurrentCommand.Tokens[token].Text := '~';
    CloseToken;
   end
  else
  if (c = LeftParenthesis) then
   begin
    FCurrentCommand.Tokens[token].TokenType := tktLeftParenthesis;
    CloseToken;
    inc(numParenthesis);
    LeftParenthesisLine := line;
    LeftParenthesisColumn := column;
   end
  else
  if (c = RightParenthesis) then
   begin
    dec(numParenthesis);
    RightParenthesisLine := line;
    RightParenthesisColumn := column;
    FCurrentCommand.Tokens[token].TokenType := tktRightParenthesis;
    CloseToken;
   end
  else
  if (c = Dot) then //!!
   begin
    FCurrentCommand.Tokens[token].TokenType := tktDot;
    //CloseToken;
   end
  else
  if (c = Comma) then
   begin
    FCurrentCommand.Tokens[token].TokenType := tktComma;
    CloseToken;
   end
  else
  if ((c >= '0') and (c <= '9')) then
    FCurrentCommand.Tokens[token].TokenType := tktInt
  else
  if (FCurrentCommand.Tokens[token].TokenType = tktNone) then
   FCurrentCommand.Tokens[token].TokenType := tktString;
  if (c = '-') or (c = '+') or (c = '*') or (c = '/') or (c = '=') then
   CloseToken;
  if (c = '|') then
   begin
    NextSymbol := GetNextSymbol;
    if (NextSymbol = '|') then
     begin
      FCurrentCommand.Tokens[token].Text :=
        FCurrentCommand.Tokens[token].Text + NextSymbol;
      inc(i);
      inc(column);
     end;
    CloseToken;
   end; // <
  if (c = '<') then
   begin
    NextSymbol := GetNextSymbol;
    if (NextSymbol = '=') or (NextSymbol = '>') then
     begin
      FCurrentCommand.Tokens[token].Text :=
        FCurrentCommand.Tokens[token].Text + NextSymbol;
      inc(i);
      inc(column);
     end;
    CloseToken;
   end; // <
  if (c = '>') then
   begin
    NextSymbol := GetNextSymbol;
    if (NextSymbol = '=') then
     begin
      FCurrentCommand.Tokens[token].Text :=
        FCurrentCommand.Tokens[token].Text + NextSymbol;
      inc(i);
      inc(column);
     end;
    CloseToken;
   end; // >
 end; // CreateToken;

 procedure CloseCommand;
 begin
  CloseToken;

  bCommandStarted := false;

  if (numParenthesis > 0) then
    raise ESQLMemException.Create(30059, ErrorGMissingRightParenthesis,
                                  [LeftParenthesisLine,LeftParenthesisColumn]);

  if (numParenthesis < 0) then
    raise ESQLMemException.Create(30060, ErrorGUnexpectedRightParenthesis,
                                  [LeftParenthesisLine,LeftParenthesisColumn]);
  priorSymbol := ' ';

  if (bQuoteNotClosed) then
    raise ESQLMemException.Create(30061, ErrorGUnterminatedString,
                                                       [quoteLine,quoteColumn]);
 end; // CloseCommand;

 var NextSymbol: WideChar;
begin
 FNewCommandStarted := False;
 l := FSQLScriptLength;
 column := 1;
 bTokenStarted := false;
 bQuoteNotClosed := false;
 bCommandStarted := false;
 token := 0;
 priorSymbol := ' ';
 numParenthesis := 0;
 LeftParenthesisLine := 0;
 LeftParenthesisColumn := 0;
 RightParenthesisLine := 0;
 RightParenthesisColumn := 0;
 i := FCurrentPos;
 while (i < l) do
  begin
   // get current character
   c := pWideChar(pWideChar(FSQL)+i)^;

   // end of the current comand
   if (c = SemiColon) then
    begin
     // modified in v.5.10
     if (numParenthesis > 0) then
      begin
       Inc(i);
       continue;
      end
     else
      begin
       CloseCommand;
       inc(i);
       break;
      end;
    end;

   // check for comment --
   if (c = '-') then
    begin
     NextSymbol := GetNextSymbol;
     if (NextSymbol = '-') then
      begin
       // seek for end of line
       inc(i);
       column := 1;
       inc(line);
       while (i < l) do
        begin
         c := pWideChar(pWideChar(FSQL)+i)^;
         if (c = lf) then
           break;
         inc(i);
        end;
       inc(i);
       continue;
      end;
    end; // comment --

   // check for comment /* */ or //
   if (c = '/') then
    begin
     NextSymbol := GetNextSymbol;
     if (NextSymbol = '/') then
      begin
       // seek for end of line
       inc(i);
       column := 1;
       inc(line);
       while (i < l) do
        begin
         c := pWideChar(pWideChar(FSQL)+i)^;
         if (c = lf) then
           break;
         inc(i);
        end;
       inc(i);
       continue;
      end // comment // ... <crlf>
     else
     if (NextSymbol = '*') then
      begin
       // commentary started
       inc(i,2);
       inc(column,2);
       while (i < l) do
        begin
          c := pWideChar(pWideChar(FSQL)+i)^;
          if (c = '*') then
           begin
             NextSymbol := GetNextSymbol;
             if (NextSymbol = '/') then
              begin
               inc(i,2);
               inc(column,2);
               break;
              end;
           end;
          if (c = lf) then
           begin
            inc(line);
            column := 1;
           end
          else
           if (c <> cr) then
            inc(column);
          inc(i);
        end; // while
       continue;
      end; // comment /* */ started
    end;


   // is this symbol a delimiter?
   bIsDelimiter := SQLMemIsDelimiter(c);

   // moved in 4.97 to avoid problem with delimeter starting new token

   bTokenFinished := IsTokenFinished;
//   bNewTokenStarted := IsNewTokenStarted;
   if (bTokenFinished) then
    CloseToken;
   bNewTokenStarted := IsNewTokenStarted;
   if (bTokenStarted and bNewTokenStarted) then
    CloseToken;
   if (bNewTokenStarted) then
    CreateToken;

   // add current symbol to token
   if (not bNewTokenStarted) and (bTokenStarted) and (not bIsDelimiter) then
    begin
     // check for number
     if FCurrentCommand.Tokens[token].TokenType in [tktInt,tktFloat] then
      if not ((c >= '0') and (c <= '9') or (c = Dot) or
              (WideUpperCase(c)='A') or (WideUpperCase(c)='B') or (WideUpperCase(c)='C') or
              (WideUpperCase(c)='D') or (WideUpperCase(c)='E') or (WideUpperCase(c)='F') or
              (c = '+') or (c = '-') or (c = 'x')) then
        raise ESQLMemException.Create(30062, ErrorGInvalidNumericSymbol,
                                                              [c,line,column]);
      // check float type .22
      if (FCurrentCommand.Tokens[token].TokenType = tktDot) and
         (c >= '0') and (c <= '9') then
       begin
        FCurrentCommand.Tokens[token].TokenType := tktInt;
       end;
     // add current symbol to token
     if ((c = 'x') and (FCurrentCommand.Tokens[token].TokenType = tktInt)) then
      begin
       FCurrentCommand.Tokens[token].Text := '';
       bHexConstStarted := true;
      end
     else
      FCurrentCommand.Tokens[token].Text :=
        FCurrentCommand.Tokens[token].Text + c;
    end; // // add current symbol to token

     // <<, >>, ||, &&, ==
    if (bNewTokenStarted) then
     if (((c = '<') or (c = '>') or (c = '&') or (c = '|') or (c = '=')) and (GetNextSymbol = c)) then
      begin
       FCurrentCommand.Tokens[token].Text :=
        FCurrentCommand.Tokens[token].Text + c;
       Inc(i);
      end;

   if (c = lf) then
    begin
     inc(line);
     column := 1;
    end
   else
    if (c <> cr) then
     inc(column);
   // skip delimiters
   if (bIsDelimiter) then
    begin
     if (bTokenStarted) then
      CloseToken;
    end;
   // next symbol
   priorSymbol := c;
   inc(i);
  end; // for all symbols in FSQL
 FCurrentPos := i;
 CloseCommand;
 Result := FNewCommandStarted;
end; // Parse


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TSQLMemLexer.Create(SQLScript: WideString; SQLParams: TSQLMemSQLParams);
begin
  line := 1;
  FSQL := SQLScript;
  FSQLParams := SQLParams;
  FCurrentPos := 0;
// commented in 4.95 - not used
//  FCurrentLine := 0;
  FCurrentCommandNo := -1;
  FSQLScriptLength := Length(FSQL);
  FSaveScript := False;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemLexer.Destroy;
begin
  SQLMemClearString(FSQL);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// makes next command current
//------------------------------------------------------------------------------
function TSQLMemLexer.GetNextCommand: Boolean;
begin
 if (FCurrentCommandNo >= 0) then
  FreeCurrentCommand;
 Inc(FCurrentCommandNo);
// commented in 4.95 - not used
// Inc(FCurrentLine);
 Result := Parse;
 FCurrentCommand.CurrentTokenNo := 0;
end;// GetNextCommand


//------------------------------------------------------------------------------
// gets next token in current command
//------------------------------------------------------------------------------
function TSQLMemLexer.GetNextToken(var Token: TToken): Boolean;
begin
  Result := LookNextToken(Token);
  Inc(FCurrentCommand.CurrentTokenNo);
end;// GetNextToken


//------------------------------------------------------------------------------
// gets current token in current command
//------------------------------------------------------------------------------
function TSQLMemLexer.GetCurrentToken(var Token: TToken): Boolean;
begin
   Result := (FCurrentCommand.CurrentTokenNo < FCurrentCommand.NumTokens);
   if (Result) then
    begin
     Token := FCurrentCommand.Tokens[FCurrentCommand.CurrentTokenNo];
    end
   else
    Token.TokenType := tktNone;
end;// GetCurrentToken


//------------------------------------------------------------------------------
// looks at next token in current command
//------------------------------------------------------------------------------
function TSQLMemLexer.LookNextToken(var Token: TToken): Boolean;
begin
   Result := (FCurrentCommand.CurrentTokenNo+1 < FCurrentCommand.NumTokens);
   if (Result) then
    Token := FCurrentCommand.Tokens[FCurrentCommand.CurrentTokenNo+1]
   else
    Token.TokenType := tktNone;
end;// LookNextToken


//------------------------------------------------------------------------------
// gets current token No
//------------------------------------------------------------------------------
function TSQLMemLexer.GetCurrentTokenNo: integer;
begin
  Result := FCurrentCommand.CurrentTokenNo;
end;// GetCurrentTokenNo


//------------------------------------------------------------------------------
// sets current token No
//------------------------------------------------------------------------------
function TSQLMemLexer.SetCurrentTokenNo(TokenNo: integer; var Token: TToken): Boolean;
begin
 FCurrentCommand.CurrentTokenNo := TokenNo;
 Result := GetCurrentToken(Token);
end;// SetCurrentTokenNo


//------------------------------------------------------------------------------
// sets new number of tokens in current command, CurrentTokenNo := 0
//------------------------------------------------------------------------------
procedure TSQLMemLexer.SetNumTokensInCurrentCommand(NewNumTokens: Integer);
begin
 SetLength(FCurrentCommand.Tokens,NewNumTokens);
 FCurrentCommand.NumTokens := NewNumTokens;
 FCurrentCommand.CurrentTokenNo := 0;
end;// SetCurrentTokenNo


//------------------------------------------------------------------------------
// starts save SQL script: all GetNextToken,GetNextToken will add all token's texts to SavedScript
//------------------------------------------------------------------------------
procedure TSQLMemLexer.StartSaveScript;
var c: WideChar;
begin
 if (not FSaveScript) then
  begin
    FSaveScript := true;
    FSaveScriptStart := FCurrentPos;
    while (FSaveScriptStart < FSQLScriptLength) do
     begin
      c := FSQL[FSaveScriptStart+1];
      if ((c = WideChar(SemiColon)) or
          (SQLMemIsDelimiter(c))) then
       Inc(FSaveScriptStart)
      else
       break;
     end;
  end;
end; // StartSaveScript


//------------------------------------------------------------------------------
// stops save SQL script and return the saved script
//------------------------------------------------------------------------------
function TSQLMemLexer.StopSaveScript(GetResult: Boolean): WideString;
var l:  Integer;
    wc: WideChar;
begin
  Result := '';
  if (FSaveScript) then
   begin
    if (GetResult) then
     begin
      l := FCurrentPos - FSaveScriptStart + 1;
      // add last semi-colon
      if (FSaveScriptStart+l < FSQLScriptLength) then
       begin
        wc := FSQL[FSaveScriptStart+l];
        if (wc = SemiColon) then
         Inc(l);
        {$IFDEF MSWINDOWS}
        if (FSaveScriptStart+l < FSQLScriptLength) then
         begin
          wc := FSQL[FSaveScriptStart+l];
          // CR -> CRLF
          if (wc = WCr) then
           Inc(l);
         end;
        {$ENDIF}
       end;
      if (l > 0) then
        Result := Copy(FSQL,FSaveScriptStart+1,l)
     end;
    FSaveScript := false;
    FSaveScriptStart := -1;
   end;
end; // StopSaveScript


//------------------------------------------------------------------------------
// return true if the token is a Boolean operator
//------------------------------------------------------------------------------
function TSQLMemLexer.SQLMemIsBoooleanOperator: Boolean;
var token: TToken;
begin
  Result := False;
  if (not GetCurrentToken(token)) then
   Exit;
  if (token.ReservedWord = rwNOT) then
  begin
   if (LookNextToken(token)) then
    if (token.ReservedWord = rwLIKE) then
     Result := True;
  end
  else
  Result := (token.ReservedWord in [rwIS,rwIN,rwBETWEEN,rwLIKE,rwAND,rwOR])
            or (token.Text = '>')
            or (token.Text = '<')
            or (token.Text = '=')
            or (token.Text = '==')
            or (token.Text = '<>')
            or (token.Text = '!=')
            or (token.Text = '>=')
            or (token.Text = '<=')
            or (token.Text = '<>')
            ;
end; // SQLMemIsBoooleanOperator


//------------------------------------------------------------------------------
// checks whether token is reserved word
//------------------------------------------------------------------------------
function IsReservedWord(Token: TToken; ReservedWord: TReservedWord=rwNone): Boolean;
begin
 Result := False;
 if (Token.TokenType = tktReservedWord) then
  if ((Token.ReservedWord = ReservedWord) or
      (ReservedWord = rwNone)) then
   Result := True;
end;

//------------------------------------------------------------------------------
// converts hex WideChar to integer hex value
//------------------------------------------------------------------------------
function CharToHexValue(const sym: WideChar): Int64;
begin
 Result := 0;
 case sym of
  '1': Result := 1;
  '2': Result := 2;
  '3': Result := 3;
  '4': Result := 4;
  '5': Result := 5;
  '6': Result := 6;
  '7': Result := 7;
  '8': Result := 8;
  '9': Result := 9;
  'a','A': Result := 10;
  'b','B': Result := 11;
  'c','C': Result := 12;
  'd','D': Result := 13;
  'e','E': Result := 14;
  'f','F': Result := 15;
 end;
end;


//------------------------------------------------------------------------------
// converts hex WideString to integer hex value
//------------------------------------------------------------------------------
function StrToHexValue(const Text: WideString): Int64;
var i,l: Integer;
begin
 Result := 0;
 l := Length(Text);
 for i := 1 to l do
  Result := Result + (CharToHexValue(Text[i]) shl ((l-i) shl 2));
end;


//------------------------------------------------------------------------------
// fix MS params ? - replace to :Param0, :Param1, ...
//------------------------------------------------------------------------------
function GetFixedParamsInQuery(const SQLText: WideString): WideString;
var lexer:      TSQLMemLexer;
    token:      TToken;
    bModified:  Boolean;
    n:          Integer;
begin
 Result := '';
 bModified := False;
 n := -1;
 lexer := TSQLMemLexer.Create(SQLText,nil);
 try
   while lexer.GetNextCommand do
    begin
     if (lexer.SetCurrentTokenNo(0,token)) then
      repeat
       if (token.TokenType = tktParameter) then
         Result := Result + Colon + AnsiQuotedStr(token.Text,BackQuote) + Space
       else
       if ((token.TokenType = tktString) and (token.Text = '?')) then
        begin
         Inc(n);
         bModified := true;
         Result := Result + ':SQLMem_MS_Param'+IntToStr(n)+ Space;
        end
       else
       if (token.TokenType = tktQuotedString) then
         Result := Result + AnsiQuotedStr(token.Text,'"') + Space
       else
       if (token.TokenType = tktBackQuotedString) then
         Result := Result + AnsiQuotedStr(token.Text,BackQuote) + Space
       else
       if (token.TokenType = tktBracketedString) then
         Result := Result + LeftBracket + token.Text + RightBracket + Space
       else
         Result := Result + token.Text + Space;
      until (not lexer.GetNextToken(token));
     Result := Result + SemiColon + Space;
    end;
 finally
   lexer.Free;
   if (not bModified) then
    Result := SQLText;
 end;
end; // GetFixedParamsInQuery


//------------------------------------------------------------------------------
// return true if empty string
//------------------------------------------------------------------------------
function IsEmptyString(Token: TToken): Boolean;
begin
  Result := False;
  if (Token.TokenType = tktQuotedString) then
   if (Length(Token.Text) = 0) then
    Result := True;
end; // IsEmptyString


function IsStringToken(const token: TToken): Boolean;
begin
  Result := (token.TokenType in [tktString,tktQuotedString,tktBackQuotedString,tktBracketedString]);
end; // IsStringToken

function IsQuotedStringToken(const token: TToken): Boolean;
begin
  Result := (token.TokenType in [tktQuotedString,tktBackQuotedString]);
end;

function SQLMemIsDelimiter(c: WideChar): Boolean;
begin
  Result := (c = Tab) or (c = CR) or (c = LF) or (c = Space);
end; // SQLMemIsDelimiter


//------------------------------------------------------------------------------
// Token -> SQL script
//------------------------------------------------------------------------------
function SQLMemGetTokenText(const Token: TToken): WideString;
begin
  Result := '';
  case Token.TokenType of
    tktAssign,
    tktLeftParenthesis,
    tktRightParenthesis,
    tktComma, tktDot,
    tktFloat,tktInt,tktString:
                                  Result := token.Text;
    tktQuotedString:              Result := AnsiQuotedStr(token.Text,'"');
    tktBackQuotedString:          Result := AnsiQuotedStr(token.Text,BackQuote);
    tktBracketedString:           Result := '['+token.Text+']';
    tktReservedWord:              Result := GetReservedWord(token.ReservedWord);
    tktParameter:                 Result := Colon+AnsiQuotedStr(token.Text,'"');
  end;
end; // SQLMemGetTokenText


//------------------------------------------------------------------------------
// return true if the token is the operator token
//------------------------------------------------------------------------------
function SQLMemIsOperatorSign(const token: TToken; const operatorName: WideString): Boolean;
begin
  // added in v.5.91
  Result := (Token.Text = operatorName) and
            (Token.TokenType <> tktQuotedString) and
            (Token.TokenType <> tktBracketedString) and
            (Token.TokenType <> tktBackQuotedString);
end;

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemLexer> initialized');
{$ENDIF}

end.

