
#deleting ECR repos
echo $LENGTH
for((i=0;i<${LENGTH};++i)) do
    IMAGES_FLATENED[${i}]=`echo ${IMAGES[$i]} | sed 's/\///'| sed 's/-//'`
    printf '%s\n' "image ${i} = ${IMAGES[$i]} image_clean = ${IMAGES_FLATENED[$i]} "
    echo "DELETING ECR repository-----------------------------------"
    aws ecr delete-repository --repository-name ${IMAGES_FLATENED[${i}]} --query repository.repositoryArn --force
done