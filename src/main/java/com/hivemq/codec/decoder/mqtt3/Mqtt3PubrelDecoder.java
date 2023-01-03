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
package com.hivemq.codec.decoder.mqtt3;

import com.google.inject.Inject;
import com.hivemq.bootstrap.ClientConnection;
import com.hivemq.bootstrap.ioc.lazysingleton.LazySingleton;
import com.hivemq.codec.decoder.AbstractMqttDecoder;
import com.hivemq.configuration.service.FullConfigurationService;
import com.hivemq.extension.sdk.api.annotations.NotNull;
import com.hivemq.extension.sdk.api.annotations.Nullable;
import com.hivemq.mqtt.handler.disconnect.MqttServerDisconnector;
import com.hivemq.mqtt.message.MessageType;
import com.hivemq.mqtt.message.ProtocolVersion;
import com.hivemq.mqtt.message.pubrel.PUBREL;
import io.netty.buffer.ByteBuf;

/**
 * @author Dominik Obermaier
 */
@LazySingleton
public class Mqtt3PubrelDecoder extends AbstractMqttDecoder<PUBREL> {

    @Inject
    public Mqtt3PubrelDecoder(
            final @NotNull MqttServerDisconnector disconnector,
            final @NotNull FullConfigurationService configurationService) {
        super(disconnector, configurationService);
    }

    @Override
    public @Nullable PUBREL decode(
            final @NotNull ClientConnection clientConnection, final @NotNull ByteBuf buf, final byte header) {

        if (clientConnection.getProtocolVersion() == ProtocolVersion.MQTTv3_1_1) {
            if (!validateHeader(header)) {
                disconnectByInvalidFixedHeader(clientConnection, MessageType.PUBREL);
                buf.clear();
                return null;
            }
        }

        if (buf.readableBytes() < 2) {
            disconnectByNoMessageId(clientConnection, MessageType.PUBREL);
            buf.clear();
            return null;
        }
        final int messageId = buf.readUnsignedShort();

        return new PUBREL(messageId);
    }

    @Override
    protected boolean validateHeader(final byte header) {
        return (header & 0b0000_0010) == 2;
    }
}
