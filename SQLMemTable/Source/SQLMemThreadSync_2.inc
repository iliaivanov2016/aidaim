 FThreadSync.Free;
(*
{$IFDEF READ_WRITE_THREAD_SYNC}
 FThreadSync.Free;
{$ELSE}
 DeleteCriticalSection(FCSect);
{$ENDIF}
*)
