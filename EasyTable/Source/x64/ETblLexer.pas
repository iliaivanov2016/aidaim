{$I ETblVer.inc}

unit ETblLexer;

interface

uses classes, windows, sysutils, db,
{$IFDEF DEBUG_FLAG}
 aaDebug,
{$ENDIF}
ETblConst, ETblExcept;

const Lf: AnsiString = #$0A;       // binary mode line separator
const Cr: AnsiString = #$0D;       // text mode line separator
const Crlf: AnsiString = #$0D#$0A; // text mode line separator
const Tab: AnsiString = #$09; // <tab>
const Comment = '-'; // -- comment <Crlf>
const Comment1 = '#'; // # comment <Crlf>
const Dot = '.';
const Comma = ',';
const SemiColon = ';';
const Asterisk = '*';
const SingleQuote = '''';
const DoubleQuote = '"';
const Space = ' ';
const LeftParenthesis = '(';
const RightParenthesis = ')';
const Percent = '%';

ETblTokenType: array [0..11] of AnsiString =
(
 'tktNone', 'tktString', 'tktQuotedString', 'tktBracketedString',
 'tktInt', 'tktFloat', 'tktReservedWord',
 'tktParam', 'tktLeftParenthesis', 'tktRightParenthesis',
 'tktComma', 'tktDot'
);

type
 TTokenType = (tktNone, tktString, tktQuotedString, tktBracketedString,
 tktInt, tktFloat, tktReservedWord,
 tktParam, tktLeftParenthesis, tktRightParenthesis,
 tktComma, tktDot);

 TTokenTypes = set of TTokenType;

 TToken = record
  TokenType:      TTokenType;
  ReservedWord:   TReservedWord;
  Text:           AnsiString;
  UnicodeText:    WideString;
  LineNum:        Integer; // number of line in script where token begins
  ColumnNum:      Integer; // number of column in script where token begins
 end;

 PToken = ^TToken;

 TSQLCommand = record
  Tokens:     array of TToken;
  NumTokens:  Integer;
  CurrentTokenNo: Integer;
 end;

 TEasyLexer = class (TObject)
  private
   FSQL:  AnsiString;
   FParams: TParams;
   procedure Parse;
  public
   NumCommands: Integer;
   Commands:    array of TSQLCommand;
   CurrentCommandNo:   Integer;

   constructor Create(SQLScript: AnsiString; Params: TParams);
   destructor Destroy; override;
   function Test(bGenerate: Boolean = true; bShowDetails: Boolean = true): AnsiString;

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
   // gets first next token specified type
   function GetNextSpecifiedToken(var Token: TToken; TokenTypes: TTokenTypes): Boolean;
 end;

 // checks whether token is reserved word
 function IsReservedWord(Token: TToken; ReservedWord: TReservedWord=rwNone): Boolean;
 function StrToHexValue(const Text: AnsiString): Int64;

implementation


////////////////////////////////////////////////////////////////////////////////
//
// TEasyLexer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Parse SQL script
//------------------------------------------------------------------------------
procedure TEasyLexer.Parse;
var i,l:      Integer;
    line,command,token,column:  Integer;
    c,priorSymbol:   AnsiChar;
    numParenthesis,
    LeftParenthesisLine,
    LeftParenthesisColumn,
    RightParenthesisLine,
    RightParenthesisColumn,
    quoteLine,quoteColumn: Integer;
    bIsDelimiter:     boolean;
    bTokenStarted:    boolean;
    bCommandStarted:  boolean;
    bNewTokenStarted: boolean;
    bTokenFinished:   boolean;
    bQuoteNotClosed:  boolean;
    bHexConstStarted: boolean;

  function GetNextSymbol: AnsiChar;
  begin
   result := ' ';
    if (i < l-1) then
     result := pAnsiChar(pAnsiChar(FSQL)+i+1)^;
  end;


 function IsNewTokenStarted: Boolean;
 begin
  result := false;
  if (bTokenStarted) then
   begin
      if (c = '>') or (c = '<') or (c = '=') or (c = '(') or (c = ')') or
         (c = ',') or (c = '/') or (c = '*') or (c = ':') or (c = '|') or
         ((c=Dot) and (Commands[command].Tokens[token].TokenType<>tktInt)) then
           result := true
      else
      if (Commands[command].Tokens[token].TokenType = tktDot) then
       begin
         if not ((c >= '0') and (c <= '9')) then
          result := true;
       end
      else
      if (Commands[command].Tokens[token].TokenType = tktString) then
       begin
        if (c = '+') or (c = '-') then
         result := true;
       end
      else
      if (Commands[command].Tokens[token].TokenType = tktInt) then
       begin
        if (c = '+') and (LowerCase(priorSymbol) <> 'e') then
         result := true
        else
        if (c = '-') and (LowerCase(priorSymbol) <> 'e') then
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
     result := true;
   end;
 end; // IsTokenFinished

 function FindReservedWord: Integer;
 var i: integer;
     s: AnsiString;
 begin
  result := -1;
  s := UpperCase(Commands[command].Tokens[token].Text);
  for i := 0 to ETblMaxSQLReservedWords do
    if (s = ETblSQLReservedWords[i]) then
     begin
      result := i;
      break;
     end;
 end; // FindReservedWord

 procedure CreateCommand;
 begin
  inc(NumCommands);
  SetLength(Commands, NumCommands);
  command := NumCommands-1;
  Commands[command].NumTokens := 0;
  Commands[command].Tokens := nil;
  token := 0;
  bCommandStarted := true;
  numParenthesis := 0;
 end; // CreateCommand;

 procedure CloseToken;
 var i: integer;
     Param: TParam;
     oldSeparator: Char;
     bParam:  Boolean;
 begin
  if (not bTokenStarted) then
   Exit;
  bParam := False;
  // check int or float
  if (Commands[command].Tokens[token].TokenType = tktInt) then
   begin
    // check int or float
    if (Pos('.',Commands[command].Tokens[token].Text) > 0) then
     Commands[command].Tokens[token].TokenType := tktFloat
    else
    if (Pos('e',LowerCase(Commands[command].Tokens[token].Text)) > 0) then
     Commands[command].Tokens[token].TokenType := tktFloat;
    if (bHexConstStarted) then
     Commands[command].Tokens[token].Text :=
      IntToStr(StrToHexValue(Commands[command].Tokens[token].Text));
   end;
  // check for reserved word
  if (Commands[command].Tokens[token].TokenType = tktString) then
   begin
//    Commands[command].Tokens[token].Text :=
//      UpperCase(Commands[command].Tokens[token].Text);
    Commands[command].Tokens[token].UnicodeText := '';
    if (Commands[command].Tokens[token].Text[1] = ':') then
     begin
      bParam := True;
      Commands[command].Tokens[token].TokenType := tktParam;
      // param name without ':'
      Commands[command].Tokens[token].Text := Copy(
              Commands[command].Tokens[token].Text, 2,
              Length(Commands[command].Tokens[token].Text)-1);
      // try to set param value
      if (FParams <> nil) then
       begin
        Param := FParams.ParamByName(Commands[command].Tokens[token].Text);
        if (Param <> nil) then
         begin
          case Param.DataType of
           ftBlob,ftMemo,ftFmtMemo,ftGraphic,
           ftTime,
           ftDate,
           ftDateTime,
           ftString,
           ftWideString:
             Commands[command].Tokens[token].TokenType := tktQuotedString;

           ftSmallInt,
           ftLargeInt,
           ftInteger,
           ftWord,
           ftAutoInc:
             Commands[command].Tokens[token].TokenType := tktInt;
           ftFloat,
           ftCurrency,
           ftBCD:
             Commands[command].Tokens[token].TokenType := tktFloat;
           else
             Commands[command].Tokens[token].TokenType := tktString;
          end;
          // set value
          case Param.DataType of
           ftTime:
            Commands[command].Tokens[token].Text := TimeToStr(Param.AsTime);
           ftDate:
            Commands[command].Tokens[token].Text := DateToStr(Param.AsDate);
           ftFloat,
           ftCurrency,
           ftBCD:
            begin
{$IFDEF D17H}
             oldSeparator := FormatSettings.DecimalSeparator;
             FormatSettings.DecimalSeparator := '.';
             try
              Commands[command].Tokens[token].Text := FloatToStr(Param.AsFloat);
             finally
              FormatSettings.DecimalSeparator := oldSeparator;
             end;
{$ELSE}
             oldSeparator := DecimalSeparator;
             DecimalSeparator := '.';
             try
              Commands[command].Tokens[token].Text := FloatToStr(Param.AsFloat);
             finally
              DecimalSeparator := oldSeparator;
             end;
{$ENDIF}
            end;
           ftBlob,ftMemo,ftFmtMemo,ftGraphic:
             Commands[command].Tokens[token].Text := '$Blob$Marker$' + Param.Name;
           ftWideString:
            begin
             Commands[command].Tokens[token].Text := Param.AsString;
             Commands[command].Tokens[token].UnicodeText := WideString(Param.Value);
            end
           else
            Commands[command].Tokens[token].Text := Param.AsString;
          end;
         end;
       end;
     end;
    // Set reserved word
    if (not bParam) then
     begin
      i := FindReservedWord;
      if (i > 0) then
       begin
        Commands[command].Tokens[token].ReservedWord := TReservedWord(i);
        Commands[command].Tokens[token].TokenType := tktReservedWord;
       end;
     end;
   end;
  bTokenStarted := false;
 end; // CloseToken;

 procedure CreateToken;
 var NextSymbol: AnsiChar;
     quoteSymbol: AnsiChar;
 begin
  if (not bCommandStarted) then
   CreateCommand;
  bTokenStarted := true;
  bHexConstStarted := false;
  inc(Commands[command].NumTokens);
  SetLength(Commands[command].Tokens,Commands[command].NumTokens);
  token := Commands[command].NumTokens - 1;
  Commands[command].Tokens[token].Text := c;
  Commands[command].Tokens[token].ColumnNum := column;
  Commands[command].Tokens[token].LineNum := line;
  Commands[command].Tokens[token].ReservedWord := rwNone;
  // here will be scanning quoted /bracketed string to its end
  if (c = SingleQuote) or (c = DoubleQuote) or (c = '[') then
   begin
    Commands[command].Tokens[token].Text := '';
    if (c <> '[') then
     Commands[command].Tokens[token].TokenType := tktQuotedString
    else
     Commands[command].Tokens[token].TokenType := tktBracketedString;
    if (c <> '[') then
     quoteSymbol := c
    else
     quoteSymbol := ']';
    quoteLine := line;
    quoteColumn := column;
    bQuoteNotClosed := true;
    inc(i);
    while (i < l) do
     begin
      c := pAnsiChar(pAnsiChar(FSQL)+i)^;
      NextSymbol := GetNextSymbol;
      if (c = quoteSymbol) then
       begin
        if (NextSymbol = c) then
         begin
          Commands[command].Tokens[token].Text :=
            Commands[command].Tokens[token].Text + c;
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

      Commands[command].Tokens[token].Text :=
         Commands[command].Tokens[token].Text + c;
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
   end   // here will be scanning quoted /bracketed string to its end
  else
  if (c = '$') then
   begin
    // hex constant , like $ff
    Commands[command].Tokens[token].TokenType := tktInt;
    bHexConstStarted := true;
    Commands[command].Tokens[token].Text := '';
   end
  else
  if (c = '!') then
   begin
    Commands[command].Tokens[token].TokenType := tktString;
    if (GetNextSymbol = '=') then
     begin
      // !=
      Commands[command].Tokens[token].Text := '!=';
     end
    else
     begin
      // !
      Commands[command].Tokens[token].Text := '!';
     end;
    CloseToken;
   end
  else
  if (c = '~') then
   begin
    Commands[command].Tokens[token].TokenType := tktString;
    Commands[command].Tokens[token].Text := '~';
    CloseToken;
   end
  else
  if (c = LeftParenthesis) then
   begin
    Commands[command].Tokens[token].TokenType := tktLeftParenthesis;
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
    Commands[command].Tokens[token].TokenType := tktRightParenthesis;
    CloseToken;
   end
  else
  if (c = Dot) then //!!
   begin
    Commands[command].Tokens[token].TokenType := tktDot;
    //CloseToken;
   end
  else
  if (c = Comma) then
   begin
    Commands[command].Tokens[token].TokenType := tktComma;
    CloseToken;
   end
  else
  if ((c >= '0') and (c <= '9')) then
    Commands[command].Tokens[token].TokenType := tktInt
  else
   Commands[command].Tokens[token].TokenType := tktString;
  if (c = '-') or (c = '+') or (c = '*') or (c = '/') or (c = '=') then
   CloseToken;
  if (c = '|') then
   begin
    NextSymbol := GetNextSymbol;
    if (NextSymbol = '|') then
     begin
      Commands[command].Tokens[token].Text :=
        Commands[command].Tokens[token].Text + NextSymbol;
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
      Commands[command].Tokens[token].Text :=
        Commands[command].Tokens[token].Text + NextSymbol;
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
      Commands[command].Tokens[token].Text :=
        Commands[command].Tokens[token].Text + NextSymbol;
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
    raise ETblException.Create(00001,[LeftParenthesisLine,LeftParenthesisColumn],nil);

  if (numParenthesis < 0) then
    raise ETblException.Create(00002,[LeftParenthesisLine,LeftParenthesisColumn],nil);
  priorSymbol := ' ';

  if (bQuoteNotClosed) then
    raise ETblException.Create(00003,[quoteLine,quoteColumn],nil);
 end; // CloseCommand;

 var NextSymbol: AnsiChar;
begin
 l := Length(FSQL);
 line := 1;
 column := 1;
 NumCommands := 0;
 Commands := nil;
 bTokenStarted := false;
 bQuoteNotClosed := false;
 bCommandStarted := false;
 command := 0;
 token := 0;
 priorSymbol := ' ';
 numParenthesis := 0;
 LeftParenthesisLine := 0;
 LeftParenthesisColumn := 0;
 RightParenthesisLine := 0;
 RightParenthesisColumn := 0;
 i := 0;
 while (i < l) do
  begin
   // get current character
   c := pAnsiChar(pAnsiChar(FSQL)+i)^;

   // end of the current comand
   if (c = ';') then
    begin
     CloseCommand;
     inc(i);
     continue;
    end;

   // check for comment
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
         c := pAnsiChar(pAnsiChar(FSQL)+i)^;
         if (c = lf) then
           break;
         inc(i);
        end;
       inc(i);
       continue;
      end;
    end; // comment --

   // check for comment
   if (c = '/') then
    begin
     NextSymbol := GetNextSymbol;
     if (NextSymbol = '*') then
      begin
       // commentary started
       inc(i,2);
       inc(column,2);
       while (i < l) do
        begin
          c := pAnsiChar(pAnsiChar(FSQL)+i)^;
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
   bIsDelimiter := false;
   if (c = Tab) or (c = CR) or (c = LF) or (c = Space) then
    bIsDelimiter := true;

   bTokenFinished := IsTokenFinished;
   bNewTokenStarted := IsNewTokenStarted;
   if (bTokenFinished) or (bTokenStarted and bNewTokenStarted) then
    CloseToken;
   if (bNewTokenStarted) then
    CreateToken;

   // add current symbol to token
   if (not bNewTokenStarted) and (bTokenStarted) and (not bIsDelimiter) then
    begin
     // check for number
     if Commands[command].Tokens[token].TokenType in [tktInt,tktFloat] then
      if not ((c >= '0') and (c <= '9') or (c = Dot) or
              (LowerCase(c)='a') or (LowerCase(c)='b') or (LowerCase(c)='c') or
              (LowerCase(c)='d') or (LowerCase(c)='e') or (LowerCase(c)='f') or
              (c = '+') or (c = '-') or (c = 'x')) then
                 raise ETblException.Create(00044, [c,line,column],nil);
      // check float type .22
      if (Commands[command].Tokens[token].TokenType = tktDot) and
         (c >= '0') and (c <= '9') then
       begin
        Commands[command].Tokens[token].TokenType := tktInt;
       end;
     if ((c = 'x') and (Commands[command].Tokens[token].TokenType = tktInt)) then
      begin
       Commands[command].Tokens[token].Text := '';
       bHexConstStarted := true;
      end
     else
      // add current symbol to token
      Commands[command].Tokens[token].Text :=
       Commands[command].Tokens[token].Text + c;
    end;
     // <<, >>, ||, &&, ==
    if (bNewTokenStarted) then
     if (((c = '<') or (c = '>') or (c = '&') or (c = '|') or (c = '=')) and (GetNextSymbol = c)) then
      begin
       Commands[command].Tokens[token].Text :=
        Commands[command].Tokens[token].Text + c;
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

 CloseCommand;
end; // Parse


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TEasyLexer.Create(SQLScript: AnsiString; Params: TParams);
var
  i: integer;
begin
 FSQL := SQLScript;
 FParams := Params;
 NumCommands := 0;
 Parse;
 CurrentCommandNo := -1;
 for i := 0 to NumCommands-1 do
  Commands[i].CurrentTokenNo := 0;
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TEasyLexer.Destroy;
var i: integer;
begin
 for i := 0 to NumCommands - 1 do
  begin
   Commands[i].Tokens := nil;
  end;
 Commands := nil;
 inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// test
//------------------------------------------------------------------------------
function TEasyLexer.Test(bGenerate: Boolean = true; bShowDetails: Boolean = true): AnsiString;
var i,j: integer;
    s: AnsiString;
begin
 result := 'Number of commands: '+IntToStr(NumCommands);
 if (bGenerate) then
  begin
   // generate
  end;

 for i := 0 to NumCommands - 1 do
  begin
   result := result + Crlf+'Command #'+IntToStr(i+1)+':' + Crlf;
   for j := 0 to Commands[i].NumTokens - 1 do
    begin
     result := result + Commands[i].Tokens[j].Text + Crlf;
     if (bShowDetails) then
      begin
       if (Commands[i].Tokens[j].ReservedWord = rwNone) then
        s := 'ReservedWord = None'+Crlf
       else
        s :=  'ReservedWord = '+ETblSQLReservedWords[Integer(Commands[i].Tokens[j].ReservedWord)]+Crlf;
       result := result +
        'Type = '+ETblTokenType[Integer(Commands[i].Tokens[j].TokenType)]+Crlf+
        s+
        'Line = '+IntToStr(Commands[i].Tokens[j].LineNum)+Crlf+
        'Column = '+IntToStr(Commands[i].Tokens[j].ColumnNum)+Crlf+Crlf;
      end;
    end;

  end;
end; // Test


//------------------------------------------------------------------------------
// makes next command current
//------------------------------------------------------------------------------
function TEasyLexer.GetNextCommand: Boolean;
begin
 Inc(CurrentCommandNo);
 Result := (CurrentCommandNo < NumCommands);
end;// GetNextCommand

//------------------------------------------------------------------------------
// gets next token in current command
//------------------------------------------------------------------------------
function TEasyLexer.GetNextToken(var Token: TToken): Boolean;
begin
 with Commands[CurrentCommandNo] do
  begin
   Result := LookNextToken(Token);
//   if (Result) then
    Inc(CurrentTokenNo);
  end;
end;// GetNextToken


//------------------------------------------------------------------------------
// gets current token in current command
//------------------------------------------------------------------------------
function TEasyLexer.GetCurrentToken(var Token: TToken): Boolean;
begin
 with Commands[CurrentCommandNo] do
  begin
   Result := (CurrentTokenNo < NumTokens);
   if (Result) then
    Token := Tokens[CurrentTokenNo]
   else
    Token.TokenType := tktNone;
  end;
end;// GetCurrentToken


//------------------------------------------------------------------------------
// looks at next token in current command
//------------------------------------------------------------------------------
function TEasyLexer.LookNextToken(var Token: TToken): Boolean;
begin
 with Commands[CurrentCommandNo] do
  begin
   Result := (CurrentTokenNo+1 < NumTokens);
   if (Result) then
    Token := Tokens[CurrentTokenNo+1]
   else
    Token.TokenType := tktNone;
  end;
end;// LookNextToken


//------------------------------------------------------------------------------
// gets current token No
//------------------------------------------------------------------------------
function TEasyLexer.GetCurrentTokenNo: integer;
begin
  Result := Commands[CurrentCommandNo].CurrentTokenNo;
end;// GetCurrentTokenNo


//------------------------------------------------------------------------------
// sets current token No
//------------------------------------------------------------------------------
function TEasyLexer.SetCurrentTokenNo(TokenNo: integer; var Token: TToken): Boolean;
begin
 Commands[CurrentCommandNo].CurrentTokenNo := TokenNo;
 Result := GetCurrentToken(Token);
end;// SetCurrentTokenNo


// checks whether token is reserved word
function IsReservedWord(Token: TToken; ReservedWord: TReservedWord=rwNone): Boolean;
begin
 Result := False;
 if (Token.TokenType = tktReservedWord) then
  if ((Token.ReservedWord = ReservedWord) or
      (ReservedWord = rwNone)) then
   Result := True;
end;

//------------------------------------------------------------------------------
// gets first next token specified type
//------------------------------------------------------------------------------
function TEasyLexer.GetNextSpecifiedToken(var Token: TToken;
  TokenTypes: TTokenTypes): Boolean;
begin
 with Commands[CurrentCommandNo] do
  begin
   repeat
     Result := LookNextToken(Token);
     if (Result) then
      Inc(CurrentTokenNo);
   until (not Result) or (Token.TokenType in TokenTypes);
  end;
end;// GetNextSpecifiedToken

function CharToHexValue(const sym: AnsiChar): Int64;
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

function StrToHexValue(const Text: AnsiString): Int64;
var i,l: Integer;
begin
 Result := 0;
 l := Length(Text);
 for i := 1 to l do
  Result := Result + (CharToHexValue(Text[i]) shl ((l-i) shl 2));
end;

end.

