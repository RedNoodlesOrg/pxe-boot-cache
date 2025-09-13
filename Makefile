IMAGE ?= coreos-pxe-cache:latest
DOCKERFILE ?= ./Dockerfile
CONFDIR ?= ./nginx
CONFFILE ?= $(CONFDIR)/nginx.conf

.PHONY: build
build:
	docker build -t $(IMAGE) -f $(DOCKERFILE) .

.PHONY: validate
validate: build
	# run config test inside a disposable container
	docker run --rm \
		$(IMAGE) \
		openresty -t -c /usr/local/openresty/nginx/conf/nginx.conf

.PHONY: run
run:
	docker run -d --name coreos-pxe \
		-p 8080:8080 \
		-v coreos-cache:/var/cache/nginx/fcos \
		--restart unless-stopped \
		$(IMAGE)

.PHONY: stop
stop:
	-@docker rm -f coreos-pxe 2>/dev/null || true
	-@docker volume rm coreos-cache 2>/dev/null || true
