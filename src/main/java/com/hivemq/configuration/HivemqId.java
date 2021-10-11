/*
 * Copyright 2019-present HiveMQ GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.hivemq.configuration;

import org.apache.commons.lang3.RandomStringUtils;

import javax.inject.Singleton;

/**
 * @author Christoph Schäbel
 */
@Singleton
public class HivemqId {

    private String hivemqId;

    public HivemqId() {
        hivemqId = generateId();
    }

    public String get() {
        return hivemqId;
    }

    //needs to be at least 5 characters long to provide acceptable uniqueness
    public String generateId() {
        return RandomStringUtils.randomAlphanumeric(5);
    }

    public void set(final String hivemqId) {
        this.hivemqId = hivemqId;
    }
}