package com.hivemq.security.ssl;

import org.junit.Test;

import java.util.Map;

import static org.junit.Assert.*;

public class DnsResolverTest {
    public static final String ALIAS_1 = "alias1";
    public static final String TEST_EXAMPLE_COM = "test.example.com";

    @Test
    public void test_resolve_simple_dns_name() {
        final DnsResolver dnsResolver = new DnsResolver(Map.of(TEST_EXAMPLE_COM, ALIAS_1));

        final String resolve = dnsResolver.resolve(TEST_EXAMPLE_COM);

        assertNotNull(resolve);
        assertEquals(ALIAS_1, resolve);
    }

    @Test
    public void test_resolve_non_matching_dns_name() {
        final DnsResolver dnsResolver = new DnsResolver(Map.of(TEST_EXAMPLE_COM, ALIAS_1));

        final String resolve = dnsResolver.resolve("other.example.com");

        assertNull(resolve);
    }

    @Test
    public void test_resolve_wildcard_dns_name() {
        final DnsResolver dnsResolver = new DnsResolver(Map.of("*.example.com", ALIAS_1));

        final String resolve = dnsResolver.resolve(TEST_EXAMPLE_COM);

        assertNotNull(resolve);
        assertEquals(ALIAS_1, resolve);
    }

    @Test
    public void test_resolve_nested_wildcard_dns_name() {
        final DnsResolver dnsResolver = new DnsResolver(Map.of("*.example.com", ALIAS_1));

        final String resolve = dnsResolver.resolve("sub.test.example.com");

        assertNotNull(resolve);
        assertEquals(ALIAS_1, resolve);
    }
}
