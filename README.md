ssh-keygen -t rsa -N "" -f mooc
docker build --build-arg username=mooc --build-arg password=mooc123 --build-arg git_name="Pramod Kumbhar"  --build-arg git_email="pramod.s.kumbhar@gmail.com"  --build-arg ldap_username=kumbhar  -t mooc .
