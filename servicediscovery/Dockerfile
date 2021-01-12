# set base image
FROM python:3.7
# adding sd python file
ADD servicediscovery.py /
# add requirements
ADD requirements.txt /
# install exoscale dependency
RUN pip install -r requirements.txt

#CMD [ "python", "./servicediscovery.py" ]
ENTRYPOINT [ "python", "./servicediscovery.py" ]
