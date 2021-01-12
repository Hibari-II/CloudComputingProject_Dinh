# set base image
FROM python:3.7
# adding autoscale.py to container
ADD autoscaler.py /
# adding requirements.txt
ADD requirements.txt /
# install dependencies
RUN pip install -r requirements.txt

ENTRYPOINT ["python", "./autoscaler.py"]