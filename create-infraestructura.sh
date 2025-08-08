#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
TAG="PitchZone"
AMI_ID="ami-051f8a213df8bc089"   # Verifica que exista aún en us-east-1
INSTANCE_TYPE="t2.micro"
SEC_GRP_NAME="PitchZone-SG"
KEY_NAME="pitchzone-key-$(date +%s)"

ts(){ date +"%F %T"; }

echo "$(ts) === Creando/redesplegando infraestructura en $REGION ==="

MYIP="$(curl -4 -s ifconfig.me)/32"
echo "$(ts) Tu IPv4: $MYIP"

echo "$(ts) 1) VPC"
VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$REGION" --query "Vpc.VpcId" --output text)
aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value="$TAG" --region "$REGION"

echo "$(ts) 2) Subnet pública"
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR" --region "$REGION" --query "Subnet.SubnetId" --output text)
aws ec2 create-tags --resources "$SUBNET_ID" --tags Key=Name,Value="${TAG}-public" --region "$REGION"
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch --region "$REGION"

echo "$(ts) 3) IGW y rutas"
IGW_ID=$(aws ec2 create-internet-gateway --region "$REGION" --query "InternetGateway.InternetGatewayId" --output text)
aws ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value="${TAG}-igw" --region "$REGION"
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION"

RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --region "$REGION" --query "RouteTable.RouteTableId" --output text)
aws ec2 create-tags --resources "$RT_ID" --tags Key=Name,Value="${TAG}-rt" --region "$REGION"
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --region "$REGION" >/dev/null
aws ec2 associate-route-table --route-table-id "$RT_ID" --subnet-id "$SUBNET_ID" --region "$REGION" >/dev/null

echo "$(ts) 4) Security Group"
SEC_GRP_ID=$(aws ec2 create-security-group --group-name "$SEC_GRP_NAME" --description "Security group for PitchZone web" --vpc-id "$VPC_ID" --region "$REGION" --query "GroupId" --output text)
aws ec2 create-tags --resources "$SEC_GRP_ID" --tags Key=Name,Value="$SEC_GRP_NAME" --region "$REGION"
aws ec2 authorize-security-group-ingress --group-id "$SEC_GRP_ID" --protocol tcp --port 22 --cidr "$MYIP" --region "$REGION" 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SEC_GRP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION" 2>/dev/null || true

echo "$(ts) 5) KeyPair nuevo: $KEY_NAME"
aws ec2 create-key-pair --key-name "$KEY_NAME" --region "$REGION" --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
chmod 400 "${KEY_NAME}.pem"

echo "$(ts) 6) Lanzando EC2 ($INSTANCE_TYPE, $AMI_ID)"
EC2_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" --count 1 --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" --security-group-ids "$SEC_GRP_ID" \
  --subnet-id "$SUBNET_ID" --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=PitchZone-EC2}]" \
  --region "$REGION" --query "Instances[0].InstanceId" --output text)

echo "$(ts) EC2_ID: $EC2_ID"

echo "$(ts) 7) Esperando estado 'running' (máximo 10 min)..."
ATTEMPTS=60
for i in $(seq 1 $ATTEMPTS); do
  STATE=$(aws ec2 describe-instances --instance-ids "$EC2_ID" --region "$REGION" --query "Reservations[0].Instances[0].State.Name" --output text)
  echo "$(ts) intento $i/$ATTEMPTS → $STATE"
  [[ "$STATE" == "running" ]] && break
  sleep 10
done
if [[ "$STATE" != "running" ]]; then
  echo "$(ts) ❌ La instancia no llegó a 'running' a tiempo. Revisa cuotas/AMI/región."
  exit 1
fi

IP=$(aws ec2 describe-instances --instance-ids "$EC2_ID" --region "$REGION" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

cat <<EOT > infraestructura-info.txt
VPC_ID=$VPC_ID
SUBNET_ID=$SUBNET_ID
IGW_ID=$IGW_ID
RT_ID=$RT_ID
SEC_GRP_ID=$SEC_GRP_ID
EC2_ID=$EC2_ID
PUBLIC_IP=$IP
KEY_NAME=$KEY_NAME
KEY_PEM=$(pwd)/${KEY_NAME}.pem
EC2_USER=ec2-user
AMI_ID=$AMI_ID
REGION=$REGION
EOT

echo "$(ts) ✅ Infraestructura creada."
echo "IP pública EC2: $IP"
echo "Datos guardados en infraestructura-info.txt:"
cat infraestructura-info.txt

echo -e "\n👉 Prueba SSH:"
echo "ssh -i $(pwd)/${KEY_NAME}.pem ec2-user@$IP"
