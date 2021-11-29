FROM lintoai/linto-platform-nlp-core:latest
LABEL maintainer="gshang@linagora.com"

WORKDIR /app

VOLUME /app/assets
ENV ASSETS_PATH=/app/assets

COPY ./requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY ./scripts /app/scripts
COPY ./components /app/components

HEALTHCHECK --interval=15s CMD curl -fs http://0.0.0.0/health || exit 1

ENTRYPOINT ["/home/user/miniconda/bin/uvicorn", "scripts.main:app", "--host", "0.0.0.0", "--port", "80"]
CMD ["--workers", "1"]