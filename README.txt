#SSL Monitoring Utility

## Environment prerequisites
* Postfix service should be running
* Httpd service should be running

## Install instructions
* Extract tar into target (e.g : /opt/certChecks) directory
* Make environment specific changes to ssl.properties file as per spec.

# Expected configuration structure
```
       `-- configdir
	      |-- ssl.properties
		  |-- checkSSLVal.sh
```

# To Execute the Script

sh checkSSLVal.sh >> /dev/null 2>1

#Note
* This script should be installed on STM server only.
* Cron should run the script once in a week.
