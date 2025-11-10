# Web View Error 

[PCA 웹 뷰 에러로그]
``` 
2025-10-23 17:01:06,572 [1] INFO [OnWindowStateMessage:221] Normal Show
2025-10-23 17:01:09,147 [1] INFO [LogOut:195] 
System.SystemException: System.Runtime.InteropServices.COMException (0x8000FFFF): 오류입니다. (0x8000FFFF (E_UNEXPECTED))
   at System.Runtime.InteropServices.Marshal.ThrowExceptionForHR(Int32 errorCode)
   at Microsoft.Web.WebView2.Core.CoreWebView2Environment.CreateCoreWebView2ControllerAsync(IntPtr ParentWindow)
   at Microsoft.Web.WebView2.Wpf.WebView2.Microsoft.Web.WebView2.Wpf.IWebView2Private.InitializeController(IntPtr parent_window, CoreWebView2ControllerOptions controllerOptions)
   at Microsoft.Web.WebView2.Wpf.WebView2Base.<>c__DisplayClass32_0.<<EnsureCoreWebView2Async>g__Init|0>d.MoveNext()
--- End of stack trace from previous location ---
   at d.a.b.d.a(String A_0, Boolean A_1)
   at System.Threading.Tasks.Task.<>c.<ThrowAsync>b__128_0(Object state)
   at System.Windows.Threading.ExceptionWrapper.InternalRealCall(Delegate callback, Object args, Int32 numArgs)
   at System.Windows.Threading.ExceptionWrapper.TryCatchWhen(Object source, Delegate callback, Object args, Int32 numArgs, Delegate catchHandler)
2025-10-23 17:01:09,214 [1] INFO [Dispose:95] SPAManger
2025-10-23 17:01:47,479 [1] INFO [DisconnectTunnel:108]
``` 

윈도우에서 PCA 앱을 초기화 할 때 런타임에서 웹뷰 에러가 발생  
-> 현재 대응은 웹뷰를 사용하지 않는 버전으로 설치하는 것으로 가이드 
