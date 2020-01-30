
# Edit here or specify in command-line
FM_TAR:=$(PWD)/../../../../ARM/FastModels_11-9-041_Linux64.tgz
DS_TAR:=$(PWD)/../../../../ARM/ARM\ DS\ 2019.1/Linux/DS000-BN-00001-r19p1-00rel1.tgz

ARMLMD_LICENSE_PATH:=0000@000.00.00.00

  
.PHONY: info prepare docker clean


info:
	@echo "   "
	@echo "==INFORMATION=================================="
	@echo "   "
	@echo "ARMLMD_LICENSE_PATH = $(ARMLMD_LICENSE_PATH)   "
	@echo " "
	ls -ltrh $(FM_TAR)
	@echo " "
	ls -ltrh $(DS_TAR)
	@echo " "


prepare:
	mkdir -p ./arm-tool-base-repo ;
	cp ./Dockerfile ./arm-tool-base-repo/ ;
	cp $(FM_TAR) ./arm-tool-base-repo/ ;
	cp $(DS_TAR) ./arm-tool-base-repo/ ;


image:
	cd ./arm-tool-base-repo ; 
	docker build -t arm-tool-base:latest --build-arg license_path=$(ARMLMD_LICENSE_PATH) . ;


clean:
	rm -rf ./arm-tool-base-repo
