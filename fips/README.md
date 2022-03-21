# FIPS Mode

## Federal Information Processing Standards (FIPS) are issued by the National Institute of Standards and Technology (NIST) after approval by the Secretary of Commerce pursuant to Section 5131 of the Information Technology Management Reform Act of 1996 (Public Law 104-106) and the Computer Security Act of 1987 (Public Law 100-235).

### To create run FID in FIPS mode

1. Install the [scripts.sh](http://scripts.sh) 
2. Create a Docker image using the above Dockerfile
3. While using the fid.yaml , replace [run.sh](http://run.sh) with [scripts.sh](http://scripts.sh) 

```yaml
args:
            [
              "if [ $HOSTNAME != myfid-0 ]; then export CLUSTER=join; fi;./scripts.sh fg",
            ]
```
