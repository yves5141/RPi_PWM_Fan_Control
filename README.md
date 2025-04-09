# RPi_PWM_Fan_Control
A shell script for controlling the cooling fan of a Raspberry Pi using one of its pwm pins.
No need for unreliable support of python scripts anymore.
This solution controls the fan by using a high frequency pwm in order to avoid noise from the fan.

Using a NPN transistor and a base resistor of about 1kOhm and a 10kOhm pull-down resistor between base and emitter you can use GPIO 12 for controlling a fan.

#### Setup (LibreElec):

1. save the file "pwm_fan_RPi.sh" to the following folder on your RPi's sd card:

```
/storage/.kodi/userdata/RPi_PWM_Fan/pwm_fan_RPi.sh
```

2. change permissions of the pwm_fan_RPi.sh file with `chmod 777`
3. save the file 'PWM_fan.service' on your RaspberryPi to
```
/storage/.config/system.d/PWM_fan.service
```
4. enable the service with
```
systemctl enable PWM_fan
```
5. start the service with
```
systemctl start PWM_fan
```
6. check if the service is working with
```
systemctl status PWM_fan.service
```
