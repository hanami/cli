@echo off
  gem list -i foreman --silent && (
        echo Foreman is installed
        foreman start -f Procfile.dev %*
    ) || (
    echo Foreman not installed. Attempting installation...
    call gem install foreman && (
        echo Foreman is installed
        foreman start -f Procfile.dev %*
        )
)