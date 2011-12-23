from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
import os

device = MonkeyRunner.waitForConnection()
result = device.takeSnapshot()
result.writeToFile('screen.png', 'png')
