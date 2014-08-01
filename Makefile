TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

TARGET ?= /kb/deployment
DEPLOY_RUNTIME ?= /kb/runtime

ifeq ($(AUTH_TOKEN),)
AUTH_TOKEN = $(shell perl -ne '/^auth-token\s*=\s*(.*)/ and print "$$1\n"' deploy.cfg)
endif

MEDIA_WORKSPACE = KBaseMedia

TPAGE_ARGS = --define kb_top=$(TARGET) \
	--define kb_runtime=$(DEPLOY_RUNTIME) \
	--define "media_workspace=$(MEDIA_WORKSPACE)" \
	--define "auth_token=$(AUTH_TOKEN)"

all: build-libs bin 

bin: $(BIN_PERL) $(BIN_SERVICE_PERL)

build-libs:
	$(TPAGE) $(TPAGE_ARGS) Constants.pm.tt > lib/Bio/KBase/SimpleFBA/Constants.pm

deploy: deploy-client deploy-service
deploy-all: deploy-client deploy-service
deploy-client: build-libs deploy-libs deploy-scripts 

deploy-service: 

include $(TOP_DIR)/tools/Makefile.common.rules
