version := `git describe --tags --always`
date := `date -u +%Y-%m-%d`
base := "fedora-bootc:43"

generate-release:
    mkdir -p build
    echo 'KEEL_NAME="Keel"' > build/keel-release
    echo 'KEEL_VERSION="{{version}}"' >> build/keel-release
    echo 'KEEL_CHANNEL="stable"' >> build/keel-release
    echo 'KEEL_BASE="{{base}}"' >> build/keel-release
    echo 'KEEL_BUILD_DATE="{{date}}"' >> build/keel-release


image:
	@echo "Building keel image..."
	sudo podman build -t localhost/keel -f Containerfile

dev:
	@echo "Building keel image..."
	podman build -t localhost/keel -f Containerfile
	@echo "Running keel image and sshing..."
	bcvk ephemeral run-ssh localhost/keel

run: 
	@echo "Running keel"
	sudo virt-install \
		--name keel \
		--cpu host \
		--vcpus 2 \
		--memory 2096 \
		--import \
		--disk ./output/qcow2/disk.qcow2,format=qcow2 \
		--os-variant fedora-eln \
		--network network=default

build:
	@echo "Building keel image..."
	sudo podman build -t localhost/keel -f Containerfile

	@echo "Creating qcow2 file from keel image..."
	sudo podman run \
		--rm \
		-it \
		--privileged \
		--pull=never \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./config.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type qcow2 \
		--use-librepo=True \
		--rootfs xfs \
		localhost/keel:latest

	@echo "Starting virtual machine..."
	sudo virt-install \
		--name keel \
		--cpu host \
		--vcpus 2 \
		--memory 2096 \
		--import \
		--disk ./output/qcow2/disk.qcow2,format=qcow2 \
		--os-variant fedora-eln \
		--network network=default

iso:
	@echo "Creating iso file from keel image..."
	sudo podman run \
		--rm \
		-it \
		--privileged \
		--pull=never \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./iso.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		build \
		--rootfs ext4 \
		--type iso \
		--target-arch amd64 \
		--use-librepo=True \
		localhost/keel:latest

pull_from_github:
	@echo "Pulling from github..."
	sudo podman pull ghcr.io/azaurus1/keel:latest

dev_from_github:
	@echo "Pulling from github..."
	sudo podman pull ghcr.io/azaurus1/keel:latest
	@echo "Starting dev from github"
	sudo bcvk ephemeral run-ssh ghcr.io/azaurus1/keel:latest