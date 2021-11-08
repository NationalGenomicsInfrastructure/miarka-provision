FROM centos:8

RUN \
  curl -L https://cpanmin.us -o /usr/bin/cpanm && \
  chmod +x /usr/bin/cpanm && \
  yum -y install python38-devel python38-pip git tar gzip bzip2

RUN \
  python3 -m pip install ansible && \
  python3 -m pip install pexpect

ENV PROVISIONURL=https://github.com/NationalGenomicsInfrastructure/miarka-provision.git

CMD git clone -b devel "$PROVISIONURL" && \
    sed -re "s!__DEPLOYROOT__!$PWD!" miarka-provision/bootstrap/bashrc > bashrc
