# Troubleshooting Guide for PRIBIT Connect Controller Installation






### "dpkg: error: dpkg frontend lock is locked by another process"

해당 에러는 다른 사용자 또는 자신이 해당 명령어를 사용중일 때 접근 시 발생한다. (충돌을 막기 위해 Lock을 걸어두는 방식)
또한, /var/lib/dpkg/lock 파일이 존재하면 패키지 및 인덱스 정보를 업데이트 하지 않기 때문에 발생한다. 
따라서, 다음 명령어를 수행하여 관련된 lock 파일을 삭제한다. 

```
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock* 
```

***

## 1. Controller Not Powering On
- Ensure the power cable is securely connected.
- Verify the power outlet is functioning.
- Check for any visible damage to the controller or cables.

## 2. Controller Not Detected by System
- Confirm USB or network cables are properly connected.
- Try connecting to a different USB port or network switch.
- Restart both the controller and the host system.

## 3. Firmware Update Issues
- Ensure you are using the latest firmware version.
- Follow the official update instructions step by step.
- If the update fails, restart the controller and try again.

## 4. Communication Errors
- Check network settings (IP address, subnet mask, gateway).
- Disable any firewall or antivirus that may block communication.
- Use the diagnostic tool to test connectivity.

## 5. LED Indicators Not Working
- Refer to the user manual for LED status meanings.
- If all LEDs are off, check the power supply.
- If LEDs show error codes, consult the error code table.

## 6. Additional Support
- Refer to the official documentation for detailed instructions.
- Contact PRIBIT Technical Support with your controller’s serial number and a description of the issue.

---
*This guide is for initial troubleshooting. For advanced issues, contact PRIBIT support.*