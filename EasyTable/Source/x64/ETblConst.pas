{$I ETblVer.inc}

unit ETblConst;

interface

uses db;

type
  TETFieldType = record
   fieldType : TFieldType;
   sqlName   : string[20];
   name      : string[20];
  end;

 TDatabaseFileMode = (dfmCompact,dfmNormal,dfmLarge);

const ETblDefaultParamName = 'Param_';

// field types supported
const MAX_SUPPORTED_FIELD_TYPES = 19;
const SUPPORTED_FIELD_TYPES : array [1..MAX_SUPPORTED_FIELD_TYPES] of TETFieldType =
      (
      (fieldType : ftAutoInc;     sqlName : 'AUTOINC';    name : 'AutoInc'),
      (fieldType : ftInteger;     sqlName : 'INTEGER';    name : 'Integer'),
      (fieldType : ftString;      sqlName : 'STRING';     name : 'String'),
      (fieldType : ftWideString;  sqlName : 'WIDESTRING'; name : 'Wide String'),
      (fieldType : ftDate;        sqlName : 'DATE';       name : 'Date'),
      (fieldType : ftTime;        sqlName : 'TIME';       name : 'Time'),
      (fieldType : ftDateTime;    sqlName : 'DATETIME';   name : 'DateTime'),
      (fieldType : ftCurrency;    sqlName : 'CURRENCY';   name : 'Currency'),
      (fieldType : ftBoolean;     sqlName : 'LOGICAL';    name : 'Logical'),
      (fieldType : ftMemo;        sqlName : 'MEMO';       name : 'Memo'),
      (fieldType : ftFmtMemo;     sqlName : 'FMTMEMO';    name : 'Formatted Memo'),
      (fieldType : ftGraphic;     sqlName : 'GRAPHIC';    name : 'Graphic'),
      (fieldType : ftBLOB;        sqlName : 'BLOB';       name : 'BLOB'),
      (fieldType : ftSmallInt;    sqlName : 'SMALLINT';   name : 'Small Integer'),
      (fieldType : ftWord;        sqlName : 'WORD';       name : 'Word'),
      (fieldType : ftFloat;       sqlName : 'FLOAT';      name : 'Float'),
      (fieldType : ftBCD;         sqlName : 'BCD';        name : 'BCD'),
      (fieldType : ftBytes;       sqlName : 'BYTES';      name : 'Bytes'),
      (fieldType : ftLargeInt;    sqlName : 'LARGEINT';   name : 'Large Integer')
      );

const
  ErUnknownError = 0;

  // Leo
  ErMissingRightParenthesis = 1;
  ErUnexpectedRightParenthesis = 2;
  ErUnterminatedString = 3;
  ErCannotOpenTable = 4;
  ErCannotSetFilter = 5;
  ErDifferentLength = 6;
  ErTableIsNotOpened = 7;
  ErRecordBufferIsNil = 8;
  ErInvalidFieldNo = 9;
  ErInvalidField = 10;
  ErFieldHeaderIsNil = 11;
  ErFieldNotFound = 12;
  ErInvalidTableName = 13;
  ErInvalidFieldLink = 14;
  ErCannotReadHiddenField = 15;
  ErCannotSetIndexDatasetNil = 16;
  ErInvalidJoinField = 17;
  ErArrayIsEmpty= 18;
  ErFieldIsHidden = 19;
  ErInvalidTypeCast = 20;
  ErInvalidTypeCastName = 21;
  ErBothJoinAOEqual = 22;
  ErInvalidType = 23;
  ErInvalidTypeName = 24;
  ErEqualRecordsInJoins = 25;
  ErDistinctIndexNotCreated = 26;
  ErInvalidUnionType = 27;
  ErInvalidFieldName = 28;
  ErInvalidNumericSymbol = 29;
  ErInvalidFilterExpressionType = 30;
  ErFieldDoesNotIncludedInGroupByList = 31;
  ErNonAggregateFunctionInGroupBySelectList = 32;
  ErQueryComponentIsNil = 33;
  ErSubQueryReturnsNoRows = 34;
  ErSubQueryReturnsMultipleRows = 35;
  ErNotFloatDataType = 36;
  ErNotSmallIntDataType = 37;
  ErNotLargeIntDataType = 38;
  ErNotWordDataType = 39;
  ErNoCorrelatedColumnsPassed = 40;
  ErNoInColumn  = 41;
  ErTypesMismatchesInSQLFunction = 42;
  ErArgumentExpectedInSQLFunction = 43;
  ErFromOrCommaExpected = 44;
  ErNoChildren = 45;

  // Andrew
  ErBlankSQLCommand = 71;
  ErSQLCommandExpected = 72;
  ErUnexpectedEndOfCommand = 73;
  ErFieldNameExpected = 74;
  ErFieldPseudonymExpected = 75;
  ErTableNameExpected = 76;
  ErFromExpected = 77;
  ErFieldListExpected = 78;
  ErUnexpectedToken = 79;
  ErOtherTokenExpected = 80;
  ErBooleanExpressionExpected = 81;
  ErSortSpecificationExpected = 82;
  ErColumnFromOrderByNotFound = 83;
  ErCannotFindField = 84;
  ErUnsupportedOperator = 85;
  ErAmbiguousFieldReference = 86;
  ErCircularDataLink = 87;
  ErNodeIsNotField = 88;
  ErCannotSetIndexWithField = 89;
  ErNoCursorInQuery = 90;
  ErNotApplicableCondition = 91;
  ErExprValue = 92;
  ErInvalidSessionName = 93;
  ErSessionActive = 94;
  ErAutoSessionActive = 95;
  ErDuplicateSessionName = 96;
  ErSessionNameMissing = 97;
  ErEngineNotInitialized = 98;
  ErAutoSessionExclusive = 99;
  ErAutoSessionExists = 100;
  ErDatabaseOpen = 101;
  ErDatabaseNameMissing = 102;
  ErDuplicateDatabaseName = 103;
  ErDatabaseClosed = 104;
  ErDatabaseHandleSet = 105;
  ErNotEditing = 106;
  ErNotIndexField = 107;
  ErDBMHandleIsNil = 108;
  ErCannotCreateHandle = 109;
  ErVisibleRecordsError = 110;
  ErExpressionExpected = 111;
  ErIntegerExpected = 112;
  ErDuplicateTablePseudonym = 113;

  // George
  ErNonInsertCommand = 151;
  ErTableOrIndexKeywordExpected = 152;
  ErLeftParenthesisExpected = 153;
  ErFieldTypeExpected = 154;
  ErUnknownFileldType = 155;
  ErDecimalConstantExpected = 156;
  ErRightParenthesisExpected = 157;
  ErNullKeywordExpected = 158;
  ErErrorCreatingTable = 159;
  ErQuotedPasswordDataExpected = 160;
  ErRightParenthesisOrCommaExpected = 161;
  ErBlobCompressionLevelValueExpected = 162;
  ErUnknownCompressLevel = 163;
  ErDroppingTable = 164;
  ErAddOrDropOrModifyKeywordExpected = 165;
  ErNewDataTypeOrNotNullExpected = 166;
  ErPasswordKeywordExpected = 167;
  ErDroppingColumns = 168;
  ErIndexKeywordExpected = 169;
  ErIndexNameExpected = 170;
  ErOnKeywordExpected = 171;
  ErIntoKeywordExpected = 172;
  ErInsertFromTheTableToItSelf = 173;
  ErSetKeywordExpected = 174;
  ErEqualExpected = 175;
  ErNotnumericArgument = 176;
  ErCantConvertTypeFromTo = 177;
  ErStringArgumentExpected = 178;
  ErNotStringArgument = 179;
  ErArgumentExpected = 180;
  ErNotIntegerDataType = 181;
  ErNotBooleanDataType = 182;
  ErNotApplicableCastType = 183;
  ErTableAlreadyExists = 184;
  ErNotDateTimeDataType = 185;
  ErConstDateFormatExpected = 186;
  ErAMPMKeyWordExpected = 187;
  ErAutoIncUniquenessViolation = 188;

  ETblMaxError = 192;
  ETblErrorMessages: array[0..ETblMaxError] of String =
  (
   'Unknown error',
   // Leo
   'Missing right parenthesis at line %d, column %d',
   'Unexpected symbol '')'' found at line %d, column %d',
   'Unterminated string at line %d, column %d',
   'Cannot open table ''%s''. DatabaseName = %s, DatabaseFileName = %s, InMemory = %d.',
   'Cannot set filter ''%s'' on table ''%s''. DatabaseName = %s, DatabaseFileName = %s, InMemory = %d.',
   'Different Length of arrays. Length1 = %d, Length2 = %d.',
   'Table is not opened, table name = ''%s''.',
   'Record buffer is nil. Table name = ''%s''.',
   'Invalid field number. Table name = ''%s'', FieldNo = %d',
   'Invalid field. Table name = ''%s'', FieldNo = %d',
   'Field header is nil. Table name = ''%s'', i = %d',
   'Field not found. Table name = ''%s'', Field name = ''%s''',
   'Invalid table name. Table name = ''%s'', alias = ''%s'', invalid table name = ''%s''',
   'Field link is invalid - AO = Dataset = nil. Table name = ''%s'', FieldNo = %d',
   'Cannot read hidden field. Table name = ''%s'', FieldNo = %d',
   'Cannot set index - result dataset does not exists.',
   'Invalid field. Table name = ''%s'', FieldName = ''%s'', i = %d, FieldExists = %d',
   'Array is empty. ItemCount = %d',
   'Field is hidden. FieldName = ''%s'', DisplayName = ''%s'', j = %d',
   'Invalid type cast.',
   'Invalid type cast. Field1 = ''%s'', Field2 = ''%s''.',
   'Both join fields are from the same table. Field1 = ''%s'', Field2 = ''%s'', No1 = %d, No2 = %d.',
   'Invalid type - compare is not supported.',
   'Invalid type - compare is not supported. Field1 = ''%s'', Field2 = ''%s''.',
   'Equal records in joins, while not EOF loop.',
   'Distinct index not created. FTableName = ''%s'', FDistinctFields = ''%s''.',
   'Invalid union type = %d.',
   'Invalid field name. Table name = ''%s'', field name = ''%s'', FieldCount = %d',
   'Invalid numeric symbol ''%s'' at line %d, column %d',
   'Filter expression should be Boolean. Filter type = %d',
   'Field is not included in GROUP BY list. Table name = ''%s'', Field name = ''%s'', FieldNo = %d, Found field name = ''%s''',
   'Using Non-Aggregate expressions in queries with GROUP BY option is prohibited. Field name = ''%s'', FieldNo = %d',
   'Query component supplied to Expression is nil',
   'Sub-query returns no rows',
   'Sub-query returns multiple rows',//Cannot set index by fields ''%s'' on table ''%s''. Case insensitive fields = ''%s''.
   'Not a float data type',
   'Not a small integer data type',
   'Not a large integer data type',
   'Not a word data type',
   'No correlated columns have been passed to correlated sub-query',
   'No column was passed to IN sub-query',
   'Types mismatches in SQL function %s: %d, %d',
   'Argument expected in SQL function %s',
   'FROM or '','' expected, but ''%s'' found at line %d, column %d',
   'Error - no children in expression node',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '', // end of (Leo)

   'Blank SQL command', // Andrew
   'SQL token expected, but ''%s'' found at line %d, column %d',
   'Unexpected end of SQL command found at line %d',
   'Field name expected, but ''%s'' found at line %d, column %d',
   'Field pseudonym expected, but ''%s'' found at line %d, column %d',
   'Table name expected, but ''%s'' found at line %d, column %d',
   'FROM expected, but ''%s'' found at line %d, column %d',
   'Field list expected, but ''%s'' found at line %d, column %d',
   'Unexpected token ''%s'' found at line %d, column %d',
   'Token ''%s'' expected, but ''%s'' found at line %d, column %d',
   'Boolean expression expected, but ''%s'' found at line %d, column %d',
   'Sort specification expected, but ''%s'' found at line %d, column %d',
   'Column ''%s'' from ORDER BY clause not found',
   'Field ''%s'' not found',
   'Operator with code=%d is not supported',
   'Ambiguous field reference to ''%s''',
   'Circular datalinks are not allowed',
   'Node is not field',
   'Cannot add index. Field ''%s'' not found',
   'No cursor in query.',
   'Search condition ''%s'' is not applicable',
   'Cannot get expression value',
   'Invalid session name ''%s''',
   'Cannot perform this operation on an active session',
   'Cannot modify SessionName while AutoSessionName is enabled',
   'Duplicate session name ''%s''',
   'Session name missing',
   'EasyTable Engine is not initialized',
   'Cannot enable AutoSessionName property with more than one session on a form or data-module',
   'Cannot add a session to the form or data-module while session ''%s'' has AutoSessionName enabled',
   'Cannot perform this operation on an open database',
   'Database name missing',
   'Duplicate database name ''%s''',
   'Cannot perform this operation on a closed database',
   'Database handle owned by a different session',
   'Dataset not in edit or insert mode',
   'Field ''%s'' is not indexed and cannot be modified',
   'Database manager handle is nil',
   'Error creating cursor handle. Try to use ExecSQL instead of Open method',
   'Internal engine error. Cannot create visible records list',
   'Expression expected, but ''%s'' found at line %d, column %d',
   'Integer expected, but ''%s'' found at line %d, column %d',
   'Duplicate table pseudonym ''%s''',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   '',
   // end of (Andrew)

   // George
   'Non-insert SQL command',
   '''TABLE'' or ''INDEX'' keyword expected, but ''%s'' found at line %d, column %d',
   '''('' symbol expected, but ''%s'' found at line %d, column %d',
   'Field type expected, but ''%s'' found at line %d, column %d',
   'Unknown field type ''%s'' at line %d, column %d',
   'Decimal constant expected, but ''%s'' found at line %d, column %d',
   ''')'' symbol expected, but ''%s'' found at line %d, column %d',
   '''NULL'' expected (for NOT NULL), but ''%s'' found at line %d, column %d',
   'Error creating table: ''%s''',
   'Quoted password expected (for PASSWORD "passwordData"), but ''%s'' found at line %d, column %d',
   ''')'' or '','' symbol expected, but ''%s'' found at line %d, column %d',
   'Blob Compression Level value expected, but ''%s'' found at line %d, column %d',
   'Unknown compress level: ''%s'' found at line %d, column %d',
   'Error dropping table: ''%s''',
   'ADD, DROP or MODIFY keyword expected, but ''%s'' found at line %d, column %d',
   'New data type or NULL or NOT NULL keyword expected, but ''%s'' found at line %d, column %d',
   '''PASSWORD'' keyword expected (for NEW PASSWORD), but ''%s'' found at line %d, column %d',
   'Error dropping column(s): ''%s''',
   '''INDEX'' keyword expected, but ''%s'' found at line %d, column %d',
   'index name expected, but ''%s'' found at line %d, column %d',
   '''ON'' keyword expected, but ''%s'' found at line %d, column %d',
   'INTO keyword expected, but ''%s'' found at line %d, column %d',
   'Insert from select is not supported yet',
   '''SET'' keyword expected, but ''%s'' found at line %d, column %d',
   'Token ''='' expected, but ''%s'' found at line %d, column %d',
   'Not numeric argument in numeric operator ''%s''',
   'Can''t convert data type from ''%s'' to ''%s''',
   'String argument expected for function ''%s'', but ''%s'' found at line %d, column %d',
   'Not string argument in function ''%s''',
   'Argument expected for function ''%s'' at line %d, column %d',
   'Not Integer data type',
   'Not Boolean data type',
   'Cannot convert an expression to specified type: ''%s''',
   'Cannot create table. Table ''%s'' already exists',
   'Not DateTime data type',
   'Const DateFormat string expected, but ''%s'' found at line %d, column %d',
   'AM/PM word expected, but ''%s'' found',
   'AutoInc uniqueness violation. Update or insert of duplicate AutoInc value (%d) failed ',
   '',
   '',
   '',
   ''
   // end of George
  );

  ETblMaxNativeError = 342;
  ETblNativeToErrorCode: array[0..ETblMaxNativeError,0..1] of Integer =
  (
    (00000, ErUnknownError)
   ,(00001, ErMissingRightParenthesis) // Leo
   ,(00002, ErUnexpectedRightParenthesis) // Leo
   ,(00003, ErUnterminatedString) // Leo
   ,(00004, ErCannotOpenTable) // Leo
   ,(00005, ErCannotSetFilter) // Leo
   ,(00006, ErDifferentLength) // Leo
   ,(00007, ErTableIsNotOpened) // Leo
   ,(00008, ErRecordBufferIsNil) // Leo
   ,(00009, ERInvalidFieldNo) // Leo
   ,(00010, ERInvalidField) // Leo
   ,(00011, ERInvalidFieldNo) // Leo
   ,(00012, ErFieldHeaderIsNil) // Leo
   ,(00013, ErFieldNotFound) // Leo
   ,(00014, ErInvalidTableName) // Leo
   ,(00015, ErInvalidFieldLink) // Leo
   ,(00016, ErCannotReadHiddenField) // Leo
   ,(00017, ErCannotSetIndexDatasetNil) // Leo
   ,(00018, ErRecordBufferIsNil) // Leo
   ,(00019, ErRecordBufferIsNil) // Leo
   ,(00020, ErInvalidJoinField) // Leo
   ,(00021, ErInvalidJoinField) // Leo
   ,(00022, ErArrayIsEmpty) // Leo
   ,(00023, ErDifferentLength) // Leo
   ,(00024, ErFieldIsHidden) // Leo
   ,(00025, ErInvalidTypeCast) // Leo
   ,(00026, ErInvalidTypeCastName) // Leo
   ,(00027, ErBothJoinAOEqual) // Leo
   ,(00028, ErInvalidType) // Leo
   ,(00029, ErInvalidTypeName) // Leo
   ,(00030, ErEqualRecordsInJoins) // Leo
   ,(00031, ErFieldIsHidden) // Leo
   ,(00032, ErDistinctIndexNotCreated) // Leo
   ,(00033, ErCannotFindField) // Leo
   ,(00034, ErAmbiguousFieldReference) // Leo
   ,(00035, ErDifferentLength) // Leo
   ,(00036, ErArrayIsEmpty) // Leo
   ,(00037, ErArrayIsEmpty) // Leo
   ,(00038, ErInvalidTypeCastName) // Leo
   ,(00039, ErInvalidTypeName) // Leo
   ,(00040, ErInvalidUnionType) // Leo
   ,(00041, ErInvalidFieldNo) // Leo
   ,(00042, ErInvalidFieldNo) // Leo
   ,(00043, ErInvalidFieldName) // Leo
   ,(00044, ErInvalidNumericSymbol) // Leo
   ,(00045, ErInvalidFieldNo) // Leo
   ,(00046, ErInvalidJoinField) // Leo
   ,(00047, ErInvalidFilterExpressionType) // Leo
   ,(00048, ErFieldNotFound) // Leo
   ,(00049, ErFieldDoesNotIncludedInGroupByList) // Leo
   ,(00050, ErCannotOpenTable) // Leo
   ,(00051, ErInvalidTypeCast) // Leo
   ,(00052, ErInvalidType) // Leo
   ,(00053, ErNonAggregateFunctionInGroupBySelectList) // Leo
   ,(00054, ErInvalidFilterExpressionType) // Leo
   ,(00055, ErQueryComponentIsNil) // Leo
   ,(00056, ErSubQueryReturnsNoRows) // Leo
   ,(00057, ErSubQueryReturnsMultipleRows) // Leo
   ,(00058, ErQueryComponentIsNil) // Leo
   ,(00059, ErQueryComponentIsNil) // Leo
   ,(00060, ErNotFloatDataType) // Leo
   ,(00061, ErNotSmallIntDataType) // Leo
   ,(00062, ErNotLargeIntDataType) // Leo
   ,(00063, ErNotWordDataType) // Leo
   ,(00064, ErNoCorrelatedColumnsPassed) // Leo
   ,(00065, ErNoInColumn) // Leo
   ,(00066, ErArgumentExpected) // Leo
   ,(00067, ErRightParenthesisExpected) // Leo
   ,(00068, ErTypesMismatchesInSQLFunction) // Leo
   ,(00069, ErLeftParenthesisExpected) // Leo
   ,(00070, ErArgumentExpectedInSQLFunction) // Leo
   ,(00071, ErLeftParenthesisExpected) // Leo
   ,(00072, ErRightParenthesisExpected) // Leo
   ,(00073, ErArgumentExpected) // Leo
   ,(00074, ErLeftParenthesisExpected) // Leo
   ,(00075, ErFromOrCommaExpected) // Leo
   ,(00076, ErNoChildren) // Leo
   ,(00077, ErFieldNotFound) // Leo
   ,(00078, ErLeftParenthesisExpected) // Leo
   ,(00079, ErArgumentExpected) // Leo
   ,(00080, ErRightParenthesisExpected) // Leo
   ,(00081, ErOtherTokenExpected)
   ,(00082, ErArgumentExpected) // Leo
   ,(00083, ErArgumentExpected) // Leo
   ,(00084, ErArgumentExpected) // Leo
   ,(00085, ErOtherTokenExpected)
   ,(00086, ErArgumentExpected) // Leo

   ,(01001, ErBlankSQLCommand) // Andrew
   ,(01002, ErBlankSQLCommand) // Andrew
   ,(01003, ErSQLCommandExpected) // Andrew
   ,(01004, ErBlankSQLCommand) // Andrew
   ,(01005, ErSQLCommandExpected) // Andrew
   ,(01006, ErUnexpectedToken) // Andrew
   ,(01007, ErUnexpectedToken) // Andrew
   ,(01008, ErUnexpectedEndOfCommand) // Andrew
   ,(01009, ErFieldNameExpected) // Andrew
   ,(01010, ErFieldPseudonymExpected) // Andrew
   ,(01011, ErFieldNameExpected) // Andrew
   ,(01012, ErTableNameExpected) // Andrew
   ,(01013, ErTableNameExpected) // Andrew
   ,(01014, ErFromExpected) // Andrew
   ,(01015, ErTableNameExpected) // Andrew
   ,(01016, ErTableNameExpected) // Andrew
   ,(01017, ErFieldListExpected) // Andrew
   ,(01018, ErFieldPseudonymExpected) // Andrew
   ,(01019, ErTableNameExpected) // Andrew
   ,(01020, ErTableNameExpected) // Andrew
   ,(01021, ErFieldNameExpected) // Andrew
   ,(01022, ErFieldNameExpected) // Andrew
   ,(01023, ErUnexpectedToken) // Andrew
   ,(01024, ErOtherTokenExpected) // Andrew
   ,(01025, ErUnexpectedToken) // Andrew
   ,(01026, ErUnexpectedToken) // Andrew
   ,(01027, ErUnexpectedToken) // Andrew
   ,(01028, ErUnexpectedToken) // Andrew
   ,(01029, ErUnexpectedToken) // Andrew
   ,(01030, ErUnexpectedToken) // Andrew
   ,(01031, ErUnexpectedToken) // Andrew
   ,(01032, ErTableNameExpected) // Andrew
   ,(01033, ErOtherTokenExpected) // Andrew
   ,(01034, ErUnexpectedToken) // Andrew
   ,(01035, ErFieldNameExpected) // Andrew
   ,(01036, ErFieldNameExpected) // Andrew
   ,(01037, ErBooleanExpressionExpected) // Andrew
   ,(01038, ErBooleanExpressionExpected) // Andrew
   ,(01039, ErUnexpectedEndOfCommand) // Andrew
   ,(01040, ErBooleanExpressionExpected) // Andrew
   ,(01041, ErBooleanExpressionExpected) // Andrew
   ,(01042, ErUnexpectedToken) // Andrew
   ,(01043, ErUnexpectedToken) // Andrew
   ,(01044, ErOtherTokenExpected) // Andrew
   ,(01045, ErOtherTokenExpected) // Andrew
   ,(01046, ErUnexpectedToken) // Andrew
   ,(01047, ErSortSpecificationExpected) // Andrew
   ,(01048, ErSortSpecificationExpected) // Andrew
   ,(01049, ErFieldNameExpected) // Andrew
   ,(01050, ErUnexpectedToken) // Andrew
   ,(01051, ErColumnFromOrderByNotFound) // Andrew
   ,(01052, ErCannotFindField) // Andrew
   ,(01053, ErUnsupportedOperator) // Andrew
   ,(01054, ErAmbiguousFieldReference) // Andrew
   ,(01055, ErAmbiguousFieldReference) // Andrew
   ,(01056, ErCircularDataLink) // Andrew
   ,(01057, ErAmbiguousFieldReference) // Andrew
   ,(01058, ErQuotedPasswordDataExpected) // Andrew
   ,(01059, ErSQLCommandExpected) // Andrew
   ,(01060, ErOtherTokenExpected) // Andrew
   ,(01061, ErOtherTokenExpected) // Andrew
   ,(01062, ErNodeIsNotField) // Andrew
   ,(01063, ErOtherTokenExpected) // Andrew
   ,(01064, ErFieldNameExpected) // Andrew
   ,(01065, ErFieldNameExpected) // Andrew
   ,(01066, ErFieldNameExpected) // Andrew
   ,(01067, ErCannotSetIndexWithField) // Andrew
   ,(01068, ErNoCursorInQuery) // Andrew
   ,(01069, ErNotApplicableCondition) // Andrew
   ,(01070, ErExprValue) // Andrew
   ,(01071, ErInvalidFilterExpressionType) // Andrew
   ,(01072, ErInvalidSessionName) // Andrew
   ,(01073, ErSessionActive) // Andrew
   ,(01074, ErAutoSessionActive) // Andrew
   ,(01075, ErDuplicateSessionName) // Andrew
   ,(01076, ErSessionNameMissing) // Andrew
   ,(01077, ErEngineNotInitialized) // Andrew
   ,(01078, ErAutoSessionExclusive) // Andrew
   ,(01079, ErAutoSessionExists) // Andrew
   ,(01080, ErDatabaseOpen) // Andrew
   ,(01081, ErDatabaseNameMissing) // Andrew
   ,(01082, ErDuplicateDatabaseName) // Andrew
   ,(01083, ErDatabaseClosed) // Andrew
   ,(01084, ErDatabaseHandleSet) // Andrew
   ,(01085, ErNotEditing) // Andrew
   ,(01086, ErNotIndexField) // Andrew
   ,(01087, ErDBMHandleIsNil) // Andrew
   ,(01088, ErCannotCreateHandle) // Andrew
   ,(01089, ErVisibleRecordsError) // Andrew
   ,(01090, ErExpressionExpected) // Andrew
   ,(01091, ErIntegerExpected) // Andrew
   ,(01092, ErIntegerExpected) // Andrew
   ,(01093, ErDuplicateTablePseudonym) // Andrew
   ,(01094, -1) // Andrew

   ,(02000, ErNonInsertCommand) // George
   ,(02001, ErUnexpectedEndOfCommand) // George
   ,(02002, ErTableOrIndexKeywordExpected) // George
   ,(02003, ErTableNameExpected) // George
   ,(02004, ErLeftParenthesisExpected) // George
   ,(02005, ErFieldNameExpected) // George
   ,(02006, ErFieldTypeExpected) // George
   ,(02007, ErUnknownFileldType) // George
   ,(02008, ErLeftParenthesisExpected) // George
   ,(02009, ErDecimalConstantExpected) // George
   ,(02010, ErRightParenthesisExpected) // George
   ,(02011, ErNullKeywordExpected) // George
   ,(02012, ErUnexpectedEndOfCommand) // George
   ,(02013, ErUnexpectedEndOfCommand) // George
   ,(02014, ErErrorCreatingTable) // George
   ,(02015, ErUnexpectedToken) // George
   ,(02016, ErQuotedPasswordDataExpected) // George
   ,(02017, ErRightParenthesisOrCommaExpected) // George
   ,(02018, ErUnexpectedEndOfCommand) // George
   ,(02019, ErBlobCompressionLevelValueExpected) // George
   ,(02020, ErUnknownCompressLevel) // George
   ,(02021, ErRightParenthesisOrCommaExpected)
   ,(02022, ErUnexpectedEndOfCommand)
   ,(02023, ErDecimalConstantExpected)
   ,(02024, ErRightParenthesisOrCommaExpected)
   ,(02025, ErUnexpectedEndOfCommand)
   ,(02026, ErDecimalConstantExpected)
   ,(02027, ErRightParenthesisOrCommaExpected)
   ,(02028, ErUnexpectedEndOfCommand)
   ,(02029, ErUnexpectedEndOfCommand)
   ,(02030, ErBlankSQLCommand)
   ,(02031, ErTableNameExpected)
   ,(02032, ErUnexpectedToken)
   ,(02033, ErDroppingTable)
   ,(02034, ErUnexpectedToken)
   ,(02035, ErTableOrIndexKeywordExpected)
   ,(02036, ErUnexpectedEndOfCommand)
   ,(02037, ErBlankSQLCommand)
   ,(02038, ErTableNameExpected)
   ,(02039, ErBlankSQLCommand)
   ,(02040, ErAddOrDropOrModifyKeywordExpected)
   ,(02041, ErAddOrDropOrModifyKeywordExpected)
   ,(02042, ErUnexpectedEndOfCommand)
   ,(02043, ErUnexpectedToken)
   ,(02044, ErRightParenthesisOrCommaExpected)
   ,(02045, ErNewDataTypeOrNotNullExpected)
   ,(02046, ErPasswordKeywordExpected)
   ,(02047, ErDroppingColumns)
   ,(02048, ErCannotFindField)
   ,(02049, ErUnexpectedToken)
   ,(02050, ErUnexpectedToken) 
   ,(02051, ErBlankSQLCommand)
   ,(02052, ErIndexKeywordExpected)
   ,(02053, ErIndexNameExpected)
   ,(02054, ErOnKeywordExpected)
   ,(02055, ErTableNameExpected)
   ,(02056, ErLeftParenthesisExpected)
   ,(02057, ErFieldNameExpected)
   ,(02058, ErUnexpectedEndOfCommand)
   ,(02059, ErQuotedPasswordDataExpected)
   ,(02060, ErUnexpectedEndOfCommand)
   ,(02061, ErUnexpectedToken)
   ,(02062, ErUnexpectedToken)
   ,(02063, ErUnexpectedEndOfCommand)
   ,(02064, ErOtherTokenExpected)
   ,(02065, ErUnexpectedEndOfCommand)
   ,(02066, ErQuotedPasswordDataExpected)
   ,(02067, ErUnexpectedToken)
   ,(02068, ErUnexpectedToken)
   ,(02069, ErUnexpectedToken)
   ,(02070, ErBlankSQLCommand)
   ,(02071, ErIntoKeywordExpected)
   ,(02072, ErTableNameExpected)
   ,(02073, ErUnexpectedEndOfCommand)
   ,(02074, ErRightParenthesisOrCommaExpected)
   ,(02075, ErUnexpectedEndOfCommand)
   ,(02076, ErUnexpectedEndOfCommand)
   ,(02077, ErLeftParenthesisExpected)
   ,(02078, ErInsertFromTheTableToItSelf)
   ,(02079, ErUnexpectedEndOfCommand)
   ,(02080, ErQuotedPasswordDataExpected)
   ,(02081, ErUnexpectedToken)
   ,(02082, ErBlankSQLCommand)
   ,(02083, ErTableNameExpected)
   ,(02084, ErQuotedPasswordDataExpected)
   ,(02085, ErSetKeywordExpected)
   ,(02086, ErEqualExpected)
   ,(02087, ErUnexpectedEndOfCommand)
   ,(02088, ErOtherTokenExpected)
   ,(02089, ErNotnumericArgument)
   ,(02090, ErNotnumericArgument)
   ,(02091, ErNotnumericArgument)
   ,(02092, ErCantConvertTypeFromTo)
   ,(02093, ErCantConvertTypeFromTo)
   ,(02094, ErLeftParenthesisExpected)
   ,(02095, ErRightParenthesisExpected)
   ,(02096, ErStringArgumentExpected)
   ,(02097, ErNotStringArgument)
   ,(02098, ErNotStringArgument)
   ,(02099, ErNotStringArgument)
   ,(02100, ErNotStringArgument)
   ,(02101, ErNotStringArgument)
   ,(02102, ErNotStringArgument)
   ,(02103, ErRightParenthesisExpected)
   ,(02104, ErLeftParenthesisExpected)
   ,(02105, ErArgumentExpected)
   ,(02106, ErRightParenthesisExpected)
   ,(02107, ErNotIntegerDataType)
   ,(02108, ErCannotFindField)
   ,(02109, ErNotnumericArgument)
   ,(02110, ERInvalidFieldName)
   ,(02111, ErRightParenthesisExpected)
   ,(02112, ERInvalidFieldName)
   ,(02113, ErNotBooleanDataType)
   ,(02114, ErNotStringArgument)
   ,(02115, ErNotApplicableCastType)
   ,(02116, ErRightParenthesisExpected)
   ,(02117, ErTableAlreadyExists)
   ,(02118, ErLeftParenthesisExpected)
   ,(02119, ErFieldNameExpected)
   ,(02120, ErRightParenthesisOrCommaExpected)
   ,(02121, ErNotStringArgument)
   ,(02122, ErNotStringArgument)
   ,(02123, ErNotStringArgument)
   ,(02124, ErNotStringArgument)
   ,(02125, ErNotStringArgument)
   ,(02126, ErLeftParenthesisExpected)
   ,(02127, ErArgumentExpected)
   ,(02128, ErOtherTokenExpected)
   ,(02129, ErArgumentExpected)
   ,(02130, ErOtherTokenExpected)
   ,(02131, ErRightParenthesisExpected)
   ,(02132, ErLeftParenthesisExpected)
   ,(02133, ErRightParenthesisExpected)
   ,(02134, ErArgumentExpected)
   ,(02135, ErOtherTokenExpected)
   ,(02136, ErArgumentExpected)
   ,(02137, ErLeftParenthesisExpected)
   ,(02138, ErArgumentExpected)
   ,(02139, ErRightParenthesisExpected)
   ,(02140, ErNotDateTimeDataType)
   ,(02141, ErArgumentExpected)
   ,(02142, ErLeftParenthesisExpected)
   ,(02143, ErOtherTokenExpected)
   ,(02144, ErConstDateFormatExpected)
   ,(02145, ErRightParenthesisExpected)
   ,(02146, ErAMPMKeyWordExpected)
   ,(02147, ErLeftParenthesisExpected)
   ,(02148, ErArgumentExpected)
   ,(02149, ErOtherTokenExpected)
   ,(02150, ErTableNameExpected)
   ,(02151, ErTableNameExpected)
   ,(02152, ErTableNameExpected)
   ,(02153, ErQuotedPasswordDataExpected)
   ,(02154, ErRightParenthesisExpected)
   ,(02155, ErLeftParenthesisExpected)
   ,(02156, ErFieldNameExpected)
   ,(02157, ErAutoIncUniquenessViolation)
   ,(02158, ErAutoIncUniquenessViolation)
   ,(02159, ErAutoIncUniquenessViolation)
   ,(02160, ErTableNameExpected)
   ,(02161, ErUnexpectedEndOfCommand)
  );


type
  TReservedWord =
  (
   rwABSOLUTE
   ,rwACTION
   ,rwADD
   ,rwALL
   ,rwALLOCATE
   ,rwALTER
   ,rwAND
   ,rwANY
   ,rwARE
   ,rwAS
   ,rwASC
   ,rwASSERTION
   ,rwAT
   ,rwAUTHORIZATION
   ,rwAVG
   ,rwBEGIN
   ,rwBETWEEN
   ,rwBIT
   ,rwBIT_LENGTH
   ,rwBOTH
   ,rwBY
   ,rwCASCADE
   ,rwCASCADED
   ,rwCASE
   ,rwCAST
   ,rwCATALOG
   ,rwCHAR
   ,rwCHARACTER
   ,rwCHAR_LENGTH
   ,rwCHARACTER_LENGTH
   ,rwCHECK
   ,rwCLOSE
   ,rwCOALESCE
   ,rwCOLLATE
   ,rwCOLLATION
   ,rwCOLUMN
   ,rwCOMMIT
   ,rwCONNECT
   ,rwCONNECTION
   ,rwCONSTRAINT
   ,rwCONSTRAINTS
   ,rwCONTINUE
   ,rwCONVERT
   ,rwCORRESPONDING
   ,rwCOUNT
   ,rwCREATE
   ,rwCROSS
   ,rwCURRENT
   ,rwCURRENT_DATE
   ,rwCURRENT_TIME
   ,rwCURRENT_TIMESTAMP
   ,rwCURRENT_USER
   ,rwCURSOR
   ,rwDATE
   ,rwDAY
   ,rwDEALLOCATE
   ,rwDEC
   ,rwDECIMAL
   ,rwDECLARE
   ,rwDEFAULT
   ,rwDEFERRABLE
   ,rwDEFERRED
   ,rwDELETE
   ,rwDESC
   ,rwDESCRIBE
   ,rwDESCRIPTOR
   ,rwDIAGNOSTICS
   ,rwDISCONNECT
   ,rwDISTINCT
   ,rwDOMAIN
   ,rwDOUBLE
   ,rwDROP
   ,rwELSE
   ,rwEND
   ,rwEND_EXEC
   ,rwESCAPE
   ,rwEXCEPT
   ,rwEXCEPTION
   ,rwEXEC
   ,rwEXECUTE
   ,rwEXISTS
   ,rwEXTERNAL
   ,rwEXTRACT
   ,rwFALSE
   ,rwFETCH
   ,rwFIRST
   ,rwFLOAT
   ,rwFOR
   ,rwFOREIGN
   ,rwFOUND
   ,rwFROM
   ,rwFULL
   ,rwGET
   ,rwGLOBAL
   ,rwGO
   ,rwGOTO
   ,rwGRANT
   ,rwGROUP
   ,rwHAVING
   ,rwHOUR
   ,rwIDENTITY
   ,rwIMMEDIATE
   ,rwIN
   ,rwINDICATOR
   ,rwINITIALLY
   ,rwINNER
   ,rwINPUT
   ,rwINSENSITIVE
   ,rwINSERT
   ,rwINT
   ,rwINTEGER
   ,rwINTERSECT
   ,rwINTERVAL
   ,rwINTO
   ,rwIS
   ,rwISNULL
   ,rwISOLATION
   ,rwJOIN
   ,rwKEY
   ,rwLANGUAGE
   ,rwLAST
   ,rwLEADING
   ,rwLEFT
   ,rwLEVEL
   ,rwLIKE
   ,rwLOCAL
   ,rwLOWER
   ,rwMATCH
   ,rwMAX
   ,rwMEMORY
   ,rwMIN
   ,rwMINUS
   ,rwMINUTE
   ,rwMODULE
   ,rwMONTH
   ,rwNAMES
   ,rwNATIONAL
   ,rwNATURAL
   ,rwNCHAR
   ,rwNEXT
   ,rwNO
   ,rwNOT
   ,rwNULL
   ,rwNULLIF
   ,rwNUMERIC
   ,rwOCTET_LENGTH
   ,rwOF
   ,rwON
   ,rwONLY
   ,rwOPEN
   ,rwOPTION
   ,rwOR
   ,rwORDER
   ,rwOUTER
   ,rwOUTPUT
   ,rwOVERLAPS
   ,rwPAD
   ,rwPARTIAL
   ,rwPOSITION
   ,rwPRECISION
   ,rwPREPARE
   ,rwPRESERVE
   ,rwPRIMARY
   ,rwPRIOR
   ,rwPRIVILEGES
   ,rwPROCEDURE
   ,rwPUBLIC
   ,rwREAD
   ,rwREAL
   ,rwREFERENCES
   ,rwRELATIVE
   ,rwRESTRICT
   ,rwREVOKE
   ,rwRIGHT
   ,rwROLLBACK
   ,rwROWS
   ,rwSCHEMA
   ,rwSCROLL
   ,rwSECOND
   ,rwSECTION
   ,rwSELECT
   ,rwSESSION
   ,rwSESSION_USER
   ,rwSET
   ,rwSIZE
   ,rwSMALLINT
   ,rwSOME
   ,rwSPACE
   ,rwSQL
   ,rwSQLCODE
   ,rwSQLERROR
   ,rwSQLSTATE
   ,rwSUBSTRING
   ,rwSUM
   ,rwSYSTEM_USER
   ,rwTABLE
   ,rwTEMPORARY
   ,rwTHEN
   ,rwTIME
   ,rwTIMESTAMP
   ,rwTIMEZONE_HOUR
   ,rwTIMEZONE_MINUTE
   ,rwTO
   ,rwTOP
   ,rwTRAILING
   ,rwTRANSACTION
   ,rwTRANSLATE
   ,rwTRANSLATION
   ,rwTRIM
   ,rwTRUE
   ,rwUNION
   ,rwUNIQUE
   ,rwUNKNOWN
   ,rwUPDATE
   ,rwUPPER
   ,rwUSAGE
   ,rwUSER
   ,rwUSING
   ,rwVALUE
   ,rwVALUES
   ,rwVARCHAR
   ,rwVARYING
   ,rwVIEW
   ,rwWHEN
   ,rwWHENEVER
   ,rwWHERE
   ,rwWITH
   ,rwWORK
   ,rwWRITE
   ,rwYEAR
   ,rwZONE
   ,rwPASSWORD                // for DDL commands
   ,rwBLOB_COMPRESSION_LEVEL  // for DDL commands
   ,rwBLOB_BLOCK_SIZE         // for DDL commands
   ,rwLAST_AUTOINC            // for DDL commands
   ,rwMODIFY                  // alter table blablabla modify ...
   ,rwNEW                     // for NEW PASSWORD in ALTER TABLE
   ,rwINDEX                   // for CREATE INDEX ...
   ,rwNOCASE                  // for CREATE INDEX ... NOCASE
   ,rwLTRIM
   ,rwRTRIM
   ,rwPOS
   ,rwLENGTH
   ,rwSYSDATE
   ,rwNOW
   ,rwTODATE
   ,rwTOSTRING
   ,rwAUTOINDEXES
   ,rwNOAUTOINDEXES
   ,rwQUARTER
   ,rwWEEKDAY
   ,rwDAYOFWEEK
   ,rwDAYNAME
   ,rwMONTHNAME
   ,rwMSECOND
   ,rwABS
   ,rwCEILING
   ,rwCEIL
   ,rwFLOOR
   ,rwMOD
   ,rwPOWER
   ,rwPOW
   ,rwRANDOM
   ,rwRAND
   ,rwROUND
   ,rwSIGN
   ,rwTRUNCATE
   ,rwTRUNC
   ,rwSHL
   ,rwSHR
   ,rwXOR
   ,rwHEX
   ,rwNone
  );

const
  ETblMaxSQLReservedWords = 271;
  ETblSQLReservedWords: array[0..ETblMaxSQLReservedWords] of String =
  (
   'ABSOLUTE'
   ,'ACTION'
   ,'ADD'
   ,'ALL'
   ,'ALLOCATE'
   ,'ALTER'
   ,'AND'
   ,'ANY'
   ,'ARE'
   ,'AS'
   ,'ASC'
   ,'ASSERTION'
   ,'AT'
   ,'AUTHORIZATION'
   ,'AVG'
   ,'BEGIN'
   ,'BETWEEN'
   ,'BIT'
   ,'BIT_LENGTH'
   ,'BOTH'
   ,'BY'
   ,'CASCADE'
   ,'CASCADED'
   ,'CASE'
   ,'CAST'
   ,'CATALOG'
   ,'CHAR'
   ,'CHARACTER'
   ,'CHAR_LENGTH'
   ,'CHARACTER_LENGTH'
   ,'CHECK'
   ,'CLOSE'
   ,'COALESCE'
   ,'COLLATE'
   ,'COLLATION'
   ,'COLUMN'
   ,'COMMIT'
   ,'CONNECT'
   ,'CONNECTION'
   ,'CONSTRAINT'
   ,'CONSTRAINTS'
   ,'CONTINUE'
   ,'CONVERT'
   ,'CORRESPONDING'
   ,'COUNT'
   ,'CREATE'
   ,'CROSS'
   ,'CURRENT'
   ,'CURRENT_DATE'
   ,'CURRENT_TIME'
   ,'CURRENT_TIMESTAMP'
   ,'CURRENT_USER'
   ,'CURSOR'
   ,'DATE'
   ,'DAY'
   ,'DEALLOCATE'
   ,'DEC'
   ,'DECIMAL'
   ,'DECLARE'
   ,'DEFAULT'
   ,'DEFERRABLE'
   ,'DEFERRED'
   ,'DELETE'
   ,'DESC'
   ,'DESCRIBE'
   ,'DESCRIPTOR'
   ,'DIAGNOSTICS'
   ,'DISCONNECT'
   ,'DISTINCT'
   ,'DOMAIN'
   ,'DOUBLE'
   ,'DROP'
   ,'ELSE'
   ,'END'
   ,'END-EXEC'
   ,'ESCAPE'
   ,'EXCEPT'
   ,'EXCEPTION'
   ,'EXEC'
   ,'EXECUTE'
   ,'EXISTS'
   ,'EXTERNAL'
   ,'EXTRACT'
   ,'FALSE'
   ,'FETCH'
   ,'FIRST'
   ,'FLOAT'
   ,'FOR'
   ,'FOREIGN'
   ,'FOUND'
   ,'FROM'
   ,'FULL'
   ,'GET'
   ,'GLOBAL'
   ,'GO'
   ,'GOTO'
   ,'GRANT'
   ,'GROUP'
   ,'HAVING'
   ,'HOUR'
   ,'IDENTITY'
   ,'IMMEDIATE'
   ,'IN'
   ,'INDICATOR'
   ,'INITIALLY'
   ,'INNER'
   ,'INPUT'
   ,'INSENSITIVE'
   ,'INSERT'
   ,'INT'
   ,'INTEGER'
   ,'INTERSECT'
   ,'INTERVAL'
   ,'INTO'
   ,'IS'
   ,'ISNULL'
   ,'ISOLATION'
   ,'JOIN'
   ,'KEY'
   ,'LANGUAGE'
   ,'LAST'
   ,'LEADING'
   ,'LEFT'
   ,'LEVEL'
   ,'LIKE'
   ,'LOCAL'
   ,'LOWER'
   ,'MATCH'
   ,'MAX'
   ,'MEMORY'
   ,'MIN'
   ,'MINUS'
   ,'MINUTE'
   ,'MODULE'
   ,'MONTH'
   ,'NAMES'
   ,'NATIONAL'
   ,'NATURAL'
   ,'NCHAR'
   ,'NEXT'
   ,'NO'
   ,'NOT'
   ,'NULL'
   ,'NULLIF'
   ,'NUMERIC'
   ,'OCTET_LENGTH'
   ,'OF'
   ,'ON'
   ,'ONLY'
   ,'OPEN'
   ,'OPTION'
   ,'OR'
   ,'ORDER'
   ,'OUTER'
   ,'OUTPUT'
   ,'OVERLAPS'
   ,'PAD'
   ,'PARTIAL'
   ,'POSITION'
   ,'PRECISION'
   ,'PREPARE'
   ,'PRESERVE'
   ,'PRIMARY'
   ,'PRIOR'
   ,'PRIVILEGES'
   ,'PROCEDURE'
   ,'PUBLIC'
   ,'READ'
   ,'REAL'
   ,'REFERENCES'
   ,'RELATIVE'
   ,'RESTRICT'
   ,'REVOKE'
   ,'RIGHT'
   ,'ROLLBACK'
   ,'ROWS'
   ,'SCHEMA'
   ,'SCROLL'
   ,'SECOND'
   ,'SECTION'
   ,'SELECT'
   ,'SESSION'
   ,'SESSION_USER'
   ,'SET'
   ,'SIZE'
   ,'SMALLINT'
   ,'SOME'
   ,'SPACE'
   ,'SQL'
   ,'SQLCODE'
   ,'SQLERROR'
   ,'SQLSTATE'
   ,'SUBSTRING'
   ,'SUM'
   ,'SYSTEM_USER'
   ,'TABLE'
   ,'TEMPORARY'
   ,'THEN'
   ,'TIME'
   ,'TIMESTAMP'
   ,'TIMEZONE_HOUR'
   ,'TIMEZONE_MINUTE'
   ,'TO'
   ,'TOP'
   ,'TRAILING'
   ,'TRANSACTION'
   ,'TRANSLATE'
   ,'TRANSLATION'
   ,'TRIM'
   ,'TRUE'
   ,'UNION'
   ,'UNIQUE'
   ,'UNKNOWN'
   ,'UPDATE'
   ,'UPPER'
   ,'USAGE'
   ,'USER'
   ,'USING'
   ,'VALUE'
   ,'VALUES'
   ,'VARCHAR'
   ,'VARYING'
   ,'VIEW'
   ,'WHEN'
   ,'WHENEVER'
   ,'WHERE'
   ,'WITH'
   ,'WORK'
   ,'WRITE'
   ,'YEAR'
   ,'ZONE'
   ,'PASSWORD'              // for DDL commands
   ,'BLOBCOMPRESSIONLEVEL'  // for DDL commands
   ,'BLOBBLOCKSIZE'         // for DDL commands
   ,'LASTAUTOINC'           // for DDL commands
   ,'MODIFY'                // alter table blablabla modify ...
   ,'NEW'                   // for NEW PASSWORD in ALTER TABLE
   ,'INDEX'                 // for CREATE INDEX ...
   ,'NOCASE'                // for CREATE INDEX ... NOCASE ..
   ,'LTRIM'
   ,'RTRIM'
   ,'POS'
   ,'LENGTH'
   ,'SYSDATE'
   ,'NOW'
   ,'TODATE'
   ,'TOSTRING'
   ,'AUTOINDEXES'
   ,'NOAUTOINDEXES'
   ,'QUARTER'
   ,'WEEKDAY'
   ,'DAYOFWEEK'
   ,'DAYNAME'
   ,'MONTHNAME'
   ,'MSECOND'
// new 6.30
   ,'ABS'
   ,'CEILING'
   ,'CEIL'
   ,'FLOOR'
   ,'MOD'
   ,'POWER'
   ,'POW'
   ,'RANDOM'
   ,'RAND'
   ,'ROUND'
   ,'SIGN'
   ,'TRUNCATE'
   ,'TRUNC'
   ,'SHL'
   ,'SHR'
   ,'XOR'
   ,'HEX'
  );

implementation

end.
