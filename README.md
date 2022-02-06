
# Obstacle Avoiding Car 

Robot car controlled using bluetooth module and has 2 modes. First mode is Normal mode, this mode receives a character from bluetooth (f=>forward, b=>backward, r=>right, l=>left, s=> stop, a=> automode) . Also it gives a red light when an object is detected in less than 25 cm. The second mode is automode which always move forward until  object is detected in less than 25 cm it move backward for 1 sec to stop the car at high speed then turn right, then it continue moving forward if no objected in front of it. By sending any character while on automode it return back to the normal mode.

# AT89S52 Microcontroller

AT89S52 is one of the popular microcontrollers from the Atmel family. AT89S52 microcontroller is an 8-bit CMOS microcontroller having 8k Flash memory and 256 bytes of RAM memory. It can be operated at 33MHz maximum operating frequency by using an external oscillator.It has GPIO pins, three 16-bit timers, one full-duplex UART communication port, three 16-bit general-purpose timers, on-chip oscillator.

# Schematic

![Schematic](https://github.com/mohamedAhmedMokhtarElkomy/ObstacleAvoidingCar-AT89S52/blob/main/Schematic.png)
## How does ultrasonic sensor work

The trigger signal for starting the transmission is given to trigger pin. The trigger signal must be a pulse with 10uS high time. When the module receives a valid trigger signal it issues 8 pulses of 40KHz ultrasonic sound from the transmitter. Then ECHO pin goes high and send sound signal, when signal comes back ECHO pin goes low.

![ultrasonic sensor timing digram](https://www.circuitstoday.com/wp-content/uploads/2012/12/HC-SR04-timing-diagram.png)

## Learn about AT89S52

- Reference for instructions: https://www.keil.com/support/man/docs/is51/is51_instructions.htm
- Reference for tutorials: http://www.8052mcu.com/tutorial
- Reference for Subroutines: https://www.refreshnotes.com/2016/05/8051-program-math-subroutines.html

## Software tools used

- Proteus 8.9
- mide IDE
- Launch virtual serial port driver

## Hardware components

- AT89S52
- ultra sonic sensor (HC-SR04)
- Blueooth module (HC-06)
- 2 * 33PF capacitors
- 11.0592 MHZ crystal
- L298 Motor Driver
- 4 * DC motors
- 16*2 LCD
- 4 * 10K ohm
- car kit
- 3 * LEDs
- 1 * variable resistance

## Extra proteus libraries
- ultrasonic sensor libraray: https://www.theengineeringprojects.com/2015/02/ultrasonic-sensor-library-proteus.html
- Bluetooth library: https://www.theengineeringprojects.com/2016/03/bluetooth-library-for-proteus.html
- L298 Motor Driver: https://www.theengineeringprojects.com/2017/09/l298-motor-driver-library-proteus.html



## Hardware issues
- The output voltage from controller pins is insufficient to light a led so add 2N2222 transistor as a switch and connect base pin to microcontroller output pin
- P0 in the controller is input ports and to use it as output we have to external pullup resistance.

## FAQ

#### Baud rate used

9600

#### Path for adding proteus libraries

C:\ProgramData\Labcenter Electronics\Proteus 8 Professional\LIBRARY

#### How to calculate distance

after echo pin goes to 1 start timer until echo pin goes to 0. then divide number of ticks by 58 to get distance in cm


## Datasheets

![datasheet](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/datasheet.jpg)
![IE](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/IE.png)
![Interrupt_Vector_Address](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/Interrupt_Vector_Address.gif)
![PI](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/PI.png)
![SCON](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/SCON.gif)
![TCON register](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/TCON-Register.jpg)
![TCON](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/TCON.PNG)
![TMOD register](https://github.com/mohamedAhmedMokhtarElkomy/microprocessor/blob/main/datasheets/TMOD-register.jpg)



