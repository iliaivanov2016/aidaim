  FThreadSync.Unlock;
(*
{$IFDEF READ_WRITE_THREAD_SYNC}
  FThreadSync.Unlock;
{$ELSE}
  LeaveCriticalSection(FCSect);
{$ENDIF}
*)
