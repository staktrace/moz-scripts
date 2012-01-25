from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
import os

device = MonkeyRunner.waitForConnection()
device.press("KEYCODE_DPAD_RIGHT", MonkeyDevice.DOWN_AND_UP)
