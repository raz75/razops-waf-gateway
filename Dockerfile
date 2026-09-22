# Use the official OWASP Coraza Nginx hardened base image
FROM ghcr.io/corazawaf/coraza-nginx:latest

# Copy our custom production configurations
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/coraza.conf /etc/coraza/coraza.conf

# Add our custom branded landing page
RUN mkdir -p /usr/share/nginx/html && \
    echo '<!DOCTYPE html><html><body style="background:#0a0e17;color:#34d399;font-family:monospace;text-align:center;padding:5rem;"><h1>[RazOps WAF Gateway]</h1><p style="color:#38bdf8;">Status: Protected by OWASP Coraza WAF & CRS v4</p><p style="color:#9ca3af;">Deployment: Automated via GitHub Actions CI/CD</p></body></html>' > /usr/share/nginx/html/index.html

# Expose HTTP
EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
