FROM python:latest
COPY server.py /
EXPOSE 8080
CMD python server.py
