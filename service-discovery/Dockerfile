# set base image
FROM python:3.7
# adding sd python file
ADD servicediscovery.py /
# install exoscale dependency
RUN pip install exoscale

#CMD [ "python", "./servicediscovery.py" ]
ENTRYPOINT [ "python", "./servicediscovery.py" ]
