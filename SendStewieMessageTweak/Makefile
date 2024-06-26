TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SendStewieMessage

SendStewieMessage_FILES = Tweak.x 
SendStewieMessage_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

THEOS_DEVICE_IP = localhost   
THEOS_DEVICE_PORT = 2222