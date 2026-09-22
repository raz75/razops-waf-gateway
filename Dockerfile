FROM owasp/modsecurity-crs:4.25-nginx-lts

USER root

# Copy our custom landing page into Nginx's default web roots
COPY html/index.html /usr/share/nginx/html/index.html
COPY html/index.html /var/www/html/index.html

# OWASP CRS Rule Tuning (Environment Variables)
ENV PARANOIA=1
ENV ANOMALY_INBOUND=5
ENV ANOMALY_OUTBOUND=4

EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
