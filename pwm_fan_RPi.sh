#!/bin/sh

#########################################################################################
# License of the original script by FranzAT                                             #
# see: https://github.com/FranzAT/libreelec_PWM_fan/blob/main/LICENSE                   #
#########################################################################################
# MIT License
#
# Copyright (c) 2021 FranzAT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#########################################################################################


#########################################################################################
# LibreElec PWM Fan Control by yves5141                                                 #
# original Python script by FranzAT, see: https://github.com/FranzAT/libreelec_PWM_fan  #
# I just changed what was neccessary in order to get a script which can run completely  #
# in a Bourne Shell without Python and make use of a high frequency pwm of the RPi      #
# pwm is set to 100kHz by default                                                       #
#########################################################################################


# Configuration
FAN_PIN=12    # BCM pin used to drive transistor's base
WAIT_TIME=5   # [s] Time to wait between each refresh
FAN_MIN=3000  # [ns] Fan minimum speed.
period=10000  # [ns] Change this value if fan has strange behavior  
duty_cycle=10000 #[ns] max fan speed on startup


# Configurable temperature and fan speed steps
# somewhat bloated, since the bourne shell doesn't support arrays...

# number of values used for controlling (has to match the number of 
# following vars of the "array")
numOfTempSteps=7

maxIndexOfTempSteps=$((numOfTempSteps - 1))

# temperature in °C
tempSteps0="50"
tempSteps1="55"
tempSteps2="60"
tempSteps3="65"
tempSteps4="70"
tempSteps5="75"
tempSteps6="80"

# duty cycle in ns
speedSteps0="3500"
speedSteps1="4500"
speedSteps2="5000"
speedSteps3="5500"
speedSteps4="6000"
speedSteps5="7500"
speedSteps6="10000"

# Fan speed will change only if the difference of temperature is higher than hysteresis
hyst=1

# enable dtoverlay, if you use dtoverlay in your config.txt, you might add this setting
# there and comment the following line
eval "dtoverlay pwm pin=\$FAN_PIN func=4"
sleep 1
# Setup PWM pin
echo 0 > /sys/class/pwm/pwmchip0/export
sleep 1
echo $period > /sys/class/pwm/pwmchip0/pwm0/period
echo $duty_cycle > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

# on startup, give the fan some time to overcome its inertia (enables lower rpm)
# especially useful when using a 12V fan, like I do
sleep 8

i=0
cpuTemp=0
fanSpeed=0
cpuTempOld=0
fanSpeedOld=0

# finding useful var names is hard at this point, don't judge me....
# hopefully, we will get bash, zsh or any other modern shell in newer LibreElec releases
eval "comp1=\$tempSteps$maxIndexOfTempSteps"
eval "comp2=\$speedSteps$maxIndexOfTempSteps"


while :; do
        # Read CPU temperature
        cpuTemp=$(cat "/sys/class/thermal/thermal_zone0/temp")
        cpuTemp=$((cpuTemp / 1000))

        # Calculate desired fan speed
        diff="$((cpuTemp - cpuTempOld))"
        diff="${diff#-}"    # abs value
        if [ $diff -gt $hyst ]; then
            # Below first value, fan will run at min speed.
            if [ $cpuTemp -lt $tempSteps0 ]; then
                fanSpeed=$speedSteps0
            # Above last value, fan will run at max speed
            elif [ $cpuTemp -ge $comp1 ]; then
                fanSpeed=$comp2
            # If temperature is between 2 steps, fan speed is calculated by linear interpolation
            else
                for i in {0..$maxIndexOfTempSteps}
                do
		    eval "comp3=\$tempSteps$i"
		    comp4=$((comp3 + 1))
                    eval "comp5=\$speedSteps$i"
                    comp6=$((comp5 + 1))

                    if [ $cpuTemp -ge $comp3 ] && [ $cpuTemp -lt $comp4 ]; then
                        fanSpeed=$((($comp6 - $comp5) / ($comp4 - $comp3) * (cpuTemp - $comp3) + $comp5))
                    fi
                done
            fi

            if [ $fanSpeed -ne $fanSpeedOld ]; then
                if [ $fanSpeed -ne $fanSpeedOld ] && [ $fanSpeed -ge $FAN_MIN ] || [ $fanSpeed -eq 0 ]; then
                    echo $fanSpeed > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
                    fanSpeedOld=fanSpeed
                fi
            fi
            cpuTempOld=cpuTemp
        fi
        sleep $WAIT_TIME
done

exit 0
