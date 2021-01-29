git clone https://github.com/mawinkler/vulnerability-management.git
PREVIOUS_DIR=`pwd`
cd vulnerability-management/cloudone-image-security/scan-report
#cp config.yml.sample config.yml
pip3 install  fpdf requests simplejson urllib3
cat <<EOF>config.yml
dssc:
  service: "${DSSC_HOST}:443"
  username: "${DSSC_USERNAME}"
  password: "${DSSC_PASSWORD}"

repository:
  name: "517003314933.dkr.ecr.eu-central-1.amazonaws.com/cloudone101c1appsecmoneyx:b46769f6"
  image_tag: "latest"

criticalities:
  - defcon1
  - critical
  - high
  - medium
EOF
cat config.yml

python3 scan-report.py


cd $PREVIOUS_DIR
