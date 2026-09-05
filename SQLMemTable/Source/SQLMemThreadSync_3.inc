  if (WriteMode) then
    FThreadSync.WaitAndLockForWrite
  else
    FThreadSync.WaitAndLockForRead;
(*
{$IFDEF READ_WRITE_THREAD_SYNC}
  if (WriteMode) then
    FThreadSync.WaitAndLockForWrite
  else
    FThreadSync.WaitAndLockForRead;
{$ELSE}
  EnterCriticalSection(FCSect);
{$ENDIF}
*)
