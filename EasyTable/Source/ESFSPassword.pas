//==============================================================================
// Product name: Password routines
// Copyright 2001 AidAim Software.
// Description:
//  Password routines.
// Version: 1.00
// Date: 08/20/2001
//==============================================================================

unit ESFSPassword;

{$I ESFSVer.inc}

{DEFINE DEBUG_FLAG}

interface

uses classes, sysutils, windows,
{$IFDEF DEBUG_FLAG}
     aaDebug,
{$ENDIF}
     ESFSDECUtil, ESFSCipher,  ESFSCipher1, ESFSRng;

const MAX_PASSWORD_LENGTH = 32;
const MAX_QUESTION_LENGTH = 100;
      // Crc algrorithms
      crcFast = 0;
      crcFull = 1;
const QUESTION_MASK = 'aFD:S.<@#Q$^562dg';

type
      TPasswordHeader = packed record
       Key:    		array [0..MAX_PASSWORD_LENGTH - 1] of AnsiChar; //
       Pass:   		array [0..MAX_PASSWORD_LENGTH - 1] of AnsiChar; //
       KeyCRC: 		Cardinal; // checksum for key
       PassCRC: 	Cardinal; // checksum for pass
       Question:	array [0..MAX_QUESTION_LENGTH-1] of AnsiChar; // control question
      end; //172 bytes

 procedure GenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);

 // calculate CRC (mode=0 - fast, 1 - full)
 function CountCRC(buffer: PAnsiChar; size: integer; mode: byte): Cardinal;

 // check crc - true if calculted CRC = specified
 function CheckCRC(buffer: PAnsiChar; size: integer; mode: byte; CRC: Cardinal): boolean;

 // create password header; if question not specified recovery of lost password
 // will not be available
 procedure CreatePasswordHeader(var PasswordHeader: TPasswordHeader; Password: AnsiString;
 					 Question: AnsiString = '';
 					 Answer: AnsiString = ''
           );
 // returns true if password is valid; Key - decoded key value
 function CheckPassword(PasswordHeader: TPasswordHeader; Password: AnsiString; var Key: AnsiString): Boolean;
 // returns true if answer is valid; Password - recovered password
 function CheckAnswer(PasswordHeader: TPasswordHeader; Answer: AnsiString; var Password: AnsiString): Boolean;
 // returns decrypted control question
 function DecryptQuestion(PasswordHeader: TPasswordHeader): AnsiString;

implementation


//------------------------------------------------------------------------------
// generate random buffer
//------------------------------------------------------------------------------
procedure GenerateRandomBuffer(Buffer: PAnsiChar; BufferSize: Integer);
var rng:  TRandom;
    size: Integer;

 function GenRndAnsiString(Len: Integer): AnsiString;
 var i: Integer;
 begin
  Result := '';
  for i := 1 to Len do
   Result := Result + Chr(Random(MaxInt) mod 255+1);
 end;

begin
 Size := 100;
 rng := TRandom_LFSR.Create(GenRndAnsiString(Size),2032,False,nil);
 try
   rng.Seed('',-1);
   rng.Buffer(Buffer^,BufferSize);
 finally
   rng.Free;
 end;
end; // GenerateRandomBuffer


//------------------------------------------------------------------------------
// calculate CRC (mode=0 - fast, 1 - full)
//------------------------------------------------------------------------------
function CountCRC(buffer: PAnsiChar; size: integer; mode: byte): Cardinal;
var
  i,x: Cardinal;
begin
 case mode of
  crcFast:
      begin
       i := 0;
       result := 0;
       x := size shr 2;
       while i < x do
        begin
         Result := Result xor pInteger(buffer + (i shl 2))^;
         inc(i);
        end;
      end;
  crcFull:  result := ESFSDecUtil.CRC16(0, buffer, size);
  else
   result := 0;
 end;
end;// CountCRC


//------------------------------------------------------------------------------
// check crc - true if calculted CRC = specified
//------------------------------------------------------------------------------
function CheckCRC(buffer: PAnsiChar; size: integer; mode: byte; CRC: Cardinal): boolean;
var
  i,x,res: Cardinal;
begin
 case mode of
  crcFast:
      begin
       i := 0;
       res := 0;
       x := (size shr 2);
       while i < x do
        begin
         Res := Res xor pInteger(buffer + (i shl 2))^;
         inc(i);
        end;
       result := (res = CRC);
      end;
  crcFull:  result := ESFSDecUtil.CRC16(0, buffer, size) = CRC;
  else
   result := true;
 end;
end;// CheckCRC


//------------------------------------------------------------------------------
// create password header; if question not specified recovery of lost password
// will not be available
//------------------------------------------------------------------------------
procedure CreatePasswordHeader(var PasswordHeader: TPasswordHeader; Password: AnsiString;
 					 Question: AnsiString = '';
 					 Answer: AnsiString = ''
					);
var key:  	PAnsiChar;
    crypto: TCipher_Rijndael;
begin
 if (Length(Password) > MAX_PASSWORD_LENGTH) then
  raise Exception.Create('Password length should be shorter then '+IntToStr(MAX_PASSWORD_LENGTH));
 if (Length(Question) > MAX_QUESTION_LENGTH) then
  raise Exception.Create('Question length should be shorter then '+IntToStr(MAX_QUESTION_LENGTH));
 // generate random key
 key := AllocMem(MAX_PASSWORD_LENGTH);
 GenerateRandomBuffer(key,MAX_PASSWORD_LENGTH);
 FillChar(PasswordHeader,sizeof(PasswordHeader),$00);
 // calculate key crc
 PasswordHeader.KeyCRC := CountCRC(key,MAX_PASSWORD_LENGTH,crcFull);
 // encode key by password
 crypto := TCipher_Rijndael.Create(Password,nil);
 crypto.EncodeBuffer(key^,PasswordHeader.Key,MAX_PASSWORD_LENGTH);
 crypto.Free;
 if (Question = '') or (Answer = '') then
  begin
   PasswordHeader.Pass[0] := #0;
   PasswordHeader.PassCRC := 0;
  end
 else
  begin
   Move(pAnsiChar(Question)^,PasswordHeader.Question,Length(Question));
   Move(pAnsiChar(Password)^,PasswordHeader.Pass,Length(Password));
   crypto := TCipher_Rijndael.Create(QUESTION_MASK, nil);
   crypto.EncodeBuffer(PasswordHeader.Question,PasswordHeader.Question,MAX_QUESTION_LENGTH);
   crypto.Free;
	 PasswordHeader.PassCRC := CountCRC(PasswordHeader.Pass,MAX_PASSWORD_LENGTH,crcFull);
   crypto := TCipher_Rijndael.Create(Answer,nil);
   crypto.EncodeBuffer(PasswordHeader.Pass,PasswordHeader.Pass,MAX_PASSWORD_LENGTH);
   crypto.Free;
  end;
 FreeMem(key);
end; //CreatePasswordHeader


//------------------------------------------------------------------------------
// returns true if password is valid; Key - decoded key value
//------------------------------------------------------------------------------
function CheckPassword(PasswordHeader: TPasswordHeader; Password: AnsiString; var Key: AnsiString): Boolean;
var
    crypto: TCipher_Rijndael;
begin
 result := false;
 if (Password = '') then
  Exit;
 SetLength(key,MAX_PASSWORD_LENGTH+1);
 Move(PasswordHeader.Key,pAnsiChar(key)^,MAX_PASSWORD_LENGTH);
 crypto := TCipher_Rijndael.Create(Password,nil);
 crypto.DecodeBuffer(pAnsiChar(key)^,pAnsiChar(key)^,MAX_PASSWORD_LENGTH);
 crypto.Free;
 if (PasswordHeader.KeyCRC = CountCRC(pAnsiChar(Key),MAX_PASSWORD_LENGTH,crcFull)) then
  result := true;
 pAnsiChar(pAnsiChar(Key)+MAX_PASSWORD_LENGTH)^ := #0;
end; // CheckPassword


//------------------------------------------------------------------------------
// returns true if answer is valid; Password - recovered password
//------------------------------------------------------------------------------
function CheckAnswer(PasswordHeader: TPasswordHeader; Answer: AnsiString; var Password: AnsiString): Boolean;
var i: Integer;
    crypto: TCipher_Rijndael;
    s: AnsiString;
begin
 result := false;
 if (Answer = '') then
  Exit;
 SetLength(s,MAX_PASSWORD_LENGTH+1);
 Move(PasswordHeader.Pass,pAnsiChar(s)^,MAX_PASSWORD_LENGTH);
 crypto := TCipher_Rijndael.Create(Answer,nil);
 crypto.DecodeBuffer(pAnsiChar(s)^,pAnsiChar(s)^,MAX_PASSWORD_LENGTH);
 crypto.Free;
 if (PasswordHeader.PassCRC = CountCRC(pAnsiChar(s),MAX_PASSWORD_LENGTH,crcFull)) then
  result := true;
 pAnsiChar(pAnsiChar(s)+MAX_PASSWORD_LENGTH)^ := #0;
 Password := '';
 for i := 0 to MAX_PASSWORD_LENGTH-1 do
  begin
   if (pAnsiChar(pAnsiChar(s) + i)^ = #0) then
    break;
   Password := Password + pAnsiChar(pAnsiChar(s)+i)^;
  end;
end; // CheckAnswer


// returns decrypted control question
function DecryptQuestion(PasswordHeader: TPasswordHeader): AnsiString;
var
    crypto: TCipher_Rijndael;
    key:			string;
begin
 SetLength(key, MAX_QUESTION_LENGTH);
 Move(PasswordHeader.Question, pAnsiChar(key)^, MAX_QUESTION_LENGTH);
 crypto := TCipher_Rijndael.Create(QUESTION_MASK, nil);
 crypto.DecodeBuffer(pAnsiChar(key)^,pAnsiChar(key)^,MAX_QUESTION_LENGTH);
 crypto.Free;
 pAnsiChar(pAnsiChar(Key)+MAX_QUESTION_LENGTH)^ := #0;
 Result := key;
end;// DecryptQuestion

initialization

Randomize;

end.
