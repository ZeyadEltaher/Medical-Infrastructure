FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# 1. Install systemd and required tools
RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        gnupg \
        software-properties-common \
        systemd \
        systemd-sysv \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/sqlserver-secrets

# 2. Add Microsoft signing key
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# 3. Add SQL Server repositories
RUN curl -fsSL \
    https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list \
    -o /etc/apt/sources.list.d/mssql-server-2025.list

RUN curl -fsSL \
    https://packages.microsoft.com/config/ubuntu/24.04/prod.list \
    -o /etc/apt/sources.list.d/mssql-release.list

# 4. Install SQL Server Engine
COPY mssql-server.deb /tmp/mssql-server.deb

RUN apt-get update && \
    (dpkg -i /tmp/mssql-server.deb || apt-get install -f -y) && \
    dpkg-query -W -f='${Status}\n' mssql-server | \
    grep -q 'install ok installed'

# 5. Install SQL Server Tools
RUN ACCEPT_EULA=Y apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

# 6. Add sqlcmd to PATH
ENV PATH="${PATH}:/opt/mssql-tools18/bin"

# 7. Copy first-time setup script
COPY sqlserver-first-start.sh /usr/local/sbin/

RUN chmod +x /usr/local/sbin/sqlserver-first-start.sh

# 8. Add first-time setup systemd service
COPY sqlserver-first-setup.service /etc/systemd/system/sqlserver-first-setup.service

# 9. Enable first-time setup service
RUN mkdir -p /etc/systemd/system/multi-user.target.wants && \
    ln -s ../sqlserver-first-setup.service \
    /etc/systemd/system/multi-user.target.wants/sqlserver-first-setup.service

# 10. Clean installation files
RUN rm -f /tmp/mssql-server.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 11. Start systemd
CMD ["/sbin/init"]