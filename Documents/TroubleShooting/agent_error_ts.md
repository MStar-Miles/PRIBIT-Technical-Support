
## "네트워크가 불안정합니다." 오류 메시지 발생 

```
2025-10-14 10:56:31,771 [23] INFO [GetMacAddress:69] name = Ethernet0 , ipv4 = 192.168.254.103 , mac = 000C29953F30 , Description = Intel(R) 82574L Gigabit Network Connection
2025-10-14 10:56:31,772 [23] INFO [_AsyncRequestAsControlFlow:2109] RCF
2025-10-14 10:56:31,772 [23] INFO [_AsyncRequestAsControlFlow:2118] RCF REQUEST : {"SGN":"7cffaf60967be554c5ac7dc0e04b5af428992f43e57d33c6e8aef3cc781744b3","EFH":"7349df93bd925e71b968579126edffe6b2efe83a4aae97a8fff59cd030edad04","LFH":"22a735d66485bd8da1ffe0449f56bc7ead2b1aafde7c40e4a54820823939441d","IMM":false,"IUDP":false,"IUTM":false,"PC":"C_MS_WINDOWS","PV":"10.0","PDN":"Windows 10","GTC":"C_APPLICATION","GV":"2.6.4.18","DID":"VMware-VMW201.00577715732116_01277","NID":"VMware-VMW201.00577715732116","DHN":"DESKTOP-4BDK647","DMN":"VMware20,1","DUN":"Pribit","CSID":"vm demo","NTC":"C_WIRE","WRID":"","MCN":"","AIR":"","LGG":"C_KR","NIP":"192.168.254.103","DMA":"00:0C:29:95:3F:30"}
2025-10-14 10:56:31,930 [20] ERROR [_AsyncRequestAsTCP:2524] 
System.SystemException: System.Net.Http.HttpRequestException: An error occurred while sending the request.
 ---> System.IO.IOException: The response ended prematurely.
   at System.Net.Http.HttpConnection.SendAsyncCore(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
   --- End of inner exception stack trace ---
   at System.Net.Http.HttpConnection.SendAsyncCore(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
   at System.Net.Http.HttpConnectionPool.SendWithVersionDetectionAndRetryAsync(HttpRequestMessage request, Boolean async, Boolean doRequestAuth, CancellationToken cancellationToken)
   at System.Net.Http.RedirectHandler.SendAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
   at System.Net.Http.HttpClient.<SendAsync>g__Core|83_0(HttpRequestMessage request, HttpCompletionOption completionOption, CancellationTokenSource cts, Boolean disposeCts, CancellationTokenSource pendingRequestsCts, CancellationToken originalCancellationToken)
   at d.m.g.a.b(MemoryStream A_0)
2025-10-14 10:56:31,940 [20] ERROR [_AsyncRequestAsControlFlow:2240] 
System.SystemException: d.m.g.d.d: 접속하신 네트워크 환경이 불안정합니다.
잠시 후 다시 이용해 주세요.
   at d.m.g.a.b(MemoryStream A_0)
   at d.m.g.a.b(Boolean A_0, String A_1, JObject A_2)
2025-10-14 10:56:31,941 [20] ERROR [AsyncRequestControlFlow:2025] 
System.SystemException: d.m.g.d.d: 접속하신 네트워크 환경이 불안정합니다.
잠시 후 다시 이용해 주세요.
   at d.m.g.a.b(MemoryStream A_0)
   at d.m.g.a.b(Boolean A_0, String A_1, JObject A_2)
   at d.m.g.a.b(String A_0, String A_1, String A_2, String A_3, String A_4, String A_5, String A_6, String A_7, String A_8, String A_9, String A_10, String A_11, String A_12)
2025-10-14 10:56:31,942 [20] INFO [RequestControlFlow_OnFailed:1164] 
``` 

[체크리스트 사용자 PC(PGA)]
1. 사용자 PC에서 네트워크 상태 확인 
2. PCG 와 Ping(ICMP) 체크 
3. PCG 와 443 Port 통신 확인

[체크리스트 PCC/PCG]
1. PCC 관리자 콘솔에서 FLOW > 네트워크 경계 설정 확인 
2. PCC 에서 Packet Capture (tcpdump) 
   1. 패킷이 정상적으로 전달되는지 확인

[조치 방안]
1. PCC 서비스 재기동 
```
systemctl restart connect-controller-check.service 
systemctl restart connect-controller-web.service
systemctl restart connect-controller-api.service
systemctl restart connect-controller.service
```
2. 사용자 PC 재기동 
