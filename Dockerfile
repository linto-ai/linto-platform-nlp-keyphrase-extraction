FROM lintoai/linto-platform-nlp-core:latest
LABEL maintainer="gshang@linagora.com"

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY kpe /usr/src/app/kpe
COPY components /usr/src/app/components
COPY celery_app /usr/src/app/celery_app
COPY http_server /usr/src/app/http_server
COPY document /usr/src/app/document
COPY docker-entrypoint.sh wait-for-it.sh healthcheck.sh ./

ENV PYTHONPATH="${PYTHONPATH}:/usr/src/app/kpe"

HEALTHCHECK CMD ./healthcheck.sh

ENTRYPOINT ["./docker-entrypoint.sh"]