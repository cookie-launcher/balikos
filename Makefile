.PHONY: packages iso test-bios test-uefi release clean

packages:
	./scripts/build-packages.sh

iso:
	sudo ./scripts/build-iso.sh

test-bios:
	./scripts/test-iso-qemu.sh --bios

test-uefi:
	./scripts/test-iso-qemu.sh --uefi

release:
	./scripts/publish-release.sh

clean:
	rm -rf work out repo cache
