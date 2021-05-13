FROM centos:centos7

MAINTAINER JinKak Jung

ENV TA_SRC=src_cython
ENV TA_HOME=/srv
#ENV TA_SRVPROJ=/srv/ta_lite
ENV TA_PKGS=/srv/pkg
ENV MECAB_KO=mecab-0.996-ko-0.9.2
ENV MECAB_KO_DIC=mecab-ko-dic-2.0.1-20150920
ENV LD_LIBRARY_PATH=.:/usr/local/lib:/lib64:/usr/lib/oracle/12.2/client64/lib

RUN yum -y update; yum -y upgrade; yum clean all
RUN yum -y install make
RUN yum -y install autoconf
RUN yum -y install libaio
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install gcc-c++ java-1.7.0-openjdk-devel python-devel
RUN yum -y install freetds-devel
RUN yum -y install python-pandas
RUN yum -y install python-pip
RUN pip install --upgrade pip

RUN localedef -i ko_KR -f UTF-8 ko_KR.UTF-8
ENV LANG ko_KR.UTF-8
ENV LC_ALL ko_KR.UTF-8

# Create application subdirectories
WORKDIR $TA_HOME
RUN mkdir log data mecab-ko mecab-ko-dic pkg ta
RUN mkdir -p /usr/lib/oracle/12.2/client64/lib/network/admin
VOLUME ["$TA_HOME/log", "$TA_HOME/data", "$TA_HOME/ta"]

# Copy application source to SRCDIR
#COPY $TA_SRC $TA_SRVPROJ
COPY $TA_SRC/requirements.pkg $TA_PKGS
COPY $MECAB_KO $TA_HOME/mecab-ko
COPY $MECAB_KO_DIC $TA_HOME/mecab-ko-dic
WORKDIR $TA_HOME/mecab-ko
RUN make install > /dev/null
WORKDIR $TA_HOME/mecab-ko-dic
RUN make install > /dev/null

# Install oracle client
COPY ./oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm $TA_HOME
RUN /usr/bin/rpm -ivh $TA_HOME/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
RUN /bin/rm $TA_HOME/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm

# Install python oracle support package
RUN pip install cx_Oracle --upgrade

# Install Python dependencies
RUN pip install --no-cache-dir Cython
#RUN pip install -r $TA_SRVPROJ/requirements.pkg
RUN pip install -r $TA_PKGS/requirements.pkg

# Port to expose
#EXPOSE 6000

# Copy entrypoint script into the image
WORKDIR $TA_HOME
#COPY ./docker-entrypoint.sh /
#ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
