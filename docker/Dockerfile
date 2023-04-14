FROM rockylinux:8.5

RUN \
  curl -L https://cpanmin.us -o /usr/bin/cpanm && \
  chmod +x /usr/bin/cpanm && \
  yum install -y epel-release && \
  yum update -y && \
  yum -y install python38-devel python38-pip git tar gzip bzip2 rsync apptainer which gcc gcc-c++ kernel-devel

# needed to run nested Singularity (apptainer), which the
# `arteria-sequencing-report-ws` role does
RUN sed -i 's/allow setuid = yes/allow setuid = no/g' /etc/apptainer/apptainer.conf

RUN \
  python3 -m pip install ansible pexpect

ENV PROVISIONURL=https://github.com/NationalGenomicsInfrastructure/miarka-provision.git

CMD git clone -b devel "$PROVISIONURL" && miarka-provision/bootstrap/setup_repo.sh "$(pwd)/miarka-provision"
