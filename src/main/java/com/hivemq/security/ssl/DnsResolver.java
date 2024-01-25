package com.hivemq.security.ssl;

import java.util.Map;

public class DnsResolver {

    private final Map<String, String> dnsMap;

    DnsResolver(final Map<String, String> dnsMap) {
        this.dnsMap = dnsMap;
    }

    String resolve(final String domain) {
        String alias = dnsMap.get(domain);
        if (alias != null) {
            return alias;
        }

        int index = domain.indexOf('.');
        while (index >= 0) {
            final String wildcardDomain = "*" + domain.substring(index);
            alias = dnsMap.get(wildcardDomain);
            if (alias != null) {
                return alias;
            }
            index = domain.indexOf('.', index + 1);
        }

        return null;
    }

}
