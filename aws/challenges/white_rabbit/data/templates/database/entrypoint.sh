#!/bin/bash

# Run the default Docker entrypoint for MySQL
exec "$MYSQL_ENTRYPOINT" "$@"