FROM alpine:latest

LABEL maintainer="Dmitry Konovalov konovalov.d.s@gmail.com"
ENV LANG=C.UTF-8
ENV LC_ALL C.UTF-8

RUN set -e \
&& apk add --update --quiet \
         asterisk \
         asterisk-sample-config >/dev/null \
  git \
  sudo \
  alpine-sdk \
  m4 \
  automake \
  autoconf \
  subversion \
&& asterisk -U asterisk &>/dev/null \
&& sleep 5s \
&& [ "$(asterisk -rx "core show channeltypes" | grep PJSIP)" != "" ] && : \
     || rm -rf /usr/lib/asterisk/modules/*pj* \
&& pkill -9 ast \
&& sleep 1s \
&& truncate -s 0 \
     /var/log/asterisk/messages \
     /var/log/asterisk/queue_log || : \
&& mkdir /usr/src \
&& mkdir -p /var/spool/asterisk/fax \
&& chown -R asterisk: /var/spool/asterisk \
&& rm -rf /var/run/asterisk/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*
RUN cd /usr/src \
&& git clone https://gitlab.alpinelinux.org/alpine/aports \
&& cd /usr/src/aports/main/asterisk
WORKDIR /usr/src/aports/main/asterisk/
RUN abuild-keygen -ain
RUN abuild -F deps 
RUN abuild -FK \
&& mv /usr/src/aports/main/asterisk/src/asterisk-18.11.2/ /usr/src/asterisk \
&& rm -rf /usr/src/aports \
&& cd /usr/src \
&& git clone https://github.com/alphacep/vosk-asterisk.git \
&& cd /usr/src/vosk-asterisk \
&& ./bootstrap \
    && ./configure --with-asterisk=/usr/src/asterisk --prefix=/usr \
    && make \
    && make install \
    && cp -R /usr/etc/asterisk/ /etc/ \
    && sed -i -e 's/noload = chan_sip.so/require = chan_sip.so/' /etc/asterisk/modules.conf \
    && echo 'load = res_speech_vosk.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = res_pjsip.so' >> /etc/asterisk/modules.conf \ 
    && echo 'noload = chan_pjsip.so' >> /etc/asterisk/modules.conf
EXPOSE 5060/udp
EXPOSE 10000-10200/udp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN apk del --quiet \
 git \
 alpine-sdk \
 m4 \
 automake \
 autoconf \
 subversion 
ENTRYPOINT ["/docker-entrypoint.sh"]