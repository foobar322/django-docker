FROM ubuntu:trusty

MAINTAINER ktaube

RUN sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN apt-get update

# install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python python-dev python-setuptools python-software-properties
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y sqlite3
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common

# add nginx stable ppa
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:nginx/stable
# update packages after adding nginx repository
RUN apt-get update
# install latest stable nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# install pip
RUN easy_install pip

# install uwsgi now because it takes a little while
RUN pip install uwsgi

# install our code
ADD . /home/docker/code/

# setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /home/docker/code/nginx-app.conf /etc/nginx/sites-enabled/
RUN ln -s /home/docker/code/supervisor-app.conf /etc/supervisor/conf.d/

# run pip install
RUN pip install -r /home/docker/code/app/requirements.txt

# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory
RUN django-admin.py startproject website /home/docker/code/app/
RUN cd /home/docker/code/app && ./manage.py syncdb --noinput

EXPOSE 80
CMD ["supervisord", "-n"]
CMD /bin/bash
