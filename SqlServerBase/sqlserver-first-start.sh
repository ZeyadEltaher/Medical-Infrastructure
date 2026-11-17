#!/bin/bash
set -euo pipefail

if [ ! -f /var/opt/mssql/.setup-complete ]; then

    echo "Configuring SQL Server for the first time..."

    : "${ACCEPT_EULA:?ACCEPT_EULA is required}"
    : "${MSSQL_PID:?MSSQL_PID is required}"
    : "${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD is required}"

    /opt/mssql/bin/mssql-conf -n setup

    touch /var/opt/mssql/.setup-complete

    echo "SQL Server setup completed."

else
    echo "SQL Server is already configured."
fi