STARTDIR=`pwd`
cd ~/environment/apps/c1-app-sec-moneyx
sed -i 's/": 0/": 300/g' buildspec.yml #change the security thresholds in the c1-app-sec-moneyx app
echo " "  >>README.md  #ensure that we have a change, regardless if the above sed command made anychanges
echo "pushing to both master and main as a temporary fix (20210303)"
git add . && git commit -m "allowing risky builds"  && git push  --set-upstream origin master  && git push  --set-upstream origin main

cd $STARTDIR

