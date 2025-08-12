# Troubleshooting Guide for PRIBIT Connect Controller Installation

<br>

### "dpkg: error: dpkg frontend lock is locked by another process"

해당 에러는 다른 사용자 또는 자신이 해당 명령어를 사용중일 때 접근 시 발생한다. (충돌을 막기 위해 Lock을 걸어두는 방식)
또한, /var/lib/dpkg/lock 파일이 존재하면 패키지 및 인덱스 정보를 업데이트 하지 않기 때문에 발생한다. 
따라서, 다음 명령어를 수행하여 관련된 lock 파일을 삭제한다. 

```
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock* 
```

---




---
*This guide is for initial troubleshooting. For advanced issues, contact PRIBIT technical support team.*