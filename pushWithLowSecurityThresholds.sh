
# trict security settings
STARTDIR=`pwd`
cd  ~/environment/apps/c1-app-sec-moneyx
sed -i 's/": 300/": 0/g' buildspec.yml #change the security thresholds in the c1-app-sec-moneyx app
echo " "  >> README.md  #ensure that we have a change, regardless if the above sed command made anychanges
echo "pushing to master branch (20210303)"
git add . && git commit -m "strict security checks at buildtime"   && git push  --set-upstream origin master

cd $STARTDIR
