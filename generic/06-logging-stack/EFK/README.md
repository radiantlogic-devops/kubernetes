# Logging Stack

Enable csv logs
```
kubectl exec -it po/fid-0 -n fid-demo -c fid -- bash -c "vds/bin/vdsconfig.sh set-property -name accessLogCsvFormat -instance vds_server -value true"
```