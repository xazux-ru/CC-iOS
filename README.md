# CC (Cart Controller)

### This app is designed to control a self-propelled radio-controlled cart.

___

### Data format
The data is sent via Bluetooth in the following format: left:right:b\n. The left and right values are derived from the joystick position. The maximum left and right values are selected using the slider. The third transmitted parameter, b, corresponds to the pressed button. DOWN = -1, STOP = 0, UP = 1. When any of the buttons is pressed, the left and right values are transmitted as 0. When using the joystick, the b parameter is set to 0.

___

### Screenshot
Soon

