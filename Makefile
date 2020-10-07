

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = wsi_WeaklySupervisedLearning 
PYTHON_INTERPRETER = python
PYTHON_VERSION = 3.6

## test if Anaconda is installed
ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

# shortcuts
DATA_SCRIPTS := $(PROJECT_DIR)/data

# network
DOCKER_JUPYTER_PORT := 8080
LOCAL_JUPYTER_PORT := 5000

#################################################################################
# PYTHON ENVIRONMENT COMMANDS                                                   #
#################################################################################

## set up the python environment
create_environment:
ifeq (True,$(HAS_CONDA))
	conda create --name $(PROJECT_NAME) python=$(PYTHON_VERSION)
	@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
else
	@echo "Conda is not installed. Please install it."
endif

## install the requirements into the python environment
requirements: install_curl  install_openslide  install_java
	conda env update --file environment.yml
	pip install -r requirements.txt
## save the python environment so it can be recreated
export_environment:
	conda env export --no-builds | grep -v "^prefix: " > environment.yml
	# note - the requirements.txt. is required to build the
	# environment up but is not changed are part of the export
	# process

# some packages that are required by the project have binary dependencies that
# have to be installed out with Conda.


install_openslide:
	sudo apt-get update
	sudo apt install -y build-essential
	sudo apt-get -y install openslide-tools
	pip install Pillow
	pip install openslide-python


install_curl:
	sudo apt -y install curl

install_java:
	sudo apt -y install software-properties-common
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt -y install openjdk-8-jdk
	sudo update-alternatives --config java # select Java 8
	printf '\nexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

#################################################################################
# CONTAINER COMMANDS                                                            #
#################################################################################
install_docker:
	# this installs Docker Community Edition from the official Docker repository
	sudo apt update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
	sudo apt-get update
	sudo apt-get -y install docker-ce
	# then we are going to add the current user to the Docker group so we can connect to the docker
	# process when we are not root
	sudo groupadd docker
	sudo usermod -aG docker $USER
	echo "Please logout and log back in for changes to take effect :D"

docker_image:
	docker build -t $(PROJECT_NAME) .


docker_run_mm_local:
	docker run --gpus all -p $(DOCKER_JUPYTER_PORT):$(DOCKER_JUPYTER_PORT) \
				-v $(PROJECT_DIR):/home/ubuntu/$(PROJECT_NAME) \
				-v /home/mahnaz/datasets/camelyon16/raw/training/tumor:/home/ubuntu/$(PROJECT_NAME)/data \
				-v /data1/wsi_WeaklySupervisedLearning/results:/home/ubuntu/$(PROJECT_NAME)/results \
				-v /data1/wsi_WeaklySupervisedLearning/features:/home/ubuntu/$(PROJECT_NAME)/features \
				-it $(PROJECT_NAME):latest

docker_run_tars:
	docker run --shm-size 8G --gpus all -v $(PROJECT_DIR):/home/ubuntu/$(PROJECT_NAME) \
				-v /data1/datasets/camelyon16/raw/training/tumor:/home/ubuntu/$(PROJECT_NAME)/data \
				-v /data1/wsi_WeaklySupervisedLearning/results:/home/ubuntu/$(PROJECT_NAME)/results \
				-v /data1/wsi_WeaklySupervisedLearning/features:/home/ubuntu/$(PROJECT_NAME)/features \
				-it $(PROJECT_NAME):latest

docker_remove_all_images:
	docker rmi $(docker images -a -q)

docker_remove_all_exited_containers:
	docker rm $(docker ps -a -f status=exited -q)

#################################################################################
# JUPYTER COMMANDS                                                              #
#################################################################################
run_notebooks:
	jupyter notebook --ip=* --port $(LOCAL_JUPYTER_PORT) --allow-root

run_notebooks_docker:
	jupyter notebook --ip=* --port $(DOCKER_JUPYTER_PORT) --allow-root

run_lab:
	jupyter lab --ip=* --port $(LOCAL_JUPYTER_PORT) --allow-root

run_lab_docker:
	jupyter lab --ip=* --port $(DOCKER_JUPYTER_PORT) --allow-root



