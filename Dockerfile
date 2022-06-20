FROM centos:latest
LABEL maintainer="Dmitry Konovalov konovalov.d.s@gmail.com"
ENV LANG=C.UTF-8
ENV LC_ALL C.UTF-8
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
WORKDIR /etc/yum.repos.d
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* 
RUN dnf install -y epel-release
RUN dnf -y install dnf-plugins-core
RUN dnf upgrade -y
RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN dnf config-manager --set-enabled powertools
RUN dnf install -y\
        git \
        wget \
        net-tools \
        gcc \
        cpp \
        ncurses \
        ncurses-devel \
        libxml2 \
        libxml2-devel \
        sqlite \
        openssl-devel \
        newt-devel \
        libuuid-devel \
        gcc-c++ \
        sqlite-devel \
        psmisc \
        libtermcap-devel \
        libtiff-devel \
        gtk2-devel \
        libtool \
        libuuid-devel \
        subversion \
        kernel-devel \
        crontabs \
        cronie-anacron \
        mariadb \
        net-snmp-devel \
        xinetd \
        tar \
        jansson-devel \
        make \
        bzip2 \
        pjproject-devel \
        libsrtp-devel \
        gsm-devel \
        speex-devel \
        gettext \
        unixODBC \
        unixODBC-devel \
        libtool-ltdl \
        libtool-ltdl-devel \
        mariadb-connector-odbc \
        libedit-devel \
        gmime30-devel \
        speexdsp-devel \
        lua-devel \
        speex-devel \
        libedit \
        diffutils \
    && dnf clean all
WORKDIR /usr/src
RUN git clone -b certified/18.9-cert1 --depth 1 https://github.com/asterisk/asterisk.git
WORKDIR /usr/src/asterisk
# Configure
RUN sh contrib/scripts/install_prereq install \
&& sh contrib/scripts/get_mp3_source.sh \
&& ./configure 1> /dev/null \
&& make -j$(nproc) menuselect.makeopts \
&& menuselect/menuselect \
  --disable BUILD_NATIVE \
  --enable format_mp3 \
  --enable cdr_csv \
  --enable chan_sip \
  --enable res_snmp \
  --enable res_http_websocket \
  --enable res_hep_pjsip \
  --enable res_hep_rtcp \
  --enable res_sorcery_astdb \
  --enable res_sorcery_config \
  --enable res_sorcery_memory \
  --enable res_sorcery_memory_cache \
  --enable res_pjproject \
  --enable res_rtp_asterisk \
  --enable res_ari \
  --enable res_ari_applications \
  --enable res_ari_asterisk \
  --enable res_ari_bridges \
  --enable res_ari_channels \
  --enable res_ari_device_states \
  --enable res_ari_endpoints \
  --enable res_ari_events \
  --enable res_ari_mailboxes \
  --enable res_ari_model \
  --enable res_ari_playbacks \
  --enable res_ari_recordings \
  --enable res_ari_sounds \
  --enable res_pjsip \
  --enable res_pjsip_acl \
  --enable res_pjsip_authenticator_digest \
  --enable res_pjsip_caller_id \
  --enable res_pjsip_config_wizard \
  --enable res_pjsip_dialog_info_body_generator \
  --enable res_pjsip_diversion \
  --enable res_pjsip_dlg_options \
  --enable res_pjsip_dtmf_info \
  --enable res_pjsip_empty_info \
  --enable res_pjsip_endpoint_identifier_anonymous \
  --enable res_pjsip_endpoint_identifier_ip \
  --enable res_pjsip_endpoint_identifier_user \
  --enable res_pjsip_exten_state \
  --enable res_pjsip_header_funcs \
  --enable res_pjsip_logger \
  --enable res_pjsip_messaging \
  --enable res_pjsip_mwi \
  --enable res_pjsip_mwi_body_generator \
  --enable res_pjsip_nat \
  --enable res_pjsip_notify \
  --enable res_pjsip_one_touch_record_info \
  --enable res_pjsip_outbound_authenticator_digest \
  --enable res_pjsip_outbound_publish \
  --enable res_pjsip_outbound_registration \
  --enable res_pjsip_path \
  --enable res_pjsip_pidf_body_generator \
  --enable res_pjsip_publish_asterisk \
  --enable res_pjsip_pubsub \
  --enable res_pjsip_refer \
  --enable res_pjsip_registrar \
  --enable res_pjsip_rfc3326 \
  --enable res_pjsip_sdp_rtp \
  --enable res_pjsip_send_to_voicemail \
  --enable res_pjsip_session \
  --enable res_pjsip_sips_contact \
  --enable res_pjsip_t38 \
  --enable res_pjsip_transport_websocket \
  --enable res_pjsip_xpidf_body_generator \
  --enable res_stasis \
  --enable res_stasis_answer \
  --enable res_stasis_device_state \
  --enable res_stasis_mailbox \
  --enable res_stasis_playback \
  --enable res_stasis_recording \
  --enable res_stasis_snoop \
  --enable res_stasis_test \
  --enable res_statsd \
  --enable res_timing_timerfd \
  menuselect.makeopts \
  && make -j$(nproc) 1> /dev/null \
  && make -j$(nproc) install 1> /dev/null \
  && make -j$(nproc) samples 1> /dev/null
WORKDIR /usr/src
RUN git clone https://github.com/alphacep/vosk-asterisk.git
WORKDIR /usr/src/vosk-asterisk
RUN ./bootstrap \
    && ./configure --with-asterisk=/usr/src/asterisk --prefix=/usr \
    && make \
    && make install \
    && sed -i -e 's/noload = chan_sip.so/require = chan_sip.so/' /etc/asterisk/modules.conf \
    && echo 'load = res_speech_vosk.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = res_pjsip.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = chan_pjsip.so' >> /etc/asterisk/modules.conf \
    && echo '#tryinclude sip/*conf' >> /etc/asterisk/sip.conf \
    && echo '#tryinclude dialplan/*conf' >> /etc/asterisk/extensions.conf \
    && echo '#tryinclude ael/*conf' >> /etc/asterisk/extensions.ael \
    # Update max number of open files.
    && sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk \
    # Set tty
    && sed -i 's/TTY=9/TTY=/g' /usr/sbin/safe_asterisk \
    # Create and configure asterisk for running asterisk user.
    && useradd -m asterisk -s /sbin/nologin \
    && chown -R asterisk:asterisk /var/run/asterisk \
                                  /etc/asterisk/ \
                                  /var/lib/asterisk \
                                  /var/log/asterisk \
                                  /var/spool/asterisk
RUN dnf install python3 python3-pip -y \
    && pip3 install torch
# Running asterisk with user asterisk.
EXPOSE 5060
EXPOSE 10000-20000/UDP
USER asterisk
CMD /usr/sbin/asterisk -fvvvvv