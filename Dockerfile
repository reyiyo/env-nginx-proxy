FROM nginx:alpine

COPY entrypoint.sh /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]