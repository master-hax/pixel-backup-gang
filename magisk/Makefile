all: release release/cifs-mounter.zip release/cifs-unmounter.zip release/usb-mounter.zip release/usb-unmounter.zip release/wifi-adb.zip

release:
	mkdir release

release/cifs-mounter.zip: cifs-mounter/module.prop cifs-mounter/action.sh
	chmod 755 cifs-mounter/action.sh
	zip -j release/cifs-mounter.zip cifs-mounter/module.prop cifs-mounter/action.sh

release/cifs-unmounter.zip: cifs-unmounter/module.prop cifs-unmounter/action.sh
	chmod 755 cifs-unmounter/action.sh
	zip -j release/cifs-unmounter.zip cifs-unmounter/module.prop cifs-unmounter/action.sh

release/usb-mounter.zip: usb-mounter/module.prop usb-mounter/action.sh
	chmod 755 usb-mounter/action.sh
	zip -j release/usb-mounter.zip usb-mounter/module.prop usb-mounter/action.sh

release/usb-unmounter.zip: usb-unmounter/module.prop usb-unmounter/action.sh
	chmod 755 usb-unmounter/action.sh
	zip -j release/usb-unmounter.zip usb-unmounter/module.prop usb-unmounter/action.sh

release/wifi-adb.zip: wifi-adb/module.prop wifi-adb/action.sh
	chmod 755 wifi-adb/action.sh
	zip -j release/wifi-adb.zip wifi-adb/module.prop wifi-adb/action.sh

clean:
	rm -f release/usb-mounter.zip release/usb-unmounter.zip release/wifi-adb.zip
