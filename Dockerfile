# Use the official OWASP CRS Hardened Nginx Base Image
FROM owasp/modsecurity-crs:4.25-nginx-lts

# Environment variables to configure OWASP WAF behavior
ENV PARANOIA=1
ENV ANOMALY_INBOUND=5
ENV ANOMALY_OUTBOUND=4
ENV BLOCKING_PARANOIA=1

# Add our custom branded landing page
RUN mkdir -p /usr/share/nginx/html && \
    echo '<!DOCTYPE html><html><body style="background:#0a0e17;color:#34d399;font-family:monospace;text-align:center;padding:5rem;"><h1>[RazOps WAF Gateway]</h1><p style="color:#38bdf8;">Engine: Hardened Nginx + OWASP Core Rule Set v4</p><p style="color:#9ca3af;">Deployment: Automated via GitHub Actions CI/CD</p></body></html>' > /usr/share/nginx/html/index.html

# Expose HTTP
EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
