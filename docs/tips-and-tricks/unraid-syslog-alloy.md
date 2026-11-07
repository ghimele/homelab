# Forward Unraid syslog to Alloy

Grafana Alloy receives syslog messages in RFC 5424 format and forwards them to Loki. The production `alloy-syslog` service exposes UDP port `514` and TCP port `1514`. The UDP port forwards to Alloy's unprivileged port `1514`.

## Find the syslog address

Check the production LoadBalancer address:

```bash
kubectl --context PROD-KHC -n monitoring get service alloy-syslog
```

The address was `IPADDRESS` when this guide was written. Verify it before configuring Unraid: an automatically assigned address can change if the service is recreated.

## Configure Unraid

1. In **Settings > Syslog Server**, clear **Remote syslog server** and click **Apply**. This disables the built-in forwarding rule and prevents duplicate forwarding. Leave **Local syslog server** unchanged.
2. In the Unraid terminal, create the persistent configuration directory and open a new configuration file:

   ```bash
   mkdir -p /boot/config/rsyslog.d
   vi /boot/config/rsyslog.d/50-alloy.conf
   ```

3. Add the following rsyslog action, replacing the target address if the LoadBalancer address differs:

   ```text
   action(
     type="omfwd"
     target="IP ADDRESS of SYSLOG in kubernetes cluster see service name = alloy-syslog"
     port="514"
     protocol="udp"
     template="RSYSLOG_SyslogProtocol23Format"
   )
   ```

4. Link the file into the active configuration. If the destination already exists, inspect it before changing it:

   ```bash
   ln -s /boot/config/rsyslog.d/50-alloy.conf /etc/rsyslog.d/50-alloy.conf
   rsyslogd -N1
   ```

5. If validation succeeds, restart rsyslog and emit a test message:

   ```bash
   /etc/rc.d/rc.rsyslogd restart
   logger -t alloy-test "Unraid syslog test"
   ```

Unraid's startup scripts link files from `/boot/config/rsyslog.d` into `/etc/rsyslog.d`.
Check that the rsyslog configuration includes that directory; `rsyslogd -N1` validates syntax but does not confirm delivery.
If Unraid also receives remote syslog messages, review its rulesets to avoid forwarding those messages back to their source.

## Verify delivery

In Grafana Explore, select the Loki datasource, choose a recent time range, and run:

```logql
{job="syslog"} |= "Unraid syslog test"
```

To inspect Alloy's listener errors, run:

```bash
kubectl --context PROD-KHC -n monitoring logs -l app.kubernetes.io/instance=alloy -c alloy --since=10m
```

The listener rejects messages that do not match RFC 5424. UDP is unencrypted and does not guarantee delivery; restrict access to trusted networks and check the firewall permits UDP `514` from Unraid to the LoadBalancer.

## References

- [Unraid syslog configuration script](https://github.com/unraid/webgui/blob/master/emhttp/plugins/dynamix/scripts/rsyslog_config)
- [Grafana Alloy syslog source](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.syslog/)
- [rsyslog forwarding module](https://docs.rsyslog.com/doc/configuration/modules/omfwd.html)
