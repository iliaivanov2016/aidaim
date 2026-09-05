//---------------------------------------------------------------------------

#ifndef uBkThreadH
#define uBkThreadH
#include <Classes.hpp>
#include <SysUtils.hpp>
#include "ACRMain.hpp"
#include "ACRTypes.hpp"
//---------------------------------------------------------------------------

class TRestructureThread : public TThread
{
    private:
     WideString FDBFileName;
     WideString FTableName;
    protected:
      void __fastcall Finalize();
      void __fastcall Finish();
    public:
      __fastcall TRestructureThread(WideString aDBFile, WideString aTableName, bool CreateSuspended = true);
     void __fastcall Execute();
};
#endif
