# Solr tools

Author: Jan Høydahl @ Cominvent AS

## upgradeindex.sh
Bash script to upgrade an entire Solr index from 4.x or 5.x to 6.x so it can be read by Solr6.x or Solr 7.x. See [README](./upgradeindex/README.md)

##SolrPasswordHash
Simple command line tool to generate a password hash for `security.json`

### Build

    mvn package

### Usage:

    java -jar target/solr-tools-1.0-SNAPSHOT.jar admin 123
    Generating password hash for admin and salt 123:
    HZtl83vopLyZfOpGedEQveAwvVdAQ1Ukr6dDJPEfs/w= MTIz
    Example usage:
    "credentials":{"myUser":"HZtl83vopLyZfOpGedEQveAwvVdAQ1Ukr6dDJPEfs/w= MTIz"}
    
# License

All tools © [Cominvent AS](www.cominvent.com) and licensed under the Apache License v2.0
