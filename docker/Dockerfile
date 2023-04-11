FROM rockylinux:8.5

RUN \
  curl -L https://cpanmin.us -o /usr/bin/cpanm && \
  chmod +x /usr/bin/cpanm && \
  yum install -y epel-release && \
  yum update -y && \
  yum -y install python38-devel python38-pip git tar gzip bzip2 rsync singularity-runtime && \
  yum -y groupinstall "Development Tools"

RUN \
  python3 -m pip install ansible pexpect

ENV PROVISIONURL=https://github.com/NationalGenomicsInfrastructure/miarka-provision.git

CMD git clone -b devel "$PROVISIONURL" && miarka-provision/bootstrap/setup_repo.sh "$(pwd)/miarka-provision"
