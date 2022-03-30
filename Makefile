-include .env

ENVIRONMENT=dev

AWS_CREDENTIALS=AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID)

TERRAFORM_OPT=-chdir=terraform
TERRAFORM_STATE=-backend-config="key=bars/${ENVIRONMENT}"
TERRAFORM_VARS=-var=\"environment=$(ENVIRONMENT)\"

#cred: export AWS_ACCESS_KEY_ID = $(AWS_ACCESS_KEY_ID)
#cred: export AWS_SECRET_ACCESS_KEY = $(AWS_SECRET_ACCESS_KEY)
#cred:


.SILENT:
init:
	$(AWS_CREDENTIALS) terraform $(TERRAFORM_OPT) init $(TERRAFORM_STATE) $(TERRAFORM_VARS)

plan:
	$(AWS_CREDENTIALS) terraform $(TERRAFORM_OPT) plan

apply:
	$(AWS_CREDENTIALS) terraform $(TERRAFORM_OPT) apply -auto-approve

all: plan apply
