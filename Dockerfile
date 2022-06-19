FROM alpine:latest

LABEL maintainer="Dmitry Konovalov konovalov.d.s@gmail.com"
ENV LANG=C.UTF-8
ENV LC_ALL C.UTF-8

RUN set -e \
&& apk add --update --quiet \
         asterisk \
         asterisk-sample-config >/dev/null \
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
          /var/tmp/* \
    && sed -i -e 's/noload = chan_sip.so/require = chan_sip.so/' /etc/asterisk/modules.conf \
    && mkdir /etc/asterisk/{ael,dialplan,sip} \
    && echo '#tryinclude sip/*.conf'  >> /etc/asterisk/sip.conf \
    && echo '#tryinclude dialplan/*.conf' >> /etc/asterisk/extensions.conf \
    && echo '#tryinclude ael/*.conf' >> /etc/asterisk/extensions.ael\
    && echo 'load = res_speech_vosk.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = res_pjsip.so' >> /etc/asterisk/modules.conf \ 
    && echo 'noload = chan_pjsip.so' >> /etc/asterisk/modules.conf 
COPY res_speech_vosk.a /usr/lib/asterisk/modules
COPY res_speech_vosk.la /usr/lib/asterisk/modules
COPY res_speech_vosk.so /usr/lib/asterisk/modules
COPY res_speech_vosk.conf /etc/asterisk
EXPOSE 5060/udp
EXPOSE 10000-10200/udp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk
ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]