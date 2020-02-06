
# Edit here or specify in command-line
CMS_TAR:=$(PWD)/../../../../ARM/cycle\ model\ studio/Arm-CycleModel-release-v11_0_4.tgz
CMS_SYSC_TAR:=$(PWD)/../../../../ARM/cycle\ model\ studio/Arm-CycleModelSystemC-Runtime-files-Linux64-v11.0.1.tgz

ARMLMD_LICENSE_PATH:=0000@000.00.00.00

  
.PHONY: info prepare clean


info:
	@echo "   "
	@echo "==INFORMATION=================================="
	@echo "   "
	@echo "ARMLMD_LICENSE_PATH = $(ARMLMD_LICENSE_PATH)   "
	@echo " "
	ls -ltrh $(cMs_TAR)
	@echo " "


prepare_makefile:
	mkdir -p ./arm-tool-base-cms-repo ;
	cp ./Dockerfile ./arm-tool-base-cms-repo/ ;


prepare: prepare_makefile
	cp ./Dockerfile ./arm-tool-base-cms-repo/ ;
	cp $(CMS_TAR) ./arm-tool-base-cms-repo/ ;
	cp $(CMS_SYSC_TAR) ./arm-tool-base-cms-repo/ ;


image:
	cd ./arm-tool-base-repo ; 
	docker build -t arm-tool-base-cms:latest --build-arg license_path=$(ARMLMD_LICENSE_PATH) . ;


clean:
	rm -rf ./arm-tool-base-repo

