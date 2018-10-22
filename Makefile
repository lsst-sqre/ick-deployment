SHELL := /bin/bash

REPLACE = ./kubernetes/replace.sh

# Create Kubernetes tls-certs secret
# LSST_CERTS_REPO is downloaded from the `lsst-square` Dropbox folder
LSST_CERTS_REPO = lsst-certs.git
LSST_CERTS_YEAR = 2018
KEY = tls/lsst.codes/2018/lsst.codes.key
CERT = tls/lsst.codes/2018/lsst.codes_chain.pem

tls-certs:
	@echo "Creating secrets..."
	@mkdir -p tls
	@cd tls; git init; git remote add origin ../$(LSST_CERTS_REPO); git pull origin master
	kubectl delete --ignore-not-found=true secrets tls-certs
	kubectl create secret tls tls-certs --key $(KEY) --cert $(CERT)

clean:
	rm -rf tls
