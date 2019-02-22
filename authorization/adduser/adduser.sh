# username
user='sch'

# user access namespace
namespace='sch'

# path contains ca crt and ca key
capath=/etc/kubernetes/pki

# seld sign crt valid duration
days=365


# generate private key
openssl genrsa -out $user.key 2048

# generate csr 
openssl req -new  -key $user.key  -out $user.csr -subj "/CN=$user"

# generate user crt
openssl x509 -req -in $user.csr -CA $capath/ca.crt -CAkey $capath/ca.key -CAcreateserial -out $user.crt -days $days

if [ $? -ne 0  ]; then
  echo "ERROR: generate user crerdentials error!"
  exit;
fi

# create kubernetes namespace
kubectl create namespace $namespace

# create role
cat <<EOF > role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  namespace: $namespace
  name: admin
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
EOF

# role binding

cat <<EOF > role-binding.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin-binding
  namespace: $namespace
subjects:
- kind: User
  name: $user
  apiGroup: ""
roleRef:
  kind: Role
  name: admin
  apiGroup: ""
EOF

# kubernetes apply config
kubectl apply -f role.yaml
kubectl apply -f role-binding.yaml


# print context config command
echo ""
echo "**************************************************"
echo "Follow these steps to config client"
echo "1. copy $user.crt $user.key $capath/ca.crt to client"
echo "2. add \"10.61.150.188 k8s.ict.ac.cn\" to client hosts"
echo "3. install kubelet on client mashine:"
echo "4. config kubelet context(** must int client ca file directory **):"
echo ""
echo "kubectl config set-credentials $user --client-certificate=$user.crt --client-key=$user.key"
echo "kubectl config set-cluster kubernetes --server https://k8s.ict.ac.cn:6443 --certificate-authority=ca.crt"
echo "kubectl config set-context default --user=$user --cluster=kubernetes --namespace $namespace"
echo "kubectl config use-context default"

