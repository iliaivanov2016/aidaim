unit MsgBaseEngine;

{$I MsgVer.inc}

interface

uses
      SysUtils,
// MsgCommunicator units
     MsgMemory,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgCompression,
     MsgCrypto,
     MsgConst,
     MsgExcept,
     MsgTypes;


////////////////////////////////////////////////////////////////////////////////
//
// General functions and procedures
//
////////////////////////////////////////////////////////////////////////////////


 // compresses and encrypts buffer
 procedure CompressAndEncryptBuffer(
                        const CryptoInfo:     TMsgCryptoInfo;
                        CompressionAlgorithm: Byte;
                        CompressionMode:      Byte;
                        InBuffer:             PAnsiChar;
                        InSize:               Integer;
                        out OutBuffer:        PAnsiChar;
                        out OutSize:          Integer
                                   );
 // decompresses and decrypts buffer; return true if successful
 function DecompressAndDecryptBuffer(
                        const CryptoInfo:     TMsgCryptoInfo;
                        CompressionAlgorithm: Byte;
                        CompressionMode:      Byte;
                        var Buffer:           PAnsiChar;
                        var BufferSize:       Integer
                                                              ): Boolean;


implementation


//------------------------------------------------------------------------------
// compresses and encrypts buffer
//------------------------------------------------------------------------------
procedure CompressAndEncryptBuffer(
                        const CryptoInfo:     TMsgCryptoInfo;
                        CompressionAlgorithm: Byte;
                        CompressionMode:      Byte;
                        InBuffer:             PAnsiChar;
                        InSize:               Integer;
                        out OutBuffer:        PAnsiChar;
                        out OutSize:          Integer
                                  );
var
  ca:         TMsgCompressionAlgorithm1;
  Buffer:     PAnsiChar;
  BufferSize: Integer;
  NewSize:    Integer;
  CRC32:      Cardinal;
begin
  ca := TMsgCompressionAlgorithm1(CompressionAlgorithm); 
  if ((ca = acaNone) and (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None)) 
  or (InSize <= 0)
  or (InBuffer = nil) 
  then 
   begin 
    OutBuffer := InBuffer; 
    OutSize := InSize; 
    Exit;
   end;
 if (ca <> acaNone) then 
  begin
    if (not MsgInternalCompressBuffer(ca,CompressionMode,InBuffer,InSize,Buffer,BufferSize)) then
     raise EMsgException.Create(11632,ErrorLCannotCompressBuffer,[InSize,IntToHex(Integer(InBuffer),8),CompressionAlgorithm,CompressionMode]);
    try 
     if (Buffer <> nil) and (BufferSize > 0) then 
      begin
       if (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None) then
        begin 
              OutSize := BufferSize+SizeOf(BufferSize);
              OutBuffer := MemoryManager.GetMem(OutSize);
              Move(InSize,OutBuffer^,SizeOf(InSize));
              Move(Buffer^,PAnsiChar(OutBuffer+SizeOf(BufferSize))^,BufferSize); 
        end // no ecnryption 
       else
        begin 
              OutSize := BufferSize+SizeOf(CRC32)+SizeOf(BufferSize);
              OutBuffer := MemoryManager.GetMem(OutSize);
              Move(InSize,PAnsiChar(OutBuffer+SizeOf(CRC32))^,SizeOf(InSize)); 
              Move(Buffer^,PAnsiChar(OutBuffer+SizeOf(CRC32)+SizeOf(BufferSize))^,BufferSize);
              CRC32 := MsgCountCRC(0,PAnsiChar(OutBuffer+SizeOf(CRC32)),OutSize-SizeOf(CRC32));
              Move(CRC32,OutBuffer^,SizeOf(CRC32));
              MsgEncryptBuffer(CryptoInfo,PAnsiChar(OutBuffer+SizeOf(CRC32)),OutSize-SizeOf(CRC32)); 
        end; // encryption
      end;
    finally
     if (Buffer <> nil) then 
      FreeMem(Buffer); 
    end;
   end // compression with or without encryption 
  else 
   begin 
     OutSize := InSize+SizeOf(CRC32);
     OutBuffer := MemoryManager.GetMem(OutSize);
     CRC32 := MsgCountCRC(0,InBuffer,InSize);
     Move(CRC32,OutBuffer^,SizeOf(CRC32));
     Move(InBuffer^,PAnsiChar(OutBuffer+SizeOf(CRC32))^,InSize); 
     MsgEncryptBuffer(CryptoInfo,PAnsiChar(OutBuffer+SizeOf(CRC32)),InSize); 
   end; // encryption without compression
end; // CompressAndEncryptBuffer 
	
 
//------------------------------------------------------------------------------ 
// decompresses and decrypts buffer; return true if successful
//------------------------------------------------------------------------------
function DecompressAndDecryptBuffer(
                        const CryptoInfo:     TMsgCryptoInfo; 
                        CompressionAlgorithm: Byte; 
                        CompressionMode:      Byte; 
                        var Buffer:           PAnsiChar; 
                        var BufferSize:       Integer 
                                                              ): Boolean; 
var 
  ca:         TMsgCompressionAlgorithm1; 
  OutBuffer:  PAnsiChar; 
  OutSize:    Integer; 
  TempBuffer: PAnsiChar; 
  TempSize:   Integer;
  NewSize:    Integer;
  CRC32:      Cardinal;
begin 
  Result := True;
  if (BufferSize <= 0) or (Buffer = nil) then 
   begin 
    Buffer := nil; 
    BufferSize := 0; 
   end 
  else 
   begin 
     ca := TMsgCompressionAlgorithm1(CompressionAlgorithm); 
     if ((ca <> acaNone) or (CryptoInfo.CryptoAlgorithm <> Msg_Cipher_None)) then 
      begin 
       if (ca <> acaNone) then 
        begin
         if (CryptoInfo.CryptoAlgorithm = Msg_Cipher_None) then 
          begin
           Move(Buffer^,OutSize,SizeOf(OutSize)); 
           try 
             MsgInternalDecompressBuffer(ca,
                PAnsiChar(Buffer+SizeOf(OutSize)),BufferSize-SizeOf(BufferSize),
                OutBuffer,OutSize);
           except 
             Result := False;
             OutBuffer := nil;
           end; 
           try 
             MemoryManager.FreeAndNilMem(Buffer);
             BufferSize := 0;
             if (Result and (OutBuffer <> nil) and (OutSize > 0)) then 
              begin
               BufferSize := OutSize; 
               Buffer := MemoryManager.GetMem(OutSize); 
               Move(OutBuffer^,Buffer^,OutSize);
              end; 
           finally
             if (OutBuffer <> nil) then
              FreeMem(OutBuffer); 
           end; 
          end // no encryption
         else 
          begin
           if (BufferSize > SizeOf(CRC32) + SizeOf(TempSize)) then 
            begin 
             Move(Buffer^,CRC32,SizeOf(CRC32));
             TempSize := BufferSize-SizeOf(CRC32);
             TempBuffer := MemoryManager.GetMem(TempSize);
             try
               Move(PAnsiChar(Buffer+SizeOf(CRC32))^,TempBuffer^,TempSize);
               MemoryManager.FreeAndNilMem(Buffer);
               BufferSize := 0;
               MsgDecryptBuffer(CryptoInfo,TempBuffer,TempSize); 
               if (MsgCountCRC(0,TempBuffer,TempSize) <> CRC32) then
                Result := False 
               else
                begin
                 Move(TempBuffer^,OutSize,SizeOf(OutSize));
                 try 
                   MsgInternalDecompressBuffer(ca,
                     PAnsiChar(TempBuffer+SizeOf(OutSize)),TempSize-SizeOf(OutSize), 
                     OutBuffer,OutSize);
                   try
                     if (OutBuffer <> nil) and (OutSize > 0) then
                      begin
                       BufferSize := OutSize;
                       Buffer := MemoryManager.GetMem(BufferSize);
                       Move(OutBuffer^,Buffer^,OutSize);
                      end
                     else
                      Result := False;
                   finally
                     if (OutBuffer <> nil) then
                      FreeMem(OutBuffer);
                   end;
                 except
                   Result := False;
                 end;
                end;
             finally
               MemoryManager.FreeAndNilMem(TempBuffer);
             end;
            end // buffersize is correct
           else
             Result := False;
          end; // encryption
        end // compression with or without encryption
       else
        begin
         if (BufferSize <= SizeOf(CRC32)) then
          Result := False
         else
          begin
           Move(Buffer^,CRC32,SizeOf(CRC32));
           TempSize := BufferSize - SizeOf(CRC32);
           TempBuffer := MemoryManager.GetMem(TempSize);
           try
             Move(PAnsiChar(Buffer+SizeOf(CRC32))^,TempBuffer^,TempSize);
             MsgDecryptBuffer(CryptoInfo,TempBuffer,TempSize);
             if (MsgCountCRC(0,TempBuffer,TempSize) <> CRC32) then
              begin
               Result := False;
               MemoryManager.FreeAndNilMem(TempBuffer);
              end
           except
             Result := False;
             MemoryManager.FreeAndNilMem(TempBuffer);
           end;
           if (Result) then
            begin
             MemoryManager.FreeAndNilMem(Buffer);
             Buffer := TempBuffer;
             BufferSize := TempSize;
            end;
          end; // buffersize is correct
        end; // encryption without compression
      end; // compression or encryption
   end; // source buffer is not nil
end; // DecompressAndDecryptBuffer



initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgBaseEngine> initialized');
{$ENDIF}

end.
