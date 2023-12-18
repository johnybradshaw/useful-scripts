# Installing R studio

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or use sudo"
  exit
fi
# Guide - https://posit.co/download/rstudio-server/
# Guide - https://cran.rstudio.com/bin/linux/ubuntu/
# update indices
apt update -qq
# install two helper packages we need
apt install --no-install-recommends software-properties-common dirmngr -y
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt install --no-install-recommends r-base -y # install R
add-apt-repository ppa:c2d4u.team/c2d4u4.0+ -y # add ppa
apt install --no-install-recommends r-cran-rstan -y # install rstan
apt install --no-install-recommends r-cran-tidyverse -y # install the tidyverse packages
ufw allow 8787/tcp # open firewall port for RStudio Server