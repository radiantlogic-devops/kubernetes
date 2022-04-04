# FIPS Mode

## In FIPS mode, RadiantOne performs all cryptographic operations using the Radiant Logic Cryptographic Module for Java. This includes key generation and key derivation, message digests and message authentication codes, random number generation, symmetric and asymmetric encryption, signature generation and verification, etc.

### To create run FID in FIPS mode

1. Install the [fips.sh]
2. Create a Docker image using the above Dockerfile
3. While using the fid.yaml , replace [run.sh](http://run.sh) with [fips.sh]

```yaml
args:
            [
              "if [ $HOSTNAME != myfid-0 ]; then export CLUSTER=join; fi;./fips.sh fg",
            ]
```
