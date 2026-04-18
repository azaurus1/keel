version := `git describe --tags --always`
date := `date -u +%Y-%m-%d`
base := "fedora-bootc:43"
channel  := "stable"
image_tag := "localhost/keel"
registry := "ghcr.io/azaurus1/keel"

generate-release:
    mkdir -p build
    printf '%s\n' \
        'KEEL_NAME="Keel"' \
        'KEEL_VERSION="{{version}}"' \
        'KEEL_CHANNEL="{{channel}}"' \
        'KEEL_BASE="{{base}}"' \
        'KEEL_BUILD_DATE="{{date}}"' \
        > build/keel-release

image: generate-release
    @echo "Building keel image ({{version}}, {{channel}})..."
    sudo podman build \
        --build-arg KEEL_VERSION="{{version}}" \
        --build-arg KEEL_BUILD_DATE="{{date}}" \
        -t {{image_tag}} -f Containerfile

dev:
	@echo "Building keel image..."
	podman build -t {{image_tag}} -f Containerfile
	@echo "Running keel image and sshing..."
	bcvk ephemeral run-ssh {{image_tag}}

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
	sudo podman build -t {{image_tag}} -f Containerfile

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
		{{image_tag}}:latest

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
		{{image_tag}}:latest

push: image
    @echo "Pushing {{image_tag}} to {{registry}}:{{version}}..."
    podman tag {{image_tag}} {{registry}}:{{version}}
    podman tag {{image_tag}} {{registry}}:latest
    podman push {{registry}}:{{version}}
    podman push {{registry}}:latest